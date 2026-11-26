import 'package:flutter/foundation.dart';
import '../../core/utils/mapa_supabase.dart';
import '../../core/utils/identificador.dart';
import '../../core/utils/supabase_config.dart';
import '../local/cache_sincronizable.dart';
import '../local/serializacion_local.dart';
import '../models/registro_fisicoquimico.dart';

/// Repositorio para la gestión del formato DO-F-070 en Supabase
class FisicoquimicoRepository {
  // Registro de ejemplo del formato Excel: solo se muestra cuando Supabase no está configurado.
  final List<RegistroFisicoquimico> _registrosMemoria = [];

  FisicoquimicoRepository() {
    _cargarDatosSemillaMemoria();
  }

  void _cargarDatosSemillaMemoria() {
    // Registro de ejemplo basado fielmente en la fila 11 del formato Excel DO-F-070
    final registroEjemplo = RegistroFisicoquimico(
      id: 'semilla-01',
      fecha: DateTime(2025, 2, 21),
      hora: '01:20',
      regional: 'Distrito Capital',
      centroFormacion: 'Centro de Tecnologías Agroindustriales',
      sede: 'Sede Principal',
      crudaCaudalEntrada: 0.7,
      crudaPh: 8.0,
      crudaTurbidez: 4.68,
      crudaColor: 15.0,
      crudaDosisCoagulante: '0.2',
      filtradaTurbidez: 0.92,
      filtradaPh: 7.6,
      cloradaTurbidez: 1.61,
      cloradaPh: 7.9,
      cloradaColorAparente: 15.0,
      cloradaCloroResidual: 2.5, // Fuera de rango (> 2.0 mg/L)
      fueraDeRango: true,
      observaciones: 'Cloro residual ligeramente alto en salida de cloración.',
      responsableNombre: 'Diego Calderón',
      createdBy: 'operario-1',
      createdAt: DateTime(2025, 2, 21, 1, 20),
      puntosControl: const [
        MedicionPuntoControl(
          areaNombre: 'Biocabaña',
          turbidez: 0.0,
          ph: 7.7,
          colorAparente: 10.0,
          cloroResidual: 1.98,
        ),
        MedicionPuntoControl(
          areaNombre: 'Agroindustria',
          turbidez: 0.92,
          ph: 8.0,
          colorAparente: 10.0,
          cloroResidual: 1.95,
        ),
        MedicionPuntoControl(
          areaNombre: 'Gastronomia',
          turbidez: 0.24,
          ph: 7.9,
          colorAparente: 10.0,
          cloroResidual: 1.5,
        ),
        MedicionPuntoControl(
          areaNombre: 'ENCC',
          turbidez: 0.0,
          ph: 8.0,
          colorAparente: 0.0,
          cloroResidual: 1.29,
        ),
      ],
    );
    _registrosMemoria.add(registroEjemplo);
  }

  /// Puntos de muestreo por defecto según el formato Excel
  List<String> obtenerPuntosMuestreoDefecto() {
    return const [
      'Biocabaña',
      'Agroindustria',
      'Gastronomia',
      'ENCC',
      'Dispensador Bienestar',
    ];
  }

  CacheSincronizable<RegistroFisicoquimico> get _cache => CacheSincronizable.de<RegistroFisicoquimico>(
        'fisicoquimicos',
        aMapa: SerializacionLocal.fisicoquimicoAMapa,
        deMapa: SerializacionLocal.fisicoquimicoDeMapa,
        idDe: (r) => r.id,
      );

  /// true si el último registro guardado quedó en el celular esperando conexión.
  bool ultimoGuardadoPendiente = false;

  static List<RegistroFisicoquimico> _ordenados(Iterable<RegistroFisicoquimico> lista) => lista.toList()
    ..sort((a, b) {
      final f = b.fecha.compareTo(a.fecha);
      return f != 0 ? f : b.hora.compareTo(a.hora);
    });

