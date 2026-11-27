import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/presentation/intro/screens/intro_video_screen.dart';

void main() {
  testWidgets('"Omitir" termina el video de inicio una sola vez', (tester) async {
    var veces = 0;
    await tester.pumpWidget(MaterialApp(home: IntroVideoScreen(alTerminar: () => veces++)));
    await tester.pump();

    // En las pruebas no hay reproductor de video: la pantalla no debe quedarse bloqueada.
    if (veces == 0) {
      await tester.tap(find.byKey(const Key('omitir_intro')));
      await tester.pump();
    }
    expect(veces, 1);

    // Ni el límite de tiempo ni otro toque la vuelven a cerrar.
    await tester.pump(const Duration(seconds: 20));
    expect(veces, 1);
  });

  testWidgets('Si el video no carga, pasa al login al cumplirse el límite', (tester) async {
    var veces = 0;
    await tester.pumpWidget(MaterialApp(
      home: IntroVideoScreen(alTerminar: () => veces++, limite: const Duration(seconds: 2)),
    ));
    await tester.pump(const Duration(seconds: 3));
    expect(veces, 1);
  });
}
