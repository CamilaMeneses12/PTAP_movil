import 'package:flutter/foundation.dart';
import '../../../data/models/medidores_modelos.dart';
import '../../../data/models/parametro_catalogo_modelo.dart';
import '../../../data/models/usuario_perfil.dart';
import '../../../data/repositories/admin_repository.dart';

/// Proveedor de estado para la administración de usuarios y catálogos de la PTAP
class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;

  AdminProvider({AdminRepository? repository})
      : _repository = repository ?? AdminRepository() {
    cargarTodo();
  }

  List<UsuarioPerfil> _usuarios = [];
  List<Medidor> _medidores = [];
  List<ParametroCatalogo> _parametros = [];

  bool _cargando = false;
  String? _error;
  String? _mensajeExito;

  List<UsuarioPerfil> get usuarios => _usuarios;
  List<Medidor> get medidores => _medidores;
  List<ParametroCatalogo> get parametros => _parametros;
  bool get cargando => _cargando;
  String? get error => _error;
  String? get mensajeExito => _mensajeExito;

  Future<void> cargarTodo() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _usuarios = await _repository.obtenerUsuarios();
      _medidores = await _repository.obtenerCatalogoMedidores();
      _parametros = await _repository.obtenerCatalogoParametros();
    } catch (e) {
      _error = 'Error al cargar datos administrativos: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cambiarRolUsuario(String usuarioId, String nuevoRol) async {
    try {
      await _repository.actualizarRolUsuario(usuarioId, nuevoRol);
      final idx = _usuarios.indexWhere((u) => u.id == usuarioId);
      if (idx != -1) {
        _usuarios[idx] = _usuarios[idx].copyWith(rol: nuevoRol);
      }
      _mensajeExito = 'Rol actualizado correctamente';
      notifyListeners();
    } catch (e) {
      _error = 'Error al cambiar rol: $e';
      notifyListeners();
    }
  }

  Future<void> toggleEstadoUsuario(String usuarioId) async {
    try {
      final idx = _usuarios.indexWhere((u) => u.id == usuarioId);
      if (idx != -1) {
        final nuevoEstado = !_usuarios[idx].activo;
        await _repository.actualizarEstadoUsuario(usuarioId, nuevoEstado);
        _usuarios[idx] = _usuarios[idx].copyWith(activo: nuevoEstado);
        _mensajeExito = nuevoEstado ? 'Usuario activado' : 'Usuario desactivado';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al cambiar estado del usuario: $e';
      notifyListeners();
    }
  }

  Future<void> toggleEstadoMedidor(int medidorId) async {
    try {
      final idx = _medidores.indexWhere((m) => m.id == medidorId);
      if (idx != -1) {
        final nuevoEstado = !_medidores[idx].activo;
        await _repository.actualizarEstadoMedidor(medidorId, nuevoEstado);
        _medidores[idx] = _medidores[idx].copyWith(activo: nuevoEstado);
        _mensajeExito = nuevoEstado ? 'Medidor activado en catálogo' : 'Medidor desactivado';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al cambiar estado del medidor: $e';
      notifyListeners();
    }
  }

  Future<void> actualizarRangoParametro(String parametroId, double min, double max) async {
    try {
      await _repository.actualizarRangoParametro(parametroId, min, max);
      final idx = _parametros.indexWhere((p) => p.id == parametroId);
      if (idx != -1) {
        _parametros[idx] = _parametros[idx].copyWith(
          valorMin: min,
          valorMax: max,
        );
      }
      _mensajeExito = 'Rangos normativos actualizados';
      notifyListeners();
    } catch (e) {
      _error = 'Error al actualizar rangos: $e';
      notifyListeners();
    }
  }

  void limpiarMensajes() {
    _error = null;
    _mensajeExito = null;
    notifyListeners();
  }
}
