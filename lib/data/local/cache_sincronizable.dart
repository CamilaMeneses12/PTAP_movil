import 'almacen_local.dart';

/// Copia local de los registros de un formato, con la marca de cuáles faltan por subir.
///
/// - Lo sincronizado es la última copia conocida de Supabase: se ve aunque no haya internet.
/// - Lo pendiente se guardó en el celular y espera conexión; nunca se borra hasta subirlo.
///
/// Hay una sola caché por colección, compartida por todos los repositorios de la app.
class CacheSincronizable<T> {
  final String coleccion;
  final Map<String, dynamic> Function(T item) aMapa;
  final T Function(Map<String, dynamic> mapa) deMapa;
  final String Function(T item) idDe;

  CacheSincronizable._(this.coleccion, this.aMapa, this.deMapa, this.idDe);

  static final Map<String, CacheSincronizable<dynamic>> _instancias = {};

  static CacheSincronizable<T> de<T>(
    String coleccion, {
    required Map<String, dynamic> Function(T item) aMapa,
    required T Function(Map<String, dynamic> mapa) deMapa,
    required String Function(T item) idDe,
  }) =>
      (_instancias[coleccion] ??= CacheSincronizable<T>._(coleccion, aMapa, deMapa, idDe))
          as CacheSincronizable<T>;

  /// Solo para pruebas: olvida lo cargado para leer de nuevo el almacén.
  static void reiniciar() => _instancias.clear();

  final List<_Entrada<T>> _entradas = [];
  Future<void>? _carga;

  Future<void> _asegurarCarga() => _carga ??= () async {
        final datos = await AlmacenLocal.instancia.leerLista(coleccion);
        for (final m in datos) {
          try {
            _entradas.add(_Entrada(deMapa(Map<String, dynamic>.from(m['datos'] as Map)), m['pendiente'] == true));
          } catch (_) {
            // Un registro dañado no impide leer los demás.
          }
        }
      }();

  Future<void> _persistir() => AlmacenLocal.instancia.guardarLista(coleccion, [
        for (final e in _entradas) {'pendiente': e.pendiente, 'datos': aMapa(e.item)},
      ]);

  Future<List<T>> todos() async {
    await _asegurarCarga();
    return [for (final e in _entradas) e.item];
  }

  Future<List<T>> pendientes() async {
    await _asegurarCarga();
    return [for (final e in _entradas) if (e.pendiente) e.item];
  }

  Future<int> contarPendientes() async => (await pendientes()).length;

  /// Guarda un registro nuevo como pendiente de subir.
  Future<void> agregarPendiente(T item) async {
    await _asegurarCarga();
    _entradas.removeWhere((e) => idDe(e.item) == idDe(item));
    _entradas.insert(0, _Entrada(item, true));
    await _persistir();
  }

  /// El registro ya está en Supabase (con [actualizado] si cambió al subirlo, por ejemplo la foto).
  Future<void> marcarSincronizado(String id, {T? actualizado}) async {
    await _asegurarCarga();
    final i = _entradas.indexWhere((e) => idDe(e.item) == id);
    if (i == -1) return;
    _entradas[i] = _Entrada(actualizado ?? _entradas[i].item, false);
    await _persistir();
  }

  /// Reemplaza la copia sincronizada por lo que devolvió Supabase, sin tocar lo pendiente.
  Future<void> reemplazarSincronizados(List<T> remotos) async {
    await _asegurarCarga();
    final pendientes = _entradas.where((e) => e.pendiente).toList();
    final idsPendientes = {for (final e in pendientes) idDe(e.item)};
    _entradas
      ..clear()
      ..addAll(pendientes)
      ..addAll([for (final r in remotos) if (!idsPendientes.contains(idDe(r))) _Entrada(r, false)]);
    await _persistir();
  }

  Future<void> eliminar(String id) async {
    await _asegurarCarga();
    _entradas.removeWhere((e) => idDe(e.item) == id);
    await _persistir();
  }
}

class _Entrada<T> {
  final T item;
  final bool pendiente;
  const _Entrada(this.item, this.pendiente);
}
