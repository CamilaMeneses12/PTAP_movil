import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planta_agua/core/routes/app_routes.dart';
import 'package:planta_agua/data/models/item_historial_modelo.dart';
import 'package:planta_agua/data/models/umbral_alerta_modelo.dart';
import 'package:planta_agua/data/models/usuario_perfil.dart';
import 'package:planta_agua/data/repositories/umbrales_repository.dart';
import 'package:planta_agua/domain/calculations/estadisticas_perfil.dart';
import 'package:planta_agua/domain/validators/validador_rangos.dart';
import 'package:planta_agua/presentation/admin/providers/admin_provider.dart';
import 'package:planta_agua/presentation/alerts/providers/alertas_provider.dart';
import 'package:planta_agua/presentation/auth/providers/auth_provider.dart';
import 'package:planta_agua/presentation/auth/screens/perfil_screen.dart';
import 'package:planta_agua/presentation/history/providers/historial_provider.dart';
import 'package:planta_agua/presentation/settings/providers/preferencias_provider.dart';
import 'package:planta_agua/presentation/settings/providers/umbrales_provider.dart';

UsuarioPerfil _perfil(String rol, {String id = 'u-1', String nombre = 'Ana Pérez'}) => UsuarioPerfil(
      id: id,
      nombreCompleto: nombre,
      correo: '$rol@ptap.test',
      rol: rol,
      activo: true,
      createdAt: DateTime(2026, 1, 1),
    );

ItemHistorial _item(
  DateTime fecha, {
  TipoRegistroHistorial tipo = TipoRegistroHistorial.fisicoquimico,
  String responsable = 'Otro',
  String? creadoPorId,
  bool alerta = false,
}) =>
    ItemHistorial(
      id: '${fecha.millisecondsSinceEpoch}-${tipo.name}',
      tipo: tipo,
      fecha: fecha,
      hora: '08:00',
      titulo: 'Registro',
      subtitulo: '',
      responsable: responsable,
      creadoPorId: creadoPorId,
      tieneAlerta: alerta,
      objetoOriginal: null,
    );

