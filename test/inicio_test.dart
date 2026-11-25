import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:planta_agua/data/models/aforo_caudal_modelo.dart';
import 'package:planta_agua/data/models/alerta_sistema_modelo.dart';
import 'package:planta_agua/data/models/medidores_modelos.dart';
import 'package:planta_agua/data/models/registro_fisicoquimico.dart';
import 'package:planta_agua/data/models/usuario_perfil.dart';
import 'package:planta_agua/domain/calculations/resumen_inicio.dart';
import 'package:planta_agua/presentation/alerts/providers/alertas_provider.dart';
import 'package:planta_agua/presentation/auth/providers/auth_provider.dart';
import 'package:planta_agua/presentation/flow/providers/caudal_provider.dart';
import 'package:planta_agua/presentation/flow/screens/monitoreo_screen.dart';
import 'package:planta_agua/presentation/history/providers/historial_provider.dart';
import 'package:planta_agua/presentation/home/screens/home_screen.dart';
import 'package:planta_agua/presentation/meters/providers/medidores_provider.dart';
import 'package:planta_agua/presentation/physicochemical/providers/fisicoquimico_provider.dart';

RegistroFisicoquimico _fisico(DateTime fecha, String hora, {double? cloro, double? ph, double? turbidez}) =>
    RegistroFisicoquimico(
      id: 'f-${fecha.toIso8601String()}-$hora',
      fecha: fecha,
      hora: hora,
      cloradaCloroResidual: cloro,
      cloradaPh: ph,
      cloradaTurbidez: turbidez,
      responsableNombre: 'Karol',
      createdBy: 'karol',
      createdAt: fecha,
    );

AforoCaudal _aforo(DateTime fecha, String hora, double caudalLS) => AforoCaudal(
      id: 'a-${fecha.toIso8601String()}-$hora',
      fecha: fecha,
      hora: hora,
      anchoCauceM: 1,
      profundidad1M: 0.1,
      profundidad2M: 0.1,
      profundidad3M: 0.1,
      profundidad4M: 0.1,
      distanciaFlotadorM: 5,
      tiempo1S: 10,
      tiempo2S: 10,
      tiempo3S: 10,
      tiempo4S: 10,
      profundidadPromedioM: 0.1,
      areaSeccionM2: 0.1,
      tiempoPromedioS: 10,
      velocidadSuperficialMS: 0.5,
      velocidadCorregidaMS: 0.4,
      caudalM3S: caudalLS / 1000,
      caudalM3H: caudalLS * 3.6,
      caudalLS: caudalLS,
      caudalLH: caudalLS * 3600,
      createdBy: 'karol',
      createdAt: fecha,
    );

JornadaMedidores _jornada(DateTime fecha, {required double macro, required double anr}) => JornadaMedidores(
      id: 'j-${fecha.toIso8601String()}',
      fecha: fecha,
      hora: '08:00',
      responsableLectura: 'Karol',
      consumoTotalMicros: macro - anr,
      consumoMacromedidor: macro,
      aguaNoRegistrada: anr,
      createdBy: 'karol',
      createdAt: fecha,
    );

