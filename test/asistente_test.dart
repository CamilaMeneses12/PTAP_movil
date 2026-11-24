import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planta_agua/data/models/item_historial_modelo.dart';
import 'package:planta_agua/data/models/usuario_perfil.dart';
import 'package:planta_agua/data/repositories/umbrales_repository.dart';
import 'package:planta_agua/data/services/modelo_celular_service.dart';
import 'package:planta_agua/domain/asistente/asistente_logica.dart';
import 'package:planta_agua/presentation/asistente/providers/asistente_provider.dart';
import 'package:planta_agua/presentation/asistente/screens/asistente_screen.dart';
import 'package:planta_agua/presentation/auth/providers/auth_provider.dart';
import 'package:planta_agua/presentation/history/providers/historial_provider.dart';
import 'package:planta_agua/presentation/settings/providers/umbrales_provider.dart';

/// Modelo del celular de mentira: no descarga nada y responde un texto fijo.
class ModeloFalso extends ModeloCelularService {
  bool listo;
  String? ultimoSistema;
  ModeloFalso({this.listo = true});

  @override
  Future<bool> instalado() async => listo;

  @override
  Stream<String> responder({required String sistema, required String pregunta}) async* {
    ultimoSistema = sistema;
    yield 'El cloro ';
    yield 'está bajo.';
  }

  @override
  Future<void> cerrar() async {}
}

UsuarioPerfil _perfil(String rol, {String id = 'yo', String nombre = 'Ana Pérez'}) => UsuarioPerfil(
      id: id,
      nombreCompleto: nombre,
      correo: 'ana@ptap.test',
      rol: rol,
      activo: true,
      createdAt: DateTime(2026, 1, 1),
    );

ItemHistorial _item(String responsable, {String? creadoPorId, bool alerta = false, String titulo = 'Calidad del Agua'}) => ItemHistorial(
      id: '$responsable-$titulo',
      tipo: TipoRegistroHistorial.fisicoquimico,
      fecha: DateTime(2026, 11, 20),
      hora: '08:00',
      titulo: titulo,
      subtitulo: 'pH: 7.1 | Cloro: 0.2 mg/L',
      responsable: responsable,
      creadoPorId: creadoPorId,
      tieneAlerta: alerta,
      mensajeAlerta: alerta ? 'Cloro residual bajo' : null,
      objetoOriginal: null,
    );

