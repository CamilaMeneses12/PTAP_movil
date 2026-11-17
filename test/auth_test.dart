import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/data/models/usuario_perfil.dart';
import 'package:planta_agua/presentation/auth/providers/auth_provider.dart';

void main() {
  group('Modelo UsuarioPerfil y Permisos de Rol', () {
    test('Permisos para rol Operario', () {
      final operario = UsuarioPerfil(
        id: 'user-op-1',
        nombreCompleto: 'Carlos Gómez',
        correo: 'carlos@sena.edu.co',
        rol: 'operario',
        activo: true,
        createdAt: DateTime.now(),
      );

      expect(operario.esOperario, isTrue);
      expect(operario.esAdministrador, isFalse);
      expect(operario.esConsultorSiga, isFalse);
      expect(operario.puedeEditar, isTrue);
      expect(operario.puedeAdministrar, isFalse);
    });

    test('Permisos para rol Administrador', () {
      final admin = UsuarioPerfil(
        id: 'user-adm-1',
        nombreCompleto: 'Laura Directora',
        correo: 'laura@sena.edu.co',
        rol: 'administrador',
        activo: true,
        createdAt: DateTime.now(),
      );

      expect(admin.esOperario, isFalse);
      expect(admin.esAdministrador, isTrue);
      expect(admin.esConsultorSiga, isFalse);
      expect(admin.puedeEditar, isTrue);
      expect(admin.puedeAdministrar, isTrue);
    });

    test('Permisos para rol Consultor SIGA', () {
      final siga = UsuarioPerfil(
        id: 'user-siga-1',
        nombreCompleto: 'Auditor SIGA',
        correo: 'auditoria@sena.edu.co',
        rol: 'consultor_siga',
        activo: true,
        createdAt: DateTime.now(),
      );

      expect(siga.esOperario, isFalse);
      expect(siga.esAdministrador, isFalse);
      expect(siga.esConsultorSiga, isTrue);
      expect(siga.puedeEditar, isFalse);
      expect(siga.puedeAdministrar, isFalse);
    });

    test('Serialización y deserialización de UsuarioPerfil', () {
      final ahora = DateTime.now();
      final perfil = UsuarioPerfil(
        id: 'abc-123',
        nombreCompleto: 'María Ruiz',
        correo: 'mruiz@sena.edu.co',
        rol: 'operario',
        activo: true,
        createdAt: ahora,
      );

      final mapa = perfil.toMap();
      expect(mapa['id'], 'abc-123');
      expect(mapa['rol'], 'operario');

      final deserializado = UsuarioPerfil.fromMap({
        'id': 'abc-123',
        'nombre_completo': 'María Ruiz',
        'correo': 'mruiz@sena.edu.co',
        'rol': 'operario',
        'activo': true,
        'created_at': ahora.toIso8601String(),
      });

      expect(deserializado.id, perfil.id);
      expect(deserializado.nombreCompleto, perfil.nombreCompleto);
      expect(deserializado.rol, perfil.rol);
    });
  });

  group('SesionUsuarioProvider (Manejo de Estado y Roles)', () {
    test('Inicialización y establecimiento de perfil', () async {
      final provider = SesionUsuarioProvider();

      expect(provider.estaAutenticado, isFalse);

      final perfilTest = UsuarioPerfil(
        id: 'test-1',
        nombreCompleto: 'Prueba Operario',
        correo: 'prueba@sena.edu.co',
        rol: 'operario',
        activo: true,
        createdAt: DateTime.now(),
      );

      provider.establecerPerfilPrueba(perfilTest);
      expect(provider.estaAutenticado, isTrue);
      expect(provider.perfil?.nombreCompleto, 'Prueba Operario');
      expect(provider.perfil?.esOperario, isTrue);

      await provider.cerrarSesion();
      expect(provider.estaAutenticado, isFalse);
      expect(provider.perfil, isNull);
    });

    test('Registro exitoso de nueva cuenta y posterior inicio de sesión', () async {
      final provider = SesionUsuarioProvider();

      // Registro de usuario nuevo
      final exito = await provider.registrarUsuario(
        correo: 'nuevo.operario@sena.edu.co',
        contrasena: 'clave123',
        nombreCompleto: 'Juan Pérez',
        rol: 'operario',
      );

      expect(exito, isTrue);
      expect(provider.estaAutenticado, isTrue);
      expect(provider.perfil?.correo, 'nuevo.operario@sena.edu.co');
      expect(provider.perfil?.nombreCompleto, 'Juan Pérez');
      expect(provider.perfil?.rol, 'operario');

      // Cerrar sesión
      await provider.cerrarSesion();
      expect(provider.estaAutenticado, isFalse);

      // Iniciar sesión con la cuenta recién creada
      final exitoLogin = await provider.iniciarSesion(
        'nuevo.operario@sena.edu.co',
        'clave123',
      );

      expect(exitoLogin, isTrue);
      expect(provider.estaAutenticado, isTrue);
      expect(provider.perfil?.nombreCompleto, 'Juan Pérez');
    });

    test('Validaciones de registro (correo duplicado o clave corta)', () async {
      final provider = SesionUsuarioProvider();

      // Clave menor a 6 caracteres
      final fallidoClave = await provider.registrarUsuario(
        correo: 'invalido@sena.edu.co',
        contrasena: '123',
        nombreCompleto: 'Test',
        rol: 'operario',
      );
      expect(fallidoClave, isFalse);
      expect(provider.mensajeError, contains('al menos 6 caracteres'));

      // Correo duplicado
      final fallidoDuplicado = await provider.registrarUsuario(
        correo: 'nuevo.operario@sena.edu.co',
        contrasena: 'password123',
        nombreCompleto: 'Otro',
        rol: 'operario',
      );
      expect(fallidoDuplicado, isFalse);
      expect(provider.mensajeError, contains('ya se encuentra registrado'));
    });
  });
}