AlertaSistema _alerta(String id, SeveridadAlerta s, DateTime t) =>
    AlertaSistema(id: id, titulo: 'Alerta $id', descripcion: '', severidad: s, fechaHora: t, hora: '00:00');

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  final hoy = DateTime(2026, 11, 25, 10);

  group('ResumenInicio', () {
    test('Pendientes de hoy: marca solo los formatos con registro de hoy', () {
      final estado = ResumenInicio.pendientesDeHoy(
        fisicoquimicos: [_fisico(DateTime(2026, 11, 25), '07:00')],
        jornadas: [_jornada(DateTime(2026, 11, 24), macro: 10, anr: 1)],
        aforos: const [],
        ahora: hoy,
      );
      expect(estado[FormatoDiario.fisicoquimico], isTrue);
      expect(estado[FormatoDiario.medidores], isFalse);
      expect(estado[FormatoDiario.aforo], isFalse);
    });

    test('Calidad: toma el registro más reciente por fecha y hora y evalúa cloro, pH y turbidez', () {
      final calidad = ResumenInicio.calidadAguaTratada([
        _fisico(DateTime(2026, 11, 25), '06:00', cloro: 1.0, ph: 7, turbidez: 0.5),
        _fisico(DateTime(2026, 11, 25), '14:00', cloro: 0.2, ph: 7, turbidez: 0.5),
        _fisico(DateTime(2026, 11, 24), '20:00', cloro: 1.1, ph: 7, turbidez: 0.5),
      ])!;
      expect(calidad.registro.hora, '14:00');
      expect(calidad.cloro.cumple, isFalse);
      expect(calidad.conforme, isFalse);
      expect(ResumenInicio.calidadAguaTratada(const []), isNull);
    });

    test('Tendencia de cloro: últimos 7 en orden cronológico, ignorando registros sin cloro', () {
      final registros = [
        for (var d = 1; d <= 9; d++) _fisico(DateTime(2026, 11, d), '08:00', cloro: d / 10),
        _fisico(DateTime(2026, 11, 10), '08:00'),
      ];
      final puntos = ResumenInicio.tendenciaCloro(registros);
      expect(puntos.length, 7);
      expect(puntos.first.valor, closeTo(0.3, 1e-9));
      expect(puntos.last.valor, closeTo(0.9, 1e-9));
    });

    test('Caudal de la quebrada: diferencia frente al aforo anterior', () {
      final c = ResumenInicio.caudalQuebrada([
        _aforo(DateTime(2026, 11, 20), '09:00', 21),
        _aforo(DateTime(2026, 11, 25), '09:00', 19.5),
      ])!;
      expect(c.ultimo.caudalLS, 19.5);
      expect(c.diferenciaLS, closeTo(-1.5, 1e-9));
      expect(ResumenInicio.caudalQuebrada([_aforo(hoy, '09:00', 20)])!.diferenciaLS, isNull);
    });

    test('Pérdidas: elevada cuando el agua no registrada supera 5 m³', () {
      expect(ResumenInicio.perdidaElevada(_jornada(hoy, macro: 40, anr: 5.5)), isTrue);
      expect(ResumenInicio.perdidaElevada(_jornada(hoy, macro: 40, anr: 5)), isFalse);
    });

    test('Alertas: cuenta por severidad y devuelve la más reciente', () {
      final r = ResumenInicio.resumenAlertas([
        _alerta('a', SeveridadAlerta.critica, DateTime(2026, 11, 25, 8)),
        _alerta('b', SeveridadAlerta.advertencia, DateTime(2026, 11, 25, 9)),
        _alerta('c', SeveridadAlerta.advertencia, DateTime(2026, 11, 24, 9)),
      ]);
      expect((r.criticas, r.advertencias, r.informativas, r.total), (1, 2, 0, 3));
      expect(r.masReciente!.id, 'b');
    });
  });

  group('Pantallas', () {
    Future<void> pantallaGrande(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
    }

    testWidgets('Inicio: tarjetas calculadas, sin valores fijos, y se actualiza al guardar', (tester) async {
      await pantallaGrande(tester);
      final fisico = FisicoquimicoProvider();
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
            ChangeNotifierProvider(create: (_) => HistorialProvider()),
            ChangeNotifierProvider.value(value: fisico),
            ChangeNotifierProvider(create: (_) => CaudalProvider()),
            ChangeNotifierProvider(create: (_) => MedidoresProvider()),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      for (final titulo in [
        'Pendientes de hoy',
        'Calidad del agua tratada',
        'Tendencia de cloro residual',
        'Caudal de la Quebrada La Seca',
        'Pérdidas de agua',
        'Alertas activas',
      ]) {
        await tester.scrollUntilVisible(find.text(titulo), 200);
        expect(find.text(titulo), findsOneWidget);
      }
      for (final fijo in ['128,4', '4.286', 'Nivel de almacenamiento', 'Caudal de salida', 'Presión de red']) {
        expect(find.textContaining(fijo), findsNothing);
      }

      // Los datos de ejemplo son de fechas pasadas: los 3 formatos están pendientes.
      await tester.scrollUntilVisible(find.text('Pendientes de hoy'), -200);
      expect(find.text('0 de 3'), findsOneWidget);

      // Guardar un DO-F-070 con fecha de hoy marca ese formato sin recargar la pantalla.
      final ahora = DateTime.now();
      await fisico.guardarRegistro(
        _fisico(DateTime(ahora.year, ahora.month, ahora.day), '23:59', cloro: 1.0, ph: 7.2, turbidez: 0.4),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 de 3'), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const Key('pendiente_fisicoquimico')), matching: find.byIcon(Icons.check_circle_rounded)),
        findsOneWidget,
      );
      expect(find.text('Conforme'), findsOneWidget);
    });

    testWidgets('Monitoreo: Caudal usa los aforos y Calidad el DO-F-070, sin telemetría simulada', (tester) async {
      await pantallaGrande(tester);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => FisicoquimicoProvider()),
            ChangeNotifierProvider(create: (_) => CaudalProvider()),
          ],
          child: const MaterialApp(home: MonitoreoScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Caudal de la Quebrada La Seca'), findsOneWidget);
      expect(find.textContaining('Datos simulados'), findsNothing);
      expect(find.text('Nivel'), findsNothing);
      expect(find.text('Presión'), findsNothing);

      await tester.tap(find.text('Calidad'));
      await tester.pumpAndSettle();
      expect(find.text('Cloro residual libre'), findsOneWidget);

      await tester.tap(find.text('pH'));
      await tester.pumpAndSettle();
      expect(find.text('pH del agua tratada'), findsOneWidget);
    });
  });
}
