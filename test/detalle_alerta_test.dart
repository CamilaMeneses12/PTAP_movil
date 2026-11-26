import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:planta_agua/core/routes/app_routes.dart';
import 'package:planta_agua/data/models/alerta_sistema_modelo.dart';
import 'package:planta_agua/data/models/registro_fisicoquimico.dart';
import 'package:planta_agua/data/models/usuario_perfil.dart';
import 'package:planta_agua/domain/alertas/catalogo_parametros_alerta.dart';
import 'package:planta_agua/domain/validators/validador_rangos.dart';
import 'package:planta_agua/presentation/alerts/providers/alertas_provider.dart';
import 'package:planta_agua/presentation/alerts/screens/alertas_screen.dart';
import 'package:planta_agua/presentation/alerts/screens/detalle_alerta_screen.dart';
import 'package:planta_agua/presentation/auth/providers/auth_provider.dart';
import 'package:planta_agua/presentation/flow/providers/caudal_provider.dart';
import 'package:planta_agua/presentation/meters/providers/medidores_provider.dart';
import 'package:planta_agua/presentation/physicochemical/providers/fisicoquimico_provider.dart';

RegistroFisicoquimico _registro(String id, DateTime fecha, double cloro) => RegistroFisicoquimico(
      id: id,
      fecha: fecha,
      hora: '08:00',
      cloradaCloroResidual: cloro,
      responsableNombre: 'Karol',
      createdBy: 'karol',
      createdAt: fecha,
    );

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  test('Catálogo: historial de los últimos 10 valores con cuántos estuvieron fuera de rango', () {
    final registros = [
      for (var d = 1; d <= 12; d++) _registro('r$d', DateTime(2026, 11, d), d.isEven ? 0.2 : 1.0),
    ];
    final alerta = AlertaSistema(
      id: 'a',
      titulo: 'Cloro bajo',
      descripcion: '',
      severidad: SeveridadAlerta.critica,
      fechaHora: DateTime(2026, 11, 25),
      hora: '08:00',
      parametroClave: 'cloro_clorada',
      valorRegistrado: 0.2,
    );
    final h = CatalogoParametrosAlerta.historial(alerta, fisicoquimicos: registros, jornadas: const [], aforos: const []);
    expect(h.length, 10);
    expect(h.first.momento.day, 3);
    expect(h.where((v) => v.fueraDeRango).length, 5);

    final e = CatalogoParametrosAlerta.evaluar(alerta)!;
    expect(e.cumple, isFalse);
    expect(e.explicacion, contains('Desinfección insuficiente'));
    expect(CatalogoParametrosAlerta.buscar('cloro_clorada')!.acciones(e).first, contains('dosificación de cloro'));
  });

  testWidgets('Detalle de alerta: secciones, registro de origen, leída al abrir y resuelta con nota', (tester) async {
    tester.view.physicalSize = const Size(1440, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final fisico = FisicoquimicoProvider();
    await fisico.cargarRegistros();
    for (var d = 1; d <= 3; d++) {
      await fisico.guardarRegistro(_registro('hist-$d', DateTime(2026, 11, 20 + d), d == 2 ? 0.1 : 1.2));
    }
    await fisico.guardarRegistro(_registro('reg-origen', DateTime(2026, 11, 25), 0.2));

    final alertas = AlertasProvider()
      ..agregarDesdeEvaluacion(
        evaluacion: ValidadorRangos.validarCloroResidual(0.2, nombre: 'Cloro Residual Clorada'),
        titulo: 'Cloro residual libre fuera de rango',
        parametro: 'Cloro residual libre',
        parametroClave: 'cloro_clorada',
        tipoFormato: TipoFormatoAlerta.fisicoquimico,
        registroId: 'reg-origen',
        responsable: 'Karol',
      );
    final id = alertas.todas.single.id;
    expect(alertas.todas.single.estado, EstadoAlerta.nueva);

    final sesion = SesionUsuarioProvider()
      ..establecerPerfilPrueba(UsuarioPerfil(
        id: 'karol',
        nombreCompleto: 'Karol Operaria',
        correo: 'karol@ptap.test',
        rol: 'operario',
        activo: true,
        createdAt: DateTime(2026, 1, 1),
      ));

    final router = GoRouter(
      initialLocation: AppRoutes.alertas,
      routes: [
        GoRoute(path: AppRoutes.alertas, builder: (_, _) => const AlertasScreen()),
        GoRoute(
          path: '${AppRoutes.alertaDetalle}/:id',
          builder: (_, state) => DetalleAlertaScreen(alertaId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: AppRoutes.fisicoquimicoDetalle,
          builder: (_, state) => Scaffold(body: Text('Detalle ${(state.extra as RegistroFisicoquimico).id}')),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: sesion),
          ChangeNotifierProvider.value(value: alertas),
          ChangeNotifierProvider.value(value: fisico),
          ChangeNotifierProvider(create: (_) => MedidoresProvider()),
          ChangeNotifierProvider(create: (_) => CaudalProvider()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Tocar la alerta abre su detalle en una ruta propia.
    await tester.tap(find.text('Cloro residual libre fuera de rango'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle de alerta'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation, AppRoutes.rutaAlerta(id));

    // Abrir el detalle la marca como leída, no como resuelta.
    expect(alertas.buscar(id)!.estado, EstadoAlerta.leida);

    for (final seccion in [
      'Qué pasó',
      'Dónde y cuándo',
      'Historial del parámetro',
      'Posibles causas y qué revisar',
      'Norma',
      'Seguimiento',
    ]) {
      await tester.scrollUntilVisible(find.text(seccion), 150, scrollable: find.byType(Scrollable).first);
      expect(find.text(seccion), findsOneWidget);
    }

    await tester.scrollUntilVisible(find.text('Qué pasó'), -150, scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('barra_rango')), findsOneWidget);
    expect(find.text('Crítica'), findsOneWidget);
    expect(find.text('0,1 mg/L (33,33 %) por debajo del mínimo'), findsOneWidget);
    expect(find.text('DO-F-070 · Análisis fisicoquímico'), findsOneWidget);

    await tester.scrollUntilVisible(find.byKey(const Key('texto_historial')), 150,
        scrollable: find.byType(Scrollable).first);
    expect(
      tester.widget<Text>(find.byKey(const Key('texto_historial'))).data,
      matches(RegExp(r'^\d+ de los últimos \d+ registros (estuvo|estuvieron) fuera de rango$')),
    );
    expect(find.textContaining('Desinfección insuficiente'), findsOneWidget);
    expect(find.textContaining('Repetir la medición en 30 min.'), findsOneWidget);
    expect(find.text('Resolución 2115 de 2007'), findsOneWidget);

    // Resolver con nota: queda quién y cuándo.
    await tester.scrollUntilVisible(find.byKey(const Key('marcar_resuelta')), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('marcar_resuelta')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('nota_resolucion')), 'Se ajustó la dosificación');
    await tester.tap(find.text('Resolver'));
    await tester.pumpAndSettle();

    final resuelta = alertas.buscar(id)!;
    expect(resuelta.estado, EstadoAlerta.resuelta);
    expect(resuelta.resueltaPor, 'Karol Operaria');
    expect(resuelta.notaResolucion, 'Se ajustó la dosificación');
    expect(resuelta.fechaResolucion, isNotNull);
    expect(find.byKey(const Key('marcar_resuelta')), findsNothing);
    expect(find.text('Se ajustó la dosificación'), findsOneWidget);

    // "Ver registro completo" abre el registro que originó la alerta.
    await tester.scrollUntilVisible(find.byKey(const Key('ver_registro_completo')), -150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('ver_registro_completo')));
    await tester.pumpAndSettle();
    expect(find.text('Detalle reg-origen'), findsOneWidget);
  });
}

