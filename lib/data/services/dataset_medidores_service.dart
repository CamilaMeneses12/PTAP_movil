import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Guarda en el celular cada recorte confirmado por el operario junto con su lectura correcta.
/// Esos pares (foto, número) son los datos para volver a entrenar el modelo en `entrenamiento/`.
///
/// Carpeta (accesible por USB con adb, sin permisos especiales):
///   /sdcard/Android/data/com.example.planta_agua/files/dataset_medidores/
/// Nombre de cada archivo: `<dígitos de la lectura>__<medidor>_<fecha>.jpg` (ej. 08136267__MIC-01_20261119_1012.jpg)
class DatasetMedidoresService {
  static const String carpeta = 'dataset_medidores';

  static String digitosDeLectura(double valor, {required int digitosEnteros, required int digitosDecimales}) {
    final texto = valor.toStringAsFixed(digitosDecimales).replaceAll('.', '');
    return texto.padLeft(digitosEnteros + digitosDecimales, '0');
  }

  Future<void> guardar({
    required String rutaRecorte,
    required double valor,
    required String codigoMedidor,
    required int digitosEnteros,
    required int digitosDecimales,
  }) async {
    try {
      final base = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final destino = Directory('${base.path}/$carpeta');
      await destino.create(recursive: true);
      final digitos = digitosDeLectura(valor, digitosEnteros: digitosEnteros, digitosDecimales: digitosDecimales);
      final t = DateTime.now();
      String dos(int n) => n.toString().padLeft(2, '0');
      final sello = '${t.year}${dos(t.month)}${dos(t.day)}_${dos(t.hour)}${dos(t.minute)}${dos(t.second)}';
      await File(rutaRecorte).copy('${destino.path}/${digitos}__${codigoMedidor}_$sello.jpg');
    } catch (e) {
      // Guardar el dataset nunca debe impedir registrar la lectura.
      debugPrint('No se pudo guardar el recorte para el dataset: $e');
    }
  }
}