void main() {
  group('Permisos de rutas por rol', () {
    final operario = _perfil('operario');
    final admin = _perfil('administrador');
    final consultor = _perfil('consultor_siga');

    test('El consultor no puede abrir formularios de creación ni administración', () {
      for (final ruta in AppRoutes.rutasEdicion) {
        expect(AppRoutes.rutaPermitida(consultor, ruta), isFalse, reason: ruta);
      }
      expect(AppRoutes.rutaPermitida(consultor, AppRoutes.admin), isFalse);
      expect(AppRoutes.rutaPermitida(consultor, AppRoutes.exportar), isTrue);
      expect(AppRoutes.rutaPermitida(consultor, AppRoutes.registros), isTrue);
    });

    test('El operario registra pero no administra', () {
      for (final ruta in AppRoutes.rutasEdicion) {
        expect(AppRoutes.rutaPermitida(operario, ruta), isTrue, reason: ruta);
      }
      expect(AppRoutes.rutaPermitida(operario, AppRoutes.admin), isFalse);
    });

    test('El administrador puede abrir todo', () {
      for (final ruta in [...AppRoutes.rutasEdicion, AppRoutes.admin, AppRoutes.perfil]) {
        expect(AppRoutes.rutaPermitida(admin, ruta), isTrue, reason: ruta);
      }
    });
  });

  group('Estadísticas del perfil', () {
    final ahora = DateTime(2026, 11, 19, 10);
    final yo = _perfil('operario', id: 'yo', nombre: 'Ana Pérez');

    test('Identifica registros propios por created_by o por nombre del responsable', () {
      expect(EstadisticasPerfil.esDelUsuario(_item(ahora, creadoPorId: 'yo'), yo), isTrue);
      expect(EstadisticasPerfil.esDelUsuario(_item(ahora, responsable: ' ana pérez '), yo), isTrue);
      expect(EstadisticasPerfil.esDelUsuario(_item(ahora, creadoPorId: 'otro'), yo), isFalse);
    });

    test('Días seguidos: cuenta la racha aunque hoy aún no haya registro', () {
      final items = [
        _item(DateTime(2026, 11, 18)),
        _item(DateTime(2026, 11, 17)),
        _item(DateTime(2026, 11, 15)),
      ];
      expect(EstadisticasPerfil.diasSeguidos(items, ahora), 2);
      expect(EstadisticasPerfil.diasSeguidos([...items, _item(DateTime(2026, 11, 19))], ahora), 3);
      expect(EstadisticasPerfil.diasSeguidos([_item(DateTime(2026, 11, 10))], ahora), 0);
    });

    test('Tareas de hoy marca solo los tipos registrados hoy', () {
      final tareas = EstadisticasPerfil.tareasDeHoy([
        _item(DateTime(2026, 11, 19, 7)),
        _item(DateTime(2026, 11, 18), tipo: TipoRegistroHistorial.medidores),
      ], ahora);
      expect(tareas[TipoRegistroHistorial.fisicoquimico], isTrue);
      expect(tareas[TipoRegistroHistorial.medidores], isFalse);
      expect(tareas[TipoRegistroHistorial.caudal], isFalse);
    });

    test('Cumplimiento: porcentaje de registros sin aviso', () {
      final items = [_item(ahora), _item(ahora), _item(ahora), _item(ahora, alerta: true)];
      expect(EstadisticasPerfil.porcentajeCumplimiento(items), closeTo(75, 0.001));
      expect(EstadisticasPerfil.porcentajeCumplimiento([]), isNull);
    });
  });

  group('Umbrales de alerta', () {
    test('Texto del rango con coma decimal', () {
      final u = UmbralesRepository.predeterminados();
      expect(u.firstWhere((e) => e.parametro == 'presion_red').rangoTexto, '2,8–4 bar');
      expect(u.firstWhere((e) => e.parametro == 'nivel_tanque').rangoTexto, 'mín. 40 %');
      expect(u.firstWhere((e) => e.clave == 'agua_clorada.turbidez').rangoTexto, 'máx. 2 NTU');
    });

    test('Aplicar un umbral cambia el rango que usa el validador', () {
      final original = ValidadorRangos.cloroMax;
      addTearDown(() => ValidadorRangos.cloroMax = original);

      UmbralesRepository.aplicarAValidador(const [
        UmbralAlerta(seccion: 'agua_clorada', parametro: 'cloro_residual', nombre: 'Cloro', unidad: 'mg/L', minimo: 0.3, maximo: 1.5),
      ]);
      expect(ValidadorRangos.cloroMax, 1.5);
      expect(ValidadorRangos.validarCloroResidual(1.8).cumple, isFalse);
    });

    test('El proveedor rechaza un mínimo mayor que el máximo', () async {
      final prov = UmbralesProvider();
      final u = prov.umbrales.first;
      final error = await prov.actualizar(u, minimo: 200, maximo: 100);
      expect(error, isNotNull);
    });
  });

  group('Perfil diferente por rol', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> montar(WidgetTester tester, UsuarioPerfil perfil) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      final sesion = SesionUsuarioProvider()..establecerPerfilPrueba(perfil);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: sesion),
            ChangeNotifierProvider(create: (_) => HistorialProvider()),
            ChangeNotifierProvider(create: (_) => AdminProvider()),
            ChangeNotifierProvider(create: (_) => AlertasProvider()),
            ChangeNotifierProvider(create: (_) => UmbralesProvider()),
            ChangeNotifierProvider(create: (_) => PreferenciasProvider()),
          ],
          child: const MaterialApp(home: PerfilScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Operario: tareas del día, umbrales en solo lectura y sin gestión', (tester) async {
      await montar(tester, _perfil('operario'));

      expect(find.text('Operador de planta'), findsOneWidget);
      expect(find.text('MIS TAREAS DE HOY'), findsOneWidget);
      expect(find.text('Usar cámara por defecto en medidores'), findsOneWidget);
      expect(find.text('UMBRALES DE ALERTA · SOLO LECTURA'), findsOneWidget);
      expect(find.text('GESTIÓN'), findsNothing);
      expect(find.text('Usuarios y roles'), findsNothing);
    });

    testWidgets('Administrador: resumen, gestión y umbrales editables', (tester) async {
      await montar(tester, _perfil('administrador'));

      expect(find.text('Administrador'), findsOneWidget);
      expect(find.text('RESUMEN DE LA PLANTA'), findsOneWidget);
      expect(find.text('GESTIÓN'), findsOneWidget);
      expect(find.text('Usuarios y roles'), findsOneWidget);
      expect(find.text('UMBRALES DE ALERTA · EDITABLES'), findsOneWidget);
      expect(find.text('MIS TAREAS DE HOY'), findsNothing);
    });

    testWidgets('Consultor: cumplimiento y consulta, sin acciones de registro', (tester) async {
      await montar(tester, _perfil('consultor_siga'));

      expect(find.text('Consultor SIGA · solo lectura'), findsOneWidget);
      expect(find.text('Reportes y exportación (PDF / Excel)'), findsOneWidget);
      expect(find.text('UMBRALES DE ALERTA · SOLO LECTURA'), findsOneWidget);
      expect(find.text('Registrar'), findsNothing);
      expect(find.text('GESTIÓN'), findsNothing);
      expect(find.text('MIS TAREAS DE HOY'), findsNothing);
    });

    testWidgets('Solo el administrador abre el editor de umbrales', (tester) async {
      await montar(tester, _perfil('operario'));
      await tester.tap(find.byKey(const Key('umbral_operacion.caudal_entrada')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
