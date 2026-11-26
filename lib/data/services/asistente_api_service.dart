import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Sesión iniciada en la API del Asistente PTAP (servidor_ia).
/// El token es una credencial: vive solo en memoria y se pierde al cerrar la app.
class SesionAsistente {
  final String token;
  final String nombre;
  final String rol;

  const SesionAsistente({required this.token, required this.nombre, required this.rol});
}

/// Token para conectar un asistente de IA (por ejemplo Claude Code) al servidor MCP de la planta.
/// Es una credencial: vive solo en memoria y no se guarda en el celular.
class TokenMcp {
  final String token;
  final String vigencia;
  final String rol;

  const TokenMcp({required this.token, required this.vigencia, required this.rol});
}

/// Respuesta del chat del servidor: se recibe por partes mientras el modelo escribe.
class RespuestaServidor {
  /// 'nube' (Groq) o 'local' (Ollama en el servidor).
  final String proveedor;
  final String modelo;
  final Stream<String> partes;

  const RespuestaServidor({required this.proveedor, required this.modelo, required this.partes});
}

class AsistenteApiException implements Exception {
  final String mensaje;
  final int? estado;
  const AsistenteApiException(this.mensaje, {this.estado});

  @override
  String toString() => mensaje;
}

/// Cliente de la API del Asistente PTAP (NestJS + PostgreSQL, ver servidor_ia/).
class AsistenteApiService {
  final String urlBase;

  AsistenteApiService(String url) : urlBase = url.trim().replaceAll(RegExp(r'/+$'), '');

  HttpClient _cliente(Duration conexion) => HttpClient()..connectionTimeout = conexion;

  Uri _uri(String ruta) => Uri.parse('$urlBase$ruta');

  /// true si el servidor responde en pocos segundos (se usa en el modo automático).
  Future<bool> disponible() async {
    final cliente = _cliente(const Duration(seconds: 3));
    try {
      final peticion = await cliente.getUrl(_uri('/api/salud')).timeout(const Duration(seconds: 3));
      final respuesta = await peticion.close().timeout(const Duration(seconds: 4));
      await respuesta.drain<void>();
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      cliente.close(force: true);
    }
  }

  Future<SesionAsistente> entrar(String correo, String clave) async {
    final datos = await _json('POST', '/api/auth/entrar', cuerpo: {'correo': correo.trim(), 'clave': clave});
    final usuario = datos['usuario'] as Map<String, dynamic>;
    return SesionAsistente(
      token: datos['token'] as String,
      nombre: usuario['nombre'] as String,
      rol: usuario['rol'] as String,
    );
  }

  /// Pide un token MCP (7 días) con la sesión iniciada. Las herramientas dependen del rol.
  Future<TokenMcp> tokenMcp(String token) async {
    final datos = await _json('POST', '/api/auth/token-mcp', token: token);
    return TokenMcp(
      token: datos['token'] as String,
      vigencia: datos['vigencia'] as String? ?? '7 días',
      rol: datos['rol'] as String? ?? '',
    );
  }

  /// modo: 'auto' (nube y, si falla, el modelo local del servidor), 'nube' o 'local'.
  Future<RespuestaServidor> conversar(String token, String mensaje, {String modo = 'auto', String sesion = 'app'}) async {
    final cliente = _cliente(const Duration(seconds: 5));
    try {
      final peticion = await cliente.postUrl(_uri('/api/chat'));
      peticion.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
      peticion.add(utf8.encode(jsonEncode({'mensaje': mensaje, 'modo': modo, 'sesion': sesion})));
      // La primera respuesta puede tardar mientras el servidor carga el modelo local.
      final respuesta = await peticion.close().timeout(const Duration(seconds: 150));
      if (respuesta.statusCode != 200) {
        final texto = await respuesta.transform(utf8.decoder).join();
        cliente.close(force: true);
        throw AsistenteApiException(_mensajeDeError(texto, respuesta.statusCode), estado: respuesta.statusCode);
      }
      final partes = respuesta.transform(utf8.decoder).transform(
            StreamTransformer<String, String>.fromHandlers(handleDone: (sink) {
              cliente.close();
              sink.close();
            }),
          );
      return RespuestaServidor(
        proveedor: respuesta.headers.value('x-proveedor') ?? 'servidor',
        modelo: respuesta.headers.value('x-modelo') ?? '',
        partes: partes,
      );
    } on AsistenteApiException {
      rethrow;
    } on TimeoutException {
      cliente.close(force: true);
      throw const AsistenteApiException('El servidor tardó demasiado en responder.');
    } on SocketException {
      cliente.close(force: true);
      throw const AsistenteApiException('No se pudo conectar con el servidor del asistente.');
    }
  }

  Future<Map<String, dynamic>> _json(String metodo, String ruta, {Map<String, dynamic>? cuerpo, String? token}) async {
    final cliente = _cliente(const Duration(seconds: 5));
    try {
      final peticion = await cliente.openUrl(metodo, _uri(ruta));
      peticion.headers.contentType = ContentType.json;
      if (token != null) peticion.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      if (cuerpo != null) peticion.add(utf8.encode(jsonEncode(cuerpo)));
      final respuesta = await peticion.close().timeout(const Duration(seconds: 15));
      final texto = await respuesta.transform(utf8.decoder).join();
      if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
        throw AsistenteApiException(_mensajeDeError(texto, respuesta.statusCode), estado: respuesta.statusCode);
      }
      return jsonDecode(texto) as Map<String, dynamic>;
    } on SocketException {
      throw const AsistenteApiException('No se pudo conectar con el servidor. Revise la dirección y la red Wi-Fi.');
    } on TimeoutException {
      throw const AsistenteApiException('El servidor no respondió a tiempo.');
    } finally {
      cliente.close();
    }
  }

  static String _mensajeDeError(String texto, int estado) {
    try {
      final datos = jsonDecode(texto);
      final mensaje = datos is Map ? (datos['message'] ?? datos['error']) : null;
      if (mensaje is List) return mensaje.join('. ');
      if (mensaje != null) return mensaje.toString();
    } catch (_) {}
    return 'Error del servidor (HTTP $estado).';
  }
}