  /// Obtiene todos los registros ordenados por fecha descendente.
  /// Sin conexión devuelve la última copia guardada en el celular más lo pendiente de subir.
  Future<List<RegistroFisicoquimico>> obtenerRegistros() async {
    if (!SupabaseConfig.estaInicializado) {
      return _ordenados([...await _cache.todos(), ..._registrosMemoria]);
    }

    try {
      final res = await SupabaseConfig.cliente
          .from('registros_fisicoquimicos')
          .select('*, puntos_control_mediciones(*)')
          .order('fecha', ascending: false)
          .order('hora', ascending: false);

      final lista = (res as List).map((mapa) {
        final puntosJson = mapa['puntos_control_mediciones'] as List? ?? [];
        final puntos = puntosJson
            .map((p) => MedicionPuntoControl.fromMap(p as Map<String, dynamic>))
            .toList();
        return RegistroFisicoquimico.fromMap(mapa, puntos: puntos);
      }).toList();

      await _cache.reemplazarSincronizados(lista);
    } catch (e) {
      debugPrint('Sin conexión con Supabase, se muestran los registros guardados en el celular: $e');
    }
    return _ordenados(await _cache.todos());
  }

  /// Guarda primero en el celular y luego intenta subirlo. Sin conexión queda pendiente
  /// y se sube después (ver [subirPendientes]). Nunca se pierde el registro.
  Future<bool> guardarRegistro(RegistroFisicoquimico registro) async {
    // Cada punto de control lleva su propio id para que un reintento no lo duplique.
    final mapa = SerializacionLocal.fisicoquimicoAMapa(registro);
    for (final p in (mapa['puntos'] as List).cast<Map<String, dynamic>>()) {
      p['id'] ??= generarUuid();
    }
    final reg = SerializacionLocal.fisicoquimicoDeMapa(mapa);

    await _cache.agregarPendiente(reg);
    ultimoGuardadoPendiente = true;
    if (!SupabaseConfig.estaInicializado) return true;

    try {
      await _subir(reg);
      await _cache.marcarSincronizado(reg.id);
      ultimoGuardadoPendiente = false;
    } catch (e) {
      debugPrint('Registro guardado en el celular; se subirá cuando haya conexión: $e');
    }
    return true;
  }

  Future<void> _subir(RegistroFisicoquimico reg) async {
    final cliente = SupabaseConfig.cliente;
    final mapa = paraInsertarEnSupabase(reg.toMap());
    String idRemoto;
    if (mapa.containsKey('id')) {
      // Con id propio: si ya estaba arriba (se cortó la respuesta), no se duplica.
      await cliente.from('registros_fisicoquimicos').upsert(mapa, onConflict: 'id', ignoreDuplicates: true);
      idRemoto = reg.id;
    } else {
      final res = await cliente.from('registros_fisicoquimicos').insert(mapa).select().single();
      idRemoto = res['id']?.toString() ?? reg.id;
    }
    if (reg.puntosControl.isNotEmpty) {
      await cliente.from('puntos_control_mediciones').upsert(
            [for (final p in reg.puntosControl) paraInsertarEnSupabase(p.toMap(fkRegistroId: idRemoto))],
            onConflict: 'id',
            ignoreDuplicates: true,
          );
    }
  }

  Future<int> contarPendientes() async =>
      SupabaseConfig.estaInicializado ? await _cache.contarPendientes() : 0;

  /// Sube lo que quedó guardado sin conexión. Devuelve el error del primer registro que falle.
  Future<String?> subirPendientes() async {
    if (!SupabaseConfig.estaInicializado) return null;
    String? error;
    for (final reg in await _cache.pendientes()) {
      try {
        await _subir(reg);
        await _cache.marcarSincronizado(reg.id);
      } catch (e) {
        error ??= '$e';
      }
    }
    return error;
  }

  /// Elimina un registro por ID
  Future<bool> eliminarRegistro(String id) async {
    _registrosMemoria.removeWhere((r) => r.id == id);
    await _cache.eliminar(id);

    if (!SupabaseConfig.estaInicializado) return true;

    try {
      await SupabaseConfig.cliente
          .from('registros_fisicoquimicos')
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error al eliminar registro: $e');
      return false;
    }
  }
}
