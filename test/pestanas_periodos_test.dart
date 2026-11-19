import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:planta_agua/data/models/usuario_perfil.dart';
import 'package:planta_agua/domain/telemetria/telemetria_planta.dart';
import 'package:planta_agua/presentation/auth/providers/auth_provider.dart';
import 'package:planta_agua/presentation/flow/screens/monitoreo_screen.dart';
import 'package:planta_agua/presentation/history/providers/historial_provider.dart';
import 'package:planta_agua/presentation/history/screens/historial_screen.dart';
import 'package:planta_agua/presentation/reports/screens/estadisticas_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  Future<void> pantallaGrande(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
  }

  group('Telemetría simulada', () {
    test('Es determinista: la misma hora siempre da el mismo valor', () {
      final t = DateTime(2026, 11, 19, 9);
      final a = TelemetriaPlanta.muestra(t);
      final b = TelemetriaPlanta.muestra(t.add(const Duration(minutes: 37)));
      expect(a.caudalEntrada, b.caudalEntrada);
      expect(a.presion, b.presion);
      expect(a.nivelTanque, b.nivelTanque);
    });

    test('No genera datos futuros y agrega por día', () {
      final ahora = DateTime(2026, 11, 19, 10, 30);
      final hoy = TelemetriaPlanta.resumenDia(ahora, ahora: ahora);
      expect(hoy.horas, 11); // 00:00 a 10:00
      final semana = TelemetriaPlanta.resumenDiario(DateTime(2026, 11, 13), ahora, ahora: ahora);
      expect(semana.length, 7);
      expect(semana.first.horas, 24);
      expect(semana.first.volumenM3, greaterThan(0));
    });
  });

  testWidgets('Monitoreo: Caudal, Presión y Nivel muestran gráficas distintas', (tester) async {
    await pantallaGrande(tester);
    await tester.pumpWidget(const MaterialApp(home: MonitoreoScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Caudal de entrada vs. salida'), findsOneWidget);
    expect(find.text('Presión de la red de distribución'), findsNothing);

    await tester.tap(find.text('Presión'));
    await tester.pumpAndSettle();
    expect(find.text('Presión de la red de distribución'), findsOneWidget);
    expect(find.text('Caudal de entrada vs. salida'), findsNothing);

    await tester.tap(find.text('Nivel'));
    await tester.pumpAndSettle();
    expect(find.text('Nivel del tanque de almacenamiento'), findsOneWidget);
    expect(find.textContaining('Mínimo operativo'), findsOneWidget);
  });

  testWidgets('Estadísticas: Día, Semana y Mes cambian periodo, barras y evolución', (tester) async {
    await pantallaGrande(tester);
    await tester.pumpWidget(const MaterialApp(home: EstadisticasScreen()));
    await tester.pumpAndSettle();

    String periodo() => tester.widget<Text>(find.byKey(const Key('etiqueta_periodo'))).data!;

    final semana = periodo();
    expect(find.text('Tratamiento diario'), findsOneWidget);
    expect(find.text('Últimas 8 semanas · promedio m³/día'), findsOneWidget);
    expect(find.text('Total semana'), findsOneWidget);

    await tester.tap(find.text('Día'));
    await tester.pumpAndSettle();
    expect(find.text('Tratamiento por hora'), findsOneWidget);
    expect(find.text('Total día'), findsOneWidget);
    expect(periodo(), isNot(semana));

    await tester.tap(find.text('Mes'));
    await tester.pumpAndSettle();
    expect(find.text('Total mes'), findsOneWidget);
    expect(find.text('Últimos 6 meses · promedio m³/día'), findsOneWidget);

    // La flecha izquierda cambia al mes anterior
    final mes = periodo();
    await tester.tap(find.byTooltip('Periodo anterior'));
    await tester.pumpAndSettle();
    expect(periodo(), isNot(mes));
  });

  testWidgets('Registros: Hoy, 7 días y 30 días muestran filas distintas', (tester) async {
    await pantallaGrande(tester);
    final sesion = SesionUsuarioProvider()
      ..establecerPerfilPrueba(UsuarioPerfil(
        id: 'u-1',
        nombreCompleto: 'Ana Pérez',
        correo: 'op@ptap.test',
        rol: 'operario',
        activo: true,
        createdAt: DateTime(2026, 1, 1),
      ));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: sesion),
          ChangeNotifierProvider(create: (_) => HistorialProvider()),
        ],
        child: const MaterialApp(home: HistorialScreen()),
      ),
    );
    await tester.pumpAndSettle();

    String periodo() => tester.widget<Text>(find.byKey(const Key('texto_periodo'))).data!;

    expect(periodo(), startsWith('Hoy'));
    expect(find.text('${DateTime.now().hour + 1} registros'), findsOneWidget);

    await tester.tap(find.text('7 días'));
    await tester.pumpAndSettle();
    expect(periodo(), 'Últimos 7 días · Promedio diario');
    expect(find.text('7 registros'), findsOneWidget);

    await tester.tap(find.text('30 días'));
    await tester.pumpAndSettle();
    expect(periodo(), 'Últimos 30 días · Promedio diario');
    expect(find.text('30 registros'), findsOneWidget);

    await tester.tap(find.text('Cargar registros anteriores'));
    await tester.pumpAndSettle();
    expect(find.text('60 registros'), findsOneWidget);

    await tester.ensureVisible(find.text('Fuera de rango'));
    await tester.tap(find.text('Fuera de rango'));
    await tester.pumpAndSettle();
    expect(periodo(), 'Horas fuera de rango · Últimos 30 días');
  });
}
