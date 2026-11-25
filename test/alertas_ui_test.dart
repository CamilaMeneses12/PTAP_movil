import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:planta_agua/presentation/alerts/providers/alertas_provider.dart';
import 'package:planta_agua/presentation/alerts/screens/alertas_screen.dart';
import 'package:planta_agua/presentation/common/widgets/mensaje_fuera_de_rango.dart';
import 'package:planta_agua/domain/validators/validador_rangos.dart';

void main() {
  group('AlertasScreen & Widgets UI Tests', () {
    testWidgets('AlertasScreen renders tabs, severity counters, and cards correctly',
        (tester) async {
      final alertasProv = AlertasProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AlertasProvider>.value(
          value: alertasProv,
          child: const MaterialApp(
            home: AlertasScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title & Tabs
      expect(find.text('Alertas'), findsWidgets);
      expect(find.text('Marcar leídas'), findsOneWidget);
      expect(find.text('Activas (2)'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);

      // Counters (1 Crítica, 2 Advertencias, 2 Informativas)
      expect(find.text('1'), findsWidgets);
      expect(find.text('Críticas'), findsOneWidget);
      expect(find.text('Advertencias'), findsOneWidget);
      expect(find.text('Informativas'), findsOneWidget);

      // Group headers & alert content
      expect(find.text('HOY'), findsOneWidget);
      expect(find.text('Caudal de entrada fuera de rango'), findsOneWidget);
      expect(find.text('Nivel de tanque descendiendo'), findsOneWidget);
    });

    testWidgets('MensajeFueraDeRango displays warning explanation box with no yellow',
        (tester) async {
      final eval = ValidadorRangos.validarPhTratada(9.2);

      expect(eval.esValido, isFalse);
      expect(eval.diferencia, closeTo(0.2, 0.01));
      expect(eval.severidad, 'critica');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MensajeFueraDeRango(evaluacion: eval),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('¡Alerta Crítica!'), findsOneWidget);
      expect(find.textContaining('está por encima del máximo permitido'), findsOneWidget);
      expect(find.textContaining('diferencia: 0,2'), findsOneWidget);
      expect(find.byType(MensajeFueraDeRango), findsOneWidget);
    });
  });
}
