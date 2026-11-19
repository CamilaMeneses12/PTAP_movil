import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// Rutas de las dos imágenes que se generan a partir de cada foto del medidor.
class FotoProcesada {
  /// Recorte del recuadro guía en escala de grises, usado para el OCR.
  final String rutaRecorte;

  /// Con el recuadro vertical: el mismo recorte girado al otro lado (el medidor puede estar
  /// de lado en cualquiera de los dos sentidos). null con el recuadro horizontal.
  final String? rutaRecorteAlterno;

  /// Foto completa reducida y comprimida (≈ 100–300 KB), guardada como evidencia.
  final String rutaEvidencia;

  const FotoProcesada({required this.rutaRecorte, required this.rutaEvidencia, this.rutaRecorteAlterno});
}

/// Recorta la foto al recuadro guía y lee el texto con ML Kit (en el dispositivo, sin internet).
class OcrMedidorService {
  /// Tamaño y posición del recuadro guía, como fracción de la imagen.
  /// La pantalla de captura dibuja el recuadro con estos mismos valores.
  static const double guiaAncho = 0.86;
  static const double guiaAlto = 0.20;
  static const double guiaCentroY = 0.45;

  /// Recuadro vertical, para medidores instalados de lado.
  static const double guiaVerticalAncho = 0.26;
  static const double guiaVerticalAlto = 0.62;

  static double anchoGuia(bool vertical) => vertical ? guiaVerticalAncho : guiaAncho;
  static double altoGuia(bool vertical) => vertical ? guiaVerticalAlto : guiaAlto;

  final TextRecognizer _reconocedor = TextRecognizer(script: TextRecognitionScript.latin);

  Future<FotoProcesada> prepararFoto(String rutaOriginal, {bool vertical = false}) =>
      compute(_procesarFoto, (rutaOriginal, vertical));

  Future<String> reconocerTexto(String rutaImagen) async {
    final resultado = await _reconocedor.processImage(InputImage.fromFilePath(rutaImagen));
    return resultado.text;
  }

  Future<void> cerrar() => _reconocedor.close();
}

/// Se ejecuta en un isolate aparte para no congelar la interfaz.
FotoProcesada _procesarFoto((String, bool) entrada) {
  final (rutaOriginal, vertical) = entrada;
  final original = img.decodeImage(File(rutaOriginal).readAsBytesSync());
  if (original == null) {
    throw const FormatException('No se pudo leer la foto tomada.');
  }
  // Aplica la rotación EXIF para que la imagen quede como se vio en pantalla.
  final foto = img.bakeOrientation(original);

  final ancho = (foto.width * OcrMedidorService.anchoGuia(vertical)).round();
  final alto = (foto.height * OcrMedidorService.altoGuia(vertical)).round();
  final x = ((foto.width - ancho) / 2).round();
  final y = (foto.height * OcrMedidorService.guiaCentroY - alto / 2).round().clamp(0, foto.height - alto);

  var recorte = img.copyCrop(foto, x: x, y: y, width: ancho, height: alto);
  recorte = img.grayscale(recorte);
  recorte = img.adjustColor(recorte, contrast: 1.35);
  // Con el medidor de lado, los dígitos quedan en columna: se gira para leerlos en fila.
  final alterno = vertical ? img.copyRotate(recorte, angle: -90) : null;
  if (vertical) recorte = img.copyRotate(recorte, angle: 90);

  final evidencia = foto.width > 1024 ? img.copyResize(foto, width: 1024) : foto;

  final base = rutaOriginal.replaceAll(RegExp(r'\.[^./\\]+$'), '');
  final rutaRecorte = '${base}_recorte.jpg';
  final rutaEvidencia = '${base}_evidencia.jpg';
  File(rutaRecorte).writeAsBytesSync(img.encodeJpg(recorte, quality: 92));
  File(rutaEvidencia).writeAsBytesSync(img.encodeJpg(evidencia, quality: 70));
  String? rutaAlterno;
  if (alterno != null) {
    rutaAlterno = '${base}_recorte_alterno.jpg';
    File(rutaAlterno).writeAsBytesSync(img.encodeJpg(alterno, quality: 92));
  }

  return FotoProcesada(rutaRecorte: rutaRecorte, rutaEvidencia: rutaEvidencia, rutaRecorteAlterno: rutaAlterno);
}
