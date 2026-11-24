import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/item_historial_modelo.dart';
import '../../../data/models/umbral_alerta_modelo.dart';
import '../../../data/models/usuario_perfil.dart';
import '../../../data/services/asistente_api_service.dart';
import '../../../data/services/modelo_celular_service.dart';
import '../../../domain/asistente/asistente_logica.dart';

class MensajeAsistente {
  final bool esUsuario;
  String texto;

  /// Qué modelo respondió: "Nube · openai/gpt-oss-20b", "En el celular · Qwen 2.5 0.5B"…
  String? fuente;
  bool escribiendo;
  bool error;

  MensajeAsistente({required this.esUsuario, this.texto = '', this.fuente, this.escribiendo = false, this.error = false});
}

/// Estado del chat del Asistente PTAP: modo elegido, sesión en el servidor y modelo del celular.
class AsistenteProvider extends ChangeNotifier {
  static const _claveUrl = 'asistente_url_servidor';
  static const _claveModo = 'asistente_modo';

  final AsistenteApiService Function(String url) _crearApi;
  final ModeloCelularService _modelo;

  AsistenteProvider({AsistenteApiService Function(String url)? crearApi, ModeloCelularService? modelo})
      : _crearApi = crearApi ?? AsistenteApiService.new,
        _modelo = modelo ?? ModeloCelularService();

  String urlServidor = '';
  ModoAsistente modo = ModoAsistente.automatico;
  SesionAsistente? sesion;
  bool? servidorDisponible;
  bool modeloInstalado = false;
  bool descargando = false;
  int progresoDescarga = 0;
  bool enviando = false;
  bool _cargado = false;
  final List<MensajeAsistente> mensajes = [];

  AsistenteApiService get _api => _crearApi(urlServidor);

  Future<void> cargar() async {
    if (_cargado) return;
    _cargado = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      urlServidor = prefs.getString(_claveUrl) ?? '';
      modo = ModoAsistente.values.firstWhere((m) => m.name == prefs.getString(_claveModo), orElse: () => ModoAsistente.automatico);
    } catch (_) {}
    notifyListeners();
    modeloInstalado = await _modelo.instalado();
    notifyListeners();
    await comprobarServidor();
  }

  Future<void> cambiarModo(ModoAsistente nuevo) async {
    modo = nuevo;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setString(_claveModo, nuevo.name);
    } catch (_) {}
  }

  Future<void> cambiarUrl(String url) async {
    urlServidor = url.trim();
    sesion = null;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setString(_claveUrl, urlServidor);
    } catch (_) {}
    await comprobarServidor();
  }

  Future<void> comprobarServidor() async {
    if (urlServidor.isEmpty) {
      servidorDisponible = false;
    } else {
      servidorDisponible = await _api.disponible();
    }
    notifyListeners();
  }

  /// Devuelve null si entró, o el mensaje de error.
  Future<String?> entrar(String correo, String clave) async {
    try {
      sesion = await _api.entrar(correo, clave);
      servidorDisponible = true;
      notifyListeners();
      return null;
    } on AsistenteApiException catch (e) {
      return e.mensaje;
    } catch (e) {
      return 'No se pudo iniciar sesión: $e';
    }
  }

  void salir() {
    sesion = null;
    notifyListeners();
  }

  Future<String?> descargarModelo() async {
    if (descargando) return null;
    descargando = true;
    progresoDescarga = 0;
    notifyListeners();
    try {
      await _modelo.instalar(progreso: (p) {
        progresoDescarga = p;
        notifyListeners();
      });
      modeloInstalado = true;
      return null;
    } catch (e) {
      return 'No se pudo descargar el modelo: $e';
    } finally {
      descargando = false;
      notifyListeners();
    }
  }

  Future<void> eliminarModelo() async {
    await _modelo.desinstalar();
    modeloInstalado = false;
    notifyListeners();
  }

  void limpiarConversacion() {
    mensajes.clear();
    notifyListeners();
  }

  Future<void> enviar(
    String texto, {
    required UsuarioPerfil? perfil,
    required List<ItemHistorial> registros,
    required List<UmbralAlerta> umbrales,
  }) async {
    final pregunta = texto.trim();
    if (pregunta.isEmpty || enviando) return;
    enviando = true;
    mensajes.add(MensajeAsistente(esUsuario: true, texto: pregunta));
    final respuesta = MensajeAsistente(esUsuario: false, escribiendo: true);
    mensajes.add(respuesta);
    notifyListeners();

    try {
      // En modo "En el celular" no se pierde tiempo buscando el servidor.
      if (modo != ModoAsistente.enCelular && sesion != null) await comprobarServidor();
      final decision = AsistenteLogica.decidir(
        modo,
        servidorDisponible: servidorDisponible == true,
        sesionIniciada: sesion != null,
        modeloInstalado: modeloInstalado,
      );

      switch (decision.fuente) {
        case FuenteRespuesta.servidor:
          final r = await _api.conversar(sesion!.token, pregunta);
          respuesta.fuente = r.proveedor == 'nube' ? 'Nube · ${r.modelo}' : 'Servidor (modelo local) · ${r.modelo}';
          await _volcar(r.partes, respuesta);
        case FuenteRespuesta.celular:
          if (perfil == null) throw StateError('Inicie sesión en la app para usar el asistente.');
          respuesta.fuente = 'En el celular · ${ModeloCelularService.nombre}';
          final sistema = AsistenteLogica.promptCelular(perfil: perfil, items: registros, umbrales: umbrales);
          await _volcar(_modelo.responder(sistema: sistema, pregunta: pregunta), respuesta);
        case FuenteRespuesta.ninguna:
          respuesta
            ..texto = decision.motivo ?? 'No hay un modelo disponible.'
            ..error = true;
      }
      if (respuesta.texto.trim().isEmpty && !respuesta.error) {
        respuesta.texto = 'El modelo no devolvió respuesta. Intente de nuevo.';
      }
    } on AsistenteApiException catch (e) {
      if (e.estado == 401) sesion = null; // token vencido: hay que entrar de nuevo
      respuesta
        ..texto = e.mensaje
        ..error = true;
    } catch (e) {
      respuesta
        ..texto = 'No se pudo responder: $e'
        ..error = true;
    } finally {
      respuesta.escribiendo = false;
      enviando = false;
      notifyListeners();
    }
  }

  Future<void> _volcar(Stream<String> partes, MensajeAsistente destino) async {
    var ultimo = DateTime.now();
    await for (final parte in partes) {
      destino.texto += parte;
      // Refresca la pantalla como máximo cada 60 ms mientras el modelo escribe.
      if (DateTime.now().difference(ultimo).inMilliseconds > 60) {
        ultimo = DateTime.now();
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _modelo.cerrar();
    super.dispose();
  }
}
