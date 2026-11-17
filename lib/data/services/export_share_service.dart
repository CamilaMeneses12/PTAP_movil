import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Servicio para compartir e imprimir archivos PDF y Excel en Android
/// compatible con WhatsApp, Correo Electrónico, Google Drive y visor nativo.
class ExportShareService {
  /// Comparte cualquier archivo (PDF o Excel) vía WhatsApp, correo u otra app disponible
  static Future<void> compartirArchivo({
    required Uint8List bytes,
    required String nombreArchivo,
    required String mimeType,
    String? texto,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$nombreArchivo';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    final xfile = XFile(
      filePath,
      mimeType: mimeType,
      name: nombreArchivo,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [xfile],
        text: texto ?? 'Reporte generado desde la App PTAP SENA La Salada',
        title: nombreArchivo,
      ),
    );
  }

  /// Abre el diálogo de impresión o guardado PDF nativo de Android
  static Future<void> imprimirPdf({
    required Uint8List bytes,
    required String nombreDoc,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: nombreDoc,
    );
  }

  /// Abre la hoja nativa de compartir PDF de la biblioteca Printing
  static Future<void> compartirPdfNativo({
    required Uint8List bytes,
    required String nombreDoc,
  }) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: nombreDoc.endsWith('.pdf') ? nombreDoc : '$nombreDoc.pdf',
    );
  }

  /// Guarda el archivo en el almacenamiento del dispositivo y retorna la ruta
  static Future<String> guardarArchivoLocal({
    required Uint8List bytes,
    required String nombreArchivo,
  }) async {
    Directory? dir;
    try {
      dir = await getExternalStorageDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }
    dir ??= await getApplicationDocumentsDirectory();

    final filePath = '${dir.path}/$nombreArchivo';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }
}
