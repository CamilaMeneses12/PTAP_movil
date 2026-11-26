import 'package:flutter/foundation.dart';
import '../../../data/models/registro_fisicoquimico.dart';
import '../../../data/repositories/fisicoquimico_repository.dart';

/// Proveedor de estado para el módulo de Parámetros Fisicoquímicos (DO-F-070)
class FisicoquimicoProvider extends ChangeNotifier {
  final FisicoquimicoRepository _repositorio;

  List<RegistroFisicoquimico> _registros = [];
  bool _cargando = false;
  String? _mensajeError;

  List<RegistroFisicoquimico> get registros => _registros;
  bool get cargando => _cargando;

  int _pendientes = 0;

  /// Registros guardados en el celular que aún no se suben a Supabase.
  int get pendientes => _pendientes;

  /// true si lo último que se guardó quedó en el celular esperando conexión.
  bool get ultimoGuardadoPendiente => _repositorio.ultimoGuardadoPendiente;

  /// Sube lo pendiente y recarga. Devuelve el error si algo no se pudo subir.
  Future<String?> sincronizar() async {
    final error = await _repositorio.subirPendientes();
    await cargarRegistros();
    return error;
  }
  String? get mensajeError => _mensajeError;

  FisicoquimicoProvider({FisicoquimicoRepository? repositorio})
      : _repositorio = repositorio ?? FisicoquimicoRepository() {
    cargarRegistros();
  }

  List<String> get puntosMuestreo => _repositorio.obtenerPuntosMuestreoDefecto();

  /// Carga todos los registros almacenados
  Future<void> cargarRegistros() async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      _registros = await _repositorio.obtenerRegistros();
      _pendientes = await _repositorio.contarPendientes();
    } catch (e) {
      _mensajeError = 'Error al cargar registros: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Guarda un nuevo registro y recarga la lista
  Future<bool> guardarRegistro(RegistroFisicoquimico registro) async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final exito = await _repositorio.guardarRegistro(registro);
      if (exito) {
        await cargarRegistros();
        return true;
      } else {
        _mensajeError = 'No se pudo guardar el registro.';
        return false;
      }
    } catch (e) {
      _mensajeError = 'Error al guardar: $e';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Elimina un registro existente
  Future<bool> eliminarRegistro(String id) async {
    try {
      final exito = await _repositorio.eliminarRegistro(id);
      if (exito) {
        _registros.removeWhere((r) => r.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _mensajeError = 'Error al eliminar: $e';
      notifyListeners();
      return false;
    }
  }
}
