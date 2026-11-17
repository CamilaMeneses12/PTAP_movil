import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:planta_agua/presentation/auth/providers/auth_provider.dart';
import 'package:planta_agua/presentation/auth/screens/login_screen.dart';

void main() {
  group('Pruebas de diseño responsivo de LoginScreen según referencia.png', () {
    final tamanos = [
      {'nombre': 'Celular Grande (FHD+)', 'size': const Size(1080, 2400), 'ratio': 2.75},
      {'nombre': 'Celular Estándar (HD+)', 'size': const Size(720, 1600), 'ratio': 2.0},
      {'nombre': 'Celular Pequeño', 'size': const Size(480, 800), 'ratio': 1.5},
      {'nombre': 'Tablet', 'size': const Size(1200, 1920), 'ratio': 2.0},
    ];

    for (final t in tamanos) {
      testWidgets('Renderiza sin overflow en ${t['nombre']}', (tester) async {
        tester.view.physicalSize = t['size'] as Size;
        tester.view.devicePixelRatio = t['ratio'] as double;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ChangeNotifierProvider<SesionUsuarioProvider>(
            create: (_) => SesionUsuarioProvider(),
            child: const MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('PLANTA DE TRATAMIENTO\nDE AGUA POTABLE'), findsOneWidget);
        expect(find.text('Iniciar Sesión'), findsWidgets);
        expect(find.text('Crear nueva cuenta'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
