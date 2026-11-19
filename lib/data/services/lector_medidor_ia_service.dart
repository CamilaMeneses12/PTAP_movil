import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../domain/ocr/interprete_lectura_medidor.dart';

/// Lector de micromedidores con el modelo propio entrenado en `entrenamiento/` (TensorFlow Lite).
///
/// Funciona en el celular sin internet. Si el archivo del modelo no está en
/// `assets/modelos/lector_medidor.tflite`, el servicio queda desactivado y la app usa solo ML Kit.
///
/// El preprocesado debe ser idéntico al de `entrenamiento/comun.py`:
/// gris -> 192 x 48 (bilineal) -> valores 0..1.
class LectorMedidorIaService {
  static const String rutaModelo = 'assets/modelos/lector_medidor.tflite';
  static const int alto = 48;
  static const int ancho = 192;
  static const int digitos = 8;

  Interpreter? _interprete;
  bool _intentado = false;

  bool get disponible => _interprete != null;

  Future<void> _cargar() async {
    if (_intentado) return;
    _intentado = true;
    try {
      await rootBundle.load(rutaModelo); // falla rápido si el modelo aún no se ha entrenado
      _interprete = await Interpreter.fromAsset(rutaModelo);
    } catch (e) {
      debugPrint('Modelo propio no disponible, se usará solo ML Kit: $e');
    }
  }

  /// Lee el recorte del contador. Devuelve null si el modelo no está disponible.
  Future<ResultadoLecturaOcr?> leer(
    String rutaRecorte, {
    required int digitosEnteros,
    required int digitosDecimales,
  }) async {
    if (digitosEnteros + digitosDecimales != digitos) return null; // el modelo lee 8 rodillos
    await _cargar();
    final interprete = _interprete;
    if (interprete == null) return null;

    final entrada = await compute(_prepararEntrada, rutaRecorte);
    if (entrada == null) return null;
    final salida = List.generate(1, (_) => List.generate(digitos, (_) => List.filled(10, 0.0)));
    interprete.run(entrada, salida);
    return interpretarSalida(salida[0], digitosEnteros: digitosEnteros);
  }

  /// Convierte la salida [8][10] del modelo en una lectura. Público para probarlo sin el modelo.
  static ResultadoLecturaOcr interpretarSalida(List<List<double>> probabilidades, {required int digitosEnteros}) {
    final buffer = StringBuffer();
    var confianzaMinima = 1.0;
    for (final rodillo in probabilidades) {
      var mejor = 0;
      for (var d = 1; d < rodillo.length; d++) {
        if (rodillo[d] > rodillo[mejor]) mejor = d;
      }
      buffer.write(mejor);
      if (rodillo[mejor] < confianzaMinima) confianzaMinima = rodillo[mejor];
    }
    final texto = buffer.toString();
    final valor = double.parse('${texto.substring(0, digitosEnteros)}.${texto.substring(digitosEnteros)}');
    final confianza = confianzaMinima >= 0.9
        ? ConfianzaOcr.alta
        : (confianzaMinima >= 0.6 ? ConfianzaOcr.media : ConfianzaOcr.baja);
    return ResultadoLecturaOcr(valor: valor, digitos: texto, confianza: confianza);
  }

  void cerrar() => _interprete?.close();
}

/// Se ejecuta en otro isolate: abre el recorte y lo deja como entrada [1][48][192][1].
List<List<List<List<double>>>>? _prepararEntrada(String ruta) {
  final imagen = img.decodeImage(File(ruta).readAsBytesSync());
  if (imagen == null) return null;
  final gris = img.grayscale(img.copyResize(
    imagen,
    width: LectorMedidorIaService.ancho,
    height: LectorMedidorIaService.alto,
    interpolation: img.Interpolation.linear,
  ));
  return [
    List.generate(
      LectorMedidorIaService.alto,
      (y) => List.generate(
        LectorMedidorIaService.ancho,
        (x) => [gris.getPixel(x, y).r / 255.0],
      ),
    ),
  ];
}
