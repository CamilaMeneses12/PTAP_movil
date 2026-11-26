import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:planta_agua/core/routes/app_routes.dart';
import 'package:planta_agua/domain/alertas/catalogo_parametros_alerta.dart';
import 'package:planta_agua/domain/normatividad/normas_agua.dart';
import 'package:planta_agua/presentation/help/screens/ayuda_screen.dart';
import 'package:planta_agua/presentation/help/screens/normatividad_screen.dart';
import 'package:planta_agua/presentation/help/widgets/boton_ver_norma.dart';

void main() {
  test('Las 6 normas pedidas, con número, año, entidad, objeto y qué aplica en la PTAP', () {
    expect(NormasAgua.todas.map((n) => n.nombreCorto), [
      'Decreto 1575 de 2007',
      'Resolución 2115 de 2007',
      'Resolución 811 de 2008',
      'Resolución 082 de 2009',
      'Resolución 4716 de 2010',
      'Decreto 1076 de 2015',
    ]);
    for (final n in NormasAgua.todas) {
      expect(n.entidad, isNotEmpty);
      expect(n.deQueTrata, isNotEmpty);
      expect(n.aplicaEnPtap, isNotEmpty);
    }
    expect(NormasAgua.buscar(NormasAgua.decreto1575)!.nota, contains('Decreto 780 de 2016'));
  });

  test('Los parámetros del agua tratada enlazan con la Res. 2115 de 2007', () {
    for (final clave in ['ph_clorada', 'turbidez_clorada', 'color_clorada', 'cloro_clorada', 'cloro_red']) {
      final id = CatalogoParametrosAlerta.buscar(clave)!.referencia.normaId;
      expect(NormasAgua.buscar(id)?.numero, '2115', reason: clave);
    }
  });

  GoRouter router(String inicio) => GoRouter(
        initialLocation: inicio,
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Center(child: BotonVerNorma()))),
          GoRoute(path: AppRoutes.ayuda, builder: (_, _) => const AyudaScreen()),
          GoRoute(
            path: AppRoutes.normatividad,
            builder: (_, state) => NormatividadScreen(normaId: state.extra as String?),
          ),
        ],
      );

  testWidgets('Ayuda abre Normatividad con una tarjeta por norma', (tester) async {
    tester.view.physicalSize = const Size(1440, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router(AppRoutes.ayuda)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('abrir_normatividad')));
    await tester.pumpAndSettle();
    expect(find.text('Normatividad'), findsOneWidget);
    for (final n in NormasAgua.todas) {
      await tester.scrollUntilVisible(find.text(n.nombreCorto), 200);
      expect(find.text(n.nombreCorto), findsOneWidget);
    }
  });

  testWidgets('"Ver norma" abre la Res. 2115 con los rangos que valida la app', (tester) async {
    tester.view.physicalSize = const Size(1440, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router('/')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver norma'));
    await tester.pumpAndSettle();
    expect(find.text('Resolución 2115 de 2007'), findsOneWidget);
    expect(find.byKey(const Key('rangos_de_la_app')), findsOneWidget);
    expect(find.text('0,3–2,0 mg/L'), findsOneWidget);
    expect(find.text('6,5–9,0'), findsOneWidget);
  });
}
