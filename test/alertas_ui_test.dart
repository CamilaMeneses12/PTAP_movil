import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:planta_agua/data/models/alerta_sistema_modelo.dart';
import 'package:planta_agua/presentation/alerts/providers/alertas_provider.dart';
import 'package:planta_agua/presentation/alerts/screens/alertas_screen.dart';
import 'package:planta_agua/presentation/common/widgets/mensaje_fuera_de_rango.dart';
import 'package:planta_agua/domain/validators/validador_rangos.dart';

void main() {
  group('AlertasScreen & Widgets UI Tests', () {
    testWidgets('AlertasScreen renders tabs, severity counters, and cards correctly',
        (tester) async {
      // Las alertas salen de los registros del operario: aquí se crean como lo hacen los formularios.
      final alertasProv = AlertasProvider()
        ..agregarAlerta(
          titulo: 'Agua no registrada fuera de rango',
          descripcion: 'Balance con ANR de 6,2 m³.',
          severidad: SeveridadAlerta.advertencia,
          parametroClave: 'agua_no_registrada',
          valorRegistrado: 6.2,
          maximo: 5,
          unidad: 'm³',
        )
        ..agregarDesdeEvaluacion(
          evaluacion: ValidadorRangos.validarPhTratada(9.4, nombre: 'pH Agua Clorada'),
          titulo: 'pH agua tratada fuera de rango',
          parametro: 'pH agua tratada',
          parametroClave: 'ph_clorada',
          tipoFormato: TipoFormatoAlerta.fisicoquimico,
          registroId: 'reg-1',
          responsable: 'Karol',
        );

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

      // Counters (1 Crítica, 1 Advertencia)
      expect(find.text('1'), findsWidgets);
      expect(find.text('Críticas'), findsOneWidget);
      expect(find.text('Advertencias'), findsOneWidget);
      expect(find.text('Informativas'), findsOneWidget);

      // Group headers & alert content
      expect(find.text('HOY'), findsOneWidget);
      expect(find.text('pH agua tratada fuera de rango'), findsOneWidget);
      expect(find.text('Agua no registrada fuera de rango'), findsOneWidget);
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
