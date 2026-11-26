import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planta_agua/data/services/asistente_api_service.dart';
import 'package:planta_agua/data/services/modelo_celular_service.dart';
import 'package:planta_agua/presentation/asistente/providers/asistente_provider.dart';
import 'package:planta_agua/presentation/asistente/screens/conexion_mcp_screen.dart';

/// Servidor falso: responde como la API del Asistente PTAP sin red.
class ApiFalsa extends AsistenteApiService {
  ApiFalsa(super.url);

  String? tokenRecibido;

  @override
  Future<bool> disponible() async => true;

  @override
  Future<SesionAsistente> entrar(String correo, String clave) async {
    if (clave != 'AguaClara2026') throw const AsistenteApiException('Correo o clave incorrectos', estado: 401);
    return const SesionAsistente(token: 'token-web', nombre: 'Karol', rol: 'operario');
  }

  @override
  Future<TokenMcp> tokenMcp(String token) async {
    tokenRecibido = token;
    return const TokenMcp(token: 'eyJmcp-1234567890-abcdef', vigencia: '7 días', rol: 'operario');
  }
}

class ModeloSinInstalar extends ModeloCelularService {
  @override
  Future<bool> instalado() async => false;
}

void main() {
  testWidgets('Servidor MCP: entrar, ver la dirección, generar el token y las herramientas del rol', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    late ApiFalsa api;
    final asistente = AsistenteProvider(
      crearApi: (url) => api = ApiFalsa(url),
      modelo: ModeloSinInstalar(),
    );

    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copiado = (call.arguments as Map)['text'] as String?;
      return null;
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: asistente,
        child: const MaterialApp(home: ConexionMcpScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Sin sesión no se puede generar el token.
    expect(find.text('Inicie sesión para generar el token'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('mcp_url')), 'http://192.168.1.20:3100/');
    await tester.enterText(find.byKey(const Key('mcp_correo')), 'karol@ptap.test');
    await tester.enterText(find.byKey(const Key('mcp_clave')), 'mala');
    await tester.tap(find.byKey(const Key('mcp_entrar')));
    await tester.pumpAndSettle();
    expect(find.text('Correo o clave incorrectos'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('mcp_clave')), 'AguaClara2026');
    await tester.tap(find.byKey(const Key('mcp_entrar')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Karol (operario)', findRichText: true), findsOneWidget);
    expect(find.text('http://192.168.1.20:3100/mcp'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mcp_generar_token')));
    await tester.pumpAndSettle();
    expect(api.tokenRecibido, 'token-web');
    expect(find.text('Token (vence en 7 días)'), findsOneWidget);
    // El token se muestra recortado en pantalla, pero se copia completo.
    expect(find.text('eyJmcp-1234567890-abcdef'), findsNothing);
    await tester.tap(find.descendant(of: find.byKey(const Key('mcp_token')), matching: find.byIcon(Icons.copy_rounded)));
    await tester.pump();
    expect(copiado, 'eyJmcp-1234567890-abcdef');

    // Un operario no ve la herramienta exclusiva del administrador.
    expect(find.textContaining('registrar_medicion', findRichText: true), findsOneWidget);
    expect(find.textContaining('cambiar_estado_registro', findRichText: true), findsNothing);

    // Cerrar la sesión borra el token de la memoria.
    await tester.tap(find.text('Cambiar de servidor o de usuario'));
    await tester.pumpAndSettle();
    expect(asistente.tokenMcp, isNull);
  });
}
