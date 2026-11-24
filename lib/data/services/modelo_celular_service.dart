import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

/// Modelo de lenguaje que corre DENTRO del celular, sin internet ni servidor.
///
/// Qwen 2.5 0.5B Instruct (formato .task de MediaPipe), unos 0,5 GB. Se descarga una sola vez
/// (con Wi-Fi) y después responde sin conexión usando el procesador del celular.
/// Su ventana es de 1.280 tokens entre pregunta y respuesta: el prompt debe ser corto.
class ModeloCelularService {
  static const String nombre = 'Qwen 2.5 0.5B';
  static const String url =
      'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/'
      'Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task';
  static const String id = 'Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280';
  static const int maxTokens = 1280;

  static bool _inicializado = false;
  InferenceModel? _modelo;

  Future<void> _inicializar() async {
    if (_inicializado) return;
    await FlutterGemma.initialize(maxDownloadRetries: 5);
    _inicializado = true;
  }

  Future<bool> instalado() async {
    try {
      await _inicializar();
      return await FlutterGemma.isModelInstalled(id);
    } catch (e) {
      debugPrint('No se pudo consultar el modelo del celular: $e');
      return false;
    }
  }

  /// Descarga e instala el modelo (una sola vez). [progreso] recibe 0–100.
  Future<void> instalar({void Function(int porcentaje)? progreso}) async {
    await _inicializar();
    var builder = FlutterGemma.installModel(modelType: ModelType.qwen).fromNetwork(url);
    if (progreso != null) builder = builder.withProgress(progreso);
    await builder.install();
  }

  Future<void> desinstalar() async {
    await cerrar();
    await _inicializar();
    await FlutterGemma.uninstallModel(id);
  }

  /// Responde con el modelo del celular. [sistema] lleva las reglas y los datos que la persona puede ver.
  Stream<String> responder({required String sistema, required String pregunta}) async* {
    await _inicializar();
    if (!FlutterGemma.hasActiveModel()) {
      // Tras reiniciar la app hay que volver a activarlo; como ya está descargado, no se descarga de nuevo.
      await FlutterGemma.installModel(modelType: ModelType.qwen).fromNetwork(url).install();
    }
    _modelo ??= await FlutterGemma.getActiveModel(maxTokens: maxTokens, preferredBackend: PreferredBackend.cpu);
    final chat = await _modelo!.createChat(
      temperature: 0.3,
      topK: 40,
      modelType: ModelType.qwen,
      systemInstruction: sistema,
    );
    try {
      await chat.addQueryChunk(Message.text(text: pregunta, isUser: true));
      await for (final respuesta in chat.generateChatResponseAsync()) {
        if (respuesta is TextResponse) yield respuesta.token;
      }
    } finally {
      await chat.close();
    }
  }

  Future<void> cerrar() async {
    await _modelo?.close();
    _modelo = null;
  }
}
