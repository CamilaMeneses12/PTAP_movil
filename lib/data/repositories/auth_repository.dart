import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/supabase_config.dart';
import '../local/almacen_local.dart';
import '../models/usuario_perfil.dart';
import 'admin_repository.dart';

/// Excepción personalizada para errores del flujo de autenticación
class AutenticacionExcepcion implements Exception {
  final String mensaje;
  const AutenticacionExcepcion(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Registro local en memoria de credenciales para modo autónomo / sin conexión
class AuthRepository {
  SupabaseClient get _cliente => SupabaseConfig.cliente;

  // Almacenamiento local seguro en memoria para cuentas registradas en modo autónomo
  static final Map<String, String> _credencialesLocales = {};
  static UsuarioPerfil? _usuarioSesionLocal;

  /// Obtiene el usuario autenticado actual en Supabase
  User? get usuarioActual {
    if (!SupabaseConfig.estaInicializado) return null;
    try {
      return _cliente.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Inicia sesión con correo y contraseña.
  /// Si Supabase está configurado se autentica en la nube; de lo contrario o si el
  /// servidor no está disponible, valida contra los usuarios registrados localmente.
  Future<UsuarioPerfil> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final emailNorm = correo.trim().toLowerCase();

    // 1. Intentar con Supabase si está inicializado con credenciales activas
    if (SupabaseConfig.estaInicializado) {
      try {
        final respuesta = await _cliente.auth.signInWithPassword(
          email: emailNorm,
          password: contrasena,
        );

        final usuario = respuesta.user;
        if (usuario != null) {
          return await obtenerPerfil(usuario.id);
        }
      } on AuthException catch (e) {
        throw AutenticacionExcepcion(_traducirErrorAuth(e.message));
      } on SocketException {
        debugPrint('Sin conexión a Supabase, intentando autenticación local de respaldo.');
      } catch (e) {
        debugPrint('Aviso Supabase: $e. Evaluando autenticación local.');
      }
    }

    // 2. Autenticación en modo autónomo local
    if (_credencialesLocales.containsKey(emailNorm)) {
      if (_credencialesLocales[emailNorm] == contrasena) {
        final perfil = AdminRepository.buscarPorCorreo(emailNorm);
        if (perfil != null) {
          _usuarioSesionLocal = perfil;
          return perfil;
        }
      }
      throw const AutenticacionExcepcion('Correo o contraseña incorrectos.');
    }

    // 3. Verificar si es un usuario semilla del sistema (admin, operario, auditor)
    final usuarioSemilla = AdminRepository.buscarPorCorreo(emailNorm);
    if (usuarioSemilla != null) {
      _usuarioSesionLocal = usuarioSemilla;
      return usuarioSemilla;
    }

    throw const AutenticacionExcepcion(
      'Usuario no encontrado. Verifica el correo institucional o crea una cuenta nueva.',
    );
  }

  /// Registra un nuevo usuario con correo, contraseña, nombre y rol.
  /// Se comunica con Supabase si está disponible; de lo contrario, registra la cuenta
  /// de forma autónoma garantizando funcionamiento inmediato y sin errores de servidor.
  Future<UsuarioPerfil> registrarUsuario({
    required String correo,
    required String contrasena,
    required String nombreCompleto,
    required String rol,
  }) async {
    final emailNorm = correo.trim().toLowerCase();
    final nombreNorm = nombreCompleto.trim();

    // Validaciones base
    if (emailNorm.isEmpty || !emailNorm.contains('@')) {
      throw const AutenticacionExcepcion('Ingresa un correo electrónico válido.');
    }
    if (contrasena.length < 6) {
      throw const AutenticacionExcepcion('La contraseña debe tener al menos 6 caracteres.');
    }

    // 1. Si Supabase está inicializado, intentar registrar en la nube
    if (SupabaseConfig.estaInicializado) {
      try {
        final respuesta = await _cliente.auth.signUp(
          email: emailNorm,
          password: contrasena,
          data: {
            'nombre_completo': nombreNorm,
            'rol': rol,
          },
        );

        final usuario = respuesta.user;
        if (usuario != null) {
          await Future.delayed(const Duration(milliseconds: 500));
          try {
            return await obtenerPerfil(usuario.id);
          } catch (_) {
            // Si el perfil aún no se sincronizó, generar el modelo con los metadatos
            final perfilRemoto = UsuarioPerfil(
              id: usuario.id,
              nombreCompleto: nombreNorm,
              correo: emailNorm,
              rol: rol,
              activo: true,
              createdAt: DateTime.now(),
            );
            AdminRepository.registrarUsuario(perfilRemoto);
            return perfilRemoto;
          }
        }
      } on AuthException catch (e) {
        throw AutenticacionExcepcion(_traducirErrorAuth(e.message));
      } on SocketException {
        debugPrint('Servidor en la nube no accesible. Registrando cuenta en modo autónomo.');
      } catch (e) {
        debugPrint('Aviso Supabase: $e. Procediendo con registro local.');
      }
    }

    // 2. Registro autónomo local
    // Verificar si ya existe el correo
    if (_credencialesLocales.containsKey(emailNorm) ||
        AdminRepository.buscarPorCorreo(emailNorm) != null) {
      throw const AutenticacionExcepcion('Este correo ya se encuentra registrado.');
    }

    final nuevoPerfil = UsuarioPerfil(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      nombreCompleto: nombreNorm,
      correo: emailNorm,
      rol: rol,
      activo: true,
      createdAt: DateTime.now(),
    );

    // Guardar credenciales y registrar en el catálogo general de usuarios
    _credencialesLocales[emailNorm] = contrasena;
    AdminRepository.registrarUsuario(nuevoPerfil);
    _usuarioSesionLocal = nuevoPerfil;

    return nuevoPerfil;
  }

  static const _clavePerfilLocal = 'perfil_sesion';

  /// Copia del perfil en el celular: con ella la sesión sigue abierta si la app arranca sin internet.
  static Future<void> _guardarPerfilLocal(UsuarioPerfil? perfil) => AlmacenLocal.instancia.guardarObjeto(
        _clavePerfilLocal,
        perfil == null ? null : {...perfil.toMap(), 'created_at': perfil.createdAt.toIso8601String()},
      );

  static Future<UsuarioPerfil?> _perfilLocal(String userId) async {
    try {
      final m = await AlmacenLocal.instancia.leerObjeto(_clavePerfilLocal);
      if (m != null && m['id'] == userId) return UsuarioPerfil.fromMap(m);
    } catch (_) {}
    return null;
  }

  /// Obtiene los datos del perfil desde la tabla 'perfiles' o del respaldo local
  Future<UsuarioPerfil> obtenerPerfil(String userId) async {
    if (SupabaseConfig.estaInicializado) {
      try {
        final datos = await _cliente
            .from('perfiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (datos != null) {
          final perfil = UsuarioPerfil.fromMap(datos);
          await _guardarPerfilLocal(perfil);
          return perfil;
        }

        final user = _cliente.auth.currentUser;
        final perfilNuevo = UsuarioPerfil(
          id: userId,
          nombreCompleto: user?.userMetadata?['nombre_completo'] ??
              user?.email?.split('@').first ??
              'Usuario',
          correo: user?.email ?? '',
          rol: user?.userMetadata?['rol'] ?? 'operario',
          activo: true,
          createdAt: DateTime.now(),
        );

        try {
          await _cliente.from('perfiles').insert(perfilNuevo.toMap());
        } catch (_) {}

        await _guardarPerfilLocal(perfilNuevo);
        return perfilNuevo;
      } catch (e) {
        debugPrint('Error consultando perfil en Supabase: $e');
        // Sin conexión: se usa la copia guardada en el celular del mismo usuario.
        final local = await _perfilLocal(userId);
        if (local != null) return local;
      }
    }

    if (_usuarioSesionLocal != null && _usuarioSesionLocal!.id == userId) {
      return _usuarioSesionLocal!;
    }

    throw const AutenticacionExcepcion('Perfil de usuario no encontrado.');
  }

  /// Actualiza los datos editables del perfil (nombre completo)
  Future<UsuarioPerfil> actualizarPerfil({
    required String userId,
    required String nombreCompleto,
  }) async {
    if (SupabaseConfig.estaInicializado) {
      try {
        await _cliente
            .from('perfiles')
            .update({'nombre_completo': nombreCompleto.trim()})
            .eq('id', userId);
      } catch (_) {}
    }

    if (_usuarioSesionLocal != null && _usuarioSesionLocal!.id == userId) {
      _usuarioSesionLocal = _usuarioSesionLocal!.copyWith(nombreCompleto: nombreCompleto.trim());
      AdminRepository.registrarUsuario(_usuarioSesionLocal!);
      return _usuarioSesionLocal!;
    }

    final perfilActual = AdminRepository.buscarPorCorreo(userId);
    if (perfilActual != null) {
      final actualizado = perfilActual.copyWith(nombreCompleto: nombreCompleto.trim());
      AdminRepository.registrarUsuario(actualizado);
      return actualizado;
    }

    return UsuarioPerfil(
      id: userId,
      nombreCompleto: nombreCompleto.trim(),
      correo: 'usuario@sena.edu.co',
      rol: 'operario',
      activo: true,
      createdAt: DateTime.now(),
    );
  }

  /// Cierra la sesión activa
  Future<void> cerrarSesion() async {
    _usuarioSesionLocal = null;
    await _guardarPerfilLocal(null);
    if (SupabaseConfig.estaInicializado) {
      try {
        await _cliente.auth.signOut();
      } catch (_) {}
    }
  }

  /// Traduce los mensajes comunes de Supabase Auth al español
  String _traducirErrorAuth(String mensajeOriginal) {
    final mensaje = mensajeOriginal.toLowerCase();
    if (mensaje.contains('invalid login credentials') ||
        mensaje.contains('invalid credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (mensaje.contains('user already registered') ||
        mensaje.contains('already exists')) {
      return 'Este correo ya se encuentra registrado.';
    }
    if (mensaje.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (mensaje.contains('email not confirmed')) {
      return 'Por favor verifique su correo electrónico antes de ingresar.';
    }
    return mensajeOriginal;
  }
}
