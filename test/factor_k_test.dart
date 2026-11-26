import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:planta_agua/data/models/usuario_perfil.dart';
import 'package:planta_agua/domain/calculations/calculos_caudal.dart';
import 'package:planta_agua/presentation/alerts/providers/alertas_provider.dart';
import 'package:planta_agua/presentation/auth/providers/auth_provider.dart';
import 'package:planta_agua/presentation/flow/providers/caudal_provider.dart';
import 'package:planta_agua/presentation/flow/screens/formulario_aforo_caudal_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  group('Factor de corrección K', () {
    test('Rango válido de 0,60 a 0,95', () {
      expect(CalculosCaudal.validarFactorCorreccion(0.80), isNull);
      expect(CalculosCaudal.validarFactorCorreccion(0.60), isNull);
      expect(CalculosCaudal.validarFactorCorreccion(0.95), isNull);
      expect(CalculosCaudal.validarFactorCorreccion(0.59), isNotNull);
      expect(CalculosCaudal.validarFactorCorreccion(0.96), isNotNull);
      expect(CalculosCaudal.validarFactorCorreccion(null), isNotNull);
    });

    test('La velocidad corregida y el caudal usan el K recibido', () {
      ResultadoCaudal calcular(double k) => CalculosCaudal.calcular(
            anchoCauceM: 0.41,
            profundidad1M: 0.09,
            profundidad2M: 0.06,
            profundidad3M: 0.05,
            profundidad4M: 0.06,
            distanciaFlotadorM: 3,
            tiempo1S: 7.55,
            tiempo2S: 5.66,
            tiempo3S: 8.59,
            tiempo4S: 7.03,
            factorCorreccion: k,
          );
      final con080 = calcular(0.80);
      final con070 = calcular(0.70);
      expect(con070.velocidadSuperficialMS, con080.velocidadSuperficialMS);
      expect(con070.velocidadCorregidaMS, closeTo(con070.velocidadSuperficialMS * 0.70, 1e-12));
      expect(con070.caudalLS / con080.caudalLS, closeTo(0.70 / 0.80, 1e-9));
    });
  });

  testWidgets('Nuevo Aforo: K editable que recalcula en vivo y se guarda en el aforo', (tester) async {
    // Pantalla ancha: la fuente de pruebas dibuja cada letra como un bloque y desborda
    // los encabezados largos que ya tenía el formulario.
    tester.view.physicalSize = const Size(1600, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final caudal = CaudalProvider();
    final sesion = SesionUsuarioProvider()
      ..establecerPerfilPrueba(UsuarioPerfil(
        id: 'karol',
        nombreCompleto: 'Karol Operaria',
        correo: 'karol@ptap.test',
        rol: 'operario',
        activo: true,
        createdAt: DateTime(2026, 1, 1),
      ));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: sesion),
          ChangeNotifierProvider(create: (_) => AlertasProvider()),
          ChangeNotifierProvider.value(value: caudal),
        ],
        // Con go_router, como en la app: al guardar, el formulario vuelve a la pantalla anterior.
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/nuevo',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: Text('Lista de aforos')),
                routes: [GoRoute(path: 'nuevo', builder: (_, _) => const FormularioAforoCaudalScreen())],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final campoK = find.byKey(const Key('campo_factor_k'));
    expect(find.textContaining('(K = 0,80)'), findsOneWidget);
    expect(find.text('Velocidad superficial'), findsOneWidget);

    String velocidadCorregida() => tester
        .widget<Text>(find.descendant(of: find.byKey(const Key('velocidad_corregida')), matching: find.byType(Text)).last)
        .data!;
    final antes = velocidadCorregida();

    await tester.scrollUntilVisible(campoK, 200, scrollable: find.byType(Scrollable).first);
    expect(find.descendant(of: campoK, matching: find.text('0,80')), findsOneWidget);
    expect(find.textContaining('arenoso o con piedras'), findsOneWidget);
    await tester.enterText(campoK, '0,70');
    await tester.pump();
    expect(find.textContaining('(K = 0,70)'), findsOneWidget);
    expect(velocidadCorregida(), isNot(antes));

    await tester.enterText(campoK, '0,50');
    await tester.pump();
    expect(find.text('K debe estar entre 0,60 y 0,95'), findsOneWidget);
    expect(velocidadCorregida(), 'Ingrese un K entre 0,60 y 0,95');

    await tester.enterText(campoK, '0,85');
    await tester.pump();
    final total = caudal.aforos.length;
    await tester.scrollUntilVisible(find.text('Guardar Aforo de Caudal'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Guardar Aforo de Caudal'));
    await tester.pumpAndSettle();
    // Con los valores de ejemplo el caudal queda bajo 10 L/s: se muestra el aviso y luego se guarda.
    if (find.text('Entendido').evaluate().isNotEmpty) {
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Lista de aforos'), findsOneWidget);
    expect(caudal.aforos.length, total + 1);
    expect(caudal.aforos.last.factorCorreccion, 0.85);
  });
}