void main() {
  group('Quién responde en cada modo', () {
    DecisionFuente decidir(ModoAsistente m, {bool servidor = false, bool sesion = false, bool modelo = false}) =>
        AsistenteLogica.decidir(m, servidorDisponible: servidor, sesionIniciada: sesion, modeloInstalado: modelo);

    test('Automático: el servidor si hay conexión y sesión; si no, el celular', () {
      expect(decidir(ModoAsistente.automatico, servidor: true, sesion: true, modelo: true).fuente, FuenteRespuesta.servidor);
      expect(decidir(ModoAsistente.automatico, servidor: false, sesion: true, modelo: true).fuente, FuenteRespuesta.celular);
      expect(decidir(ModoAsistente.automatico, servidor: true, sesion: false, modelo: true).fuente, FuenteRespuesta.celular);
      final nada = decidir(ModoAsistente.automatico);
      expect(nada.fuente, FuenteRespuesta.ninguna);
      expect(nada.motivo, isNotNull);
    });

    test('En línea nunca usa el celular', () {
      expect(decidir(ModoAsistente.enLinea, servidor: true, sesion: true).fuente, FuenteRespuesta.servidor);
      expect(decidir(ModoAsistente.enLinea, servidor: false, sesion: true, modelo: true).fuente, FuenteRespuesta.ninguna);
      expect(decidir(ModoAsistente.enLinea, servidor: true, modelo: true).fuente, FuenteRespuesta.ninguna);
    });

    test('En el celular nunca usa el servidor', () {
      expect(decidir(ModoAsistente.enCelular, servidor: true, sesion: true, modelo: true).fuente, FuenteRespuesta.celular);
      expect(decidir(ModoAsistente.enCelular, servidor: true, sesion: true).fuente, FuenteRespuesta.ninguna);
    });
  });

  group('El prompt del celular solo lleva lo que el rol puede ver', () {
    final items = [
      _item('Otro Operario', creadoPorId: 'otro', titulo: 'Registro ajeno'),
      _item('Ana Pérez', creadoPorId: 'yo', alerta: true, titulo: 'Registro propio'),
    ];

    test('El operario solo ve sus registros', () {
      final visibles = AsistenteLogica.registrosVisibles(items, _perfil('operario'));
      expect(visibles.map((i) => i.titulo), ['Registro propio']);
      final prompt = AsistenteLogica.promptCelular(perfil: _perfil('operario'), items: items, umbrales: UmbralesRepository.predeterminados());
      expect(prompt, contains('Registro propio'));
      expect(prompt, isNot(contains('Registro ajeno')));
      expect(prompt, contains('FUERA DE RANGO: Cloro residual bajo'));
      expect(prompt, contains('Cloro residual libre: 0,3–2 mg/L'));
    });

    test('El consultor SIGA y el administrador ven todos', () {
      expect(AsistenteLogica.registrosVisibles(items, _perfil('consultor_siga')).length, 2);
      expect(AsistenteLogica.registrosVisibles(items, _perfil('administrador')).length, 2);
    });

    test('Sin registros visibles lo dice en vez de dejar el modelo adivinar', () {
      final prompt = AsistenteLogica.promptCelular(perfil: _perfil('operario', id: 'nadie', nombre: 'Nadie'), items: items, umbrales: const []);
      expect(prompt, contains('- Ninguno.'));
    });
  });

  group('Proveedor del asistente', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('Sin servidor, el modo automático responde con el modelo del celular', () async {
      final modelo = ModeloFalso();
      final prov = AsistenteProvider(modelo: modelo);
      await prov.cargar();
      await prov.enviar('¿Cómo va el cloro?', perfil: _perfil('operario'), registros: [_item('Ana Pérez', creadoPorId: 'yo')], umbrales: const []);

      final respuesta = prov.mensajes.last;
      expect(respuesta.texto, 'El cloro está bajo.');
      expect(respuesta.fuente, 'En el celular · ${ModeloCelularService.nombre}');
      expect(respuesta.error, isFalse);
      expect(modelo.ultimoSistema, contains('Ana Pérez'));
    });

    test('Sin servidor ni modelo explica qué hacer', () async {
      final prov = AsistenteProvider(modelo: ModeloFalso(listo: false));
      await prov.cargar();
      await prov.enviar('Hola', perfil: _perfil('operario'), registros: const [], umbrales: const []);
      expect(prov.mensajes.last.error, isTrue);
      expect(prov.mensajes.last.texto, contains('descargue el modelo'));
    });
  });

  testWidgets('La pantalla del asistente muestra el selector de modo y responde', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final sesion = SesionUsuarioProvider()..establecerPerfilPrueba(_perfil('operario'));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: sesion),
          ChangeNotifierProvider(create: (_) => HistorialProvider()),
          ChangeNotifierProvider(create: (_) => UmbralesProvider()),
          ChangeNotifierProvider(create: (_) => AsistenteProvider(modelo: ModeloFalso())),
        ],
        child: const MaterialApp(home: AsistenteScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Automático'), findsOneWidget);
    expect(find.text('En línea'), findsOneWidget);
    expect(find.text('Celular'), findsOneWidget);
    expect(find.text('Modelo del celular listo'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('campo_pregunta')), '¿Cómo va el cloro?');
    await tester.tap(find.byKey(const Key('enviar_pregunta')));
    await tester.pumpAndSettle();

    expect(find.text('El cloro está bajo.'), findsOneWidget);
    expect(find.textContaining('En el celular'), findsOneWidget);
  });
}
