import 'package:flutter/foundation.dart';
import '../../../core/utils/supabase_config.dart';
import '../../../data/models/usuario_perfil.dart';
import '../../../data/repositories/auth_repository.dart';

enum EstadoAuth { inicial, cargando, autenticado, noAutenticado, error }

/// Proveedor de estado de autenticación y perfil del usuario
class SesionUsuarioProvider extends ChangeNotifier {
  final AuthRepository _repositorio;

  EstadoAuth _estado = EstadoAuth.inicial;
  UsuarioPerfil? _perfil;
  String? _mensajeError;

  EstadoAuth get estado => _estado;
  UsuarioPerfil? get perfil => _perfil;
  String? get mensajeError => _mensajeError;
  bool get estaAutenticado => _estado == EstadoAuth.autenticado && _perfil != null;

  SesionUsuarioProvider({AuthRepository? repositorio})
      : _repositorio = repositorio ?? AuthRepository() {
    _verificarSesionActual();
  }

  /// Verifica si ya existe una sesión activa al iniciar la app
  Future<void> _verificarSesionActual() async {
    if (!SupabaseConfig.estaInicializado) {
      _estado = EstadoAuth.noAutenticado;
      notifyListeners();
      return;
    }

    try {
      final user = _repositorio.usuarioActual;
      if (user != null) {
        _perfil = await _repositorio.obtenerPerfil(user.id);
        _estado = EstadoAuth.autenticado;
      } else {
        _estado = EstadoAuth.noAutenticado;
      }
    } catch (e) {
      _estado = EstadoAuth.noAutenticado;
    }
    notifyListeners();
  }

  /// Inicia sesión con correo y contraseña
  Future<bool> iniciarSesion(String correo, String contrasena) async {
    _estado = EstadoAuth.cargando;
    _mensajeError = null;
    notifyListeners();

    try {
      _perfil = await _repositorio.iniciarSesion(
        correo: correo,
        contrasena: contrasena,
      );
      _estado = EstadoAuth.autenticado;
      notifyListeners();
      return true;
    } on AutenticacionExcepcion catch (e) {
      _mensajeError = e.mensaje;
      _estado = EstadoAuth.error;
      notifyListeners();
      return false;
    } catch (e) {
      _mensajeError = 'Error inesperado: $e';
      _estado = EstadoAuth.error;
      notifyListeners();
      return false;
    }
  }

  /// Registra una nueva cuenta de usuario. Toda cuenta nueva entra como operario.
  Future<bool> registrarUsuario({
    required String correo,
    required String contrasena,
    required String nombreCompleto,
  }) async {
    _estado = EstadoAuth.cargando;
    _mensajeError = null;
    notifyListeners();

    try {
      _perfil = await _repositorio.registrarUsuario(
        correo: correo,
        contrasena: contrasena,
        nombreCompleto: nombreCompleto,
      );
      _estado = EstadoAuth.autenticado;
      notifyListeners();
      return true;
    } on AutenticacionExcepcion catch (e) {
      _mensajeError = e.mensaje;
      _estado = EstadoAuth.error;
      notifyListeners();
      return false;
    } catch (e) {
      _mensajeError = 'Error inesperado al registrarse: $e';
      _estado = EstadoAuth.error;
      notifyListeners();
      return false;
    }
  }

  /// Actualiza el nombre completo del perfil
  Future<bool> actualizarNombre(String nuevoNombre) async {
    if (_perfil == null) return false;

    try {
      _perfil = await _repositorio.actualizarPerfil(
        userId: _perfil!.id,
        nombreCompleto: nuevoNombre,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _mensajeError = 'Error al actualizar el nombre: $e';
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión activa
  Future<void> cerrarSesion() async {
    await _repositorio.cerrarSesion();
    _perfil = null;
    _estado = EstadoAuth.noAutenticado;
    _mensajeError = null;
    notifyListeners();
  }

  /// Permite establecer un perfil local para pruebas de desarrollo o cambio rápido de rol
  void establecerPerfilPrueba(UsuarioPerfil perfil) {
    _perfil = perfil;
    _estado = EstadoAuth.autenticado;
    _mensajeError = null;
    notifyListeners();
  }
}
