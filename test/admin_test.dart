import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/data/repositories/admin_repository.dart';
import 'package:planta_agua/presentation/admin/providers/admin_provider.dart';

void main() {
  group('Módulo de Administración (Usuarios y Catálogos)', () {
    late AdminRepository repository;
    late AdminProvider provider;

    setUp(() {
      repository = AdminRepository();
      provider = AdminProvider(repository: repository);
    });

    test('AdminRepository lista usuarios iniciales con diferentes roles', () async {
      final usuarios = await repository.obtenerUsuarios();
      expect(usuarios.isNotEmpty, isTrue);

      final tieneAdmin = usuarios.any((u) => u.rol == 'administrador');
      final tieneOperario = usuarios.any((u) => u.rol == 'operario');
      final tieneSiga = usuarios.any((u) => u.rol == 'consultor_siga');

      expect(tieneAdmin, isTrue);
      expect(tieneOperario, isTrue);
      expect(tieneSiga, isTrue);
    });

    test('AdminProvider modifica el rol de un usuario y notifica cambios', () async {
      await provider.cargarTodo();
      final usuario = provider.usuarios.firstWhere((u) => u.rol == 'operario');

      await provider.cambiarRolUsuario(usuario.id, 'administrador');
      final actualizado = provider.usuarios.firstWhere((u) => u.id == usuario.id);

      expect(actualizado.rol, 'administrador');
      expect(provider.mensajeExito, isNotNull);
    });

    test('AdminProvider alterna el estado activo/inactivo de un usuario', () async {
      await provider.cargarTodo();
      final usuario = provider.usuarios.first;
      final estadoInicial = usuario.activo;

      await provider.toggleEstadoUsuario(usuario.id);
      final actualizado = provider.usuarios.firstWhere((u) => u.id == usuario.id);

      expect(actualizado.activo, !estadoInicial);
    });

    test('AdminRepository carga los 9 medidores oficiales y permite activarlos/desactivarlos', () async {
      final medidores = await repository.obtenerCatalogoMedidores();
      expect(medidores.length, 9);

      final primerMedidor = medidores.first;
      await repository.actualizarEstadoMedidor(primerMedidor.id, false);

      final actualizados = await repository.obtenerCatalogoMedidores();
      expect(actualizados.first.activo, isFalse);
    });

    test('AdminRepository actualiza rangos normativos de parámetros fisicoquímicos', () async {
      final parametros = await repository.obtenerCatalogoParametros();
      expect(parametros.isNotEmpty, isTrue);

      final paramCloro = parametros.firstWhere((p) => p.codigo == 'CLORO_RESIDUAL');
      expect(paramCloro.valorMin, 0.3);
      expect(paramCloro.valorMax, 2.0);

      // Calibrar a nuevo rango
      await repository.actualizarRangoParametro(paramCloro.id, 0.5, 2.5);

      final parametrosNuevos = await repository.obtenerCatalogoParametros();
      final paramActualizado = parametrosNuevos.firstWhere((p) => p.id == paramCloro.id);
      expect(paramActualizado.valorMin, 0.5);
      expect(paramActualizado.valorMax, 2.5);
    });

    test('AdminProvider actualiza rango de parámetro y emite mensaje de éxito', () async {
      await provider.cargarTodo();
      final paramPh = provider.parametros.firstWhere((p) => p.codigo == 'PH_TRATADA');

      await provider.actualizarRangoParametro(paramPh.id, 6.8, 8.8);
      final modificado = provider.parametros.firstWhere((p) => p.id == paramPh.id);

      expect(modificado.valorMin, 6.8);
      expect(modificado.valorMax, 8.8);
      expect(provider.mensajeExito, contains('Rangos'));
    });
  });
}
