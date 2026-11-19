import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/supabase_config.dart';

/// Guarda y consulta las fotos de evidencia de las lecturas en Supabase Storage.
class FotoLecturaService {
  static const String bucket = 'lecturas-medidores';

  /// Ruta dentro del bucket: fecha/jornada/codigo-medidor.jpg
  static String rutaRemota({required DateTime fecha, required String jornadaId, required String codigoMedidor}) {
    final dia = fecha.toIso8601String().split('T').first;
    return '$dia/$jornadaId/$codigoMedidor.jpg';
  }

  /// Sube la foto y devuelve su ruta en el bucket, o null si no hay conexión o falla.
  /// Un fallo aquí nunca impide guardar la lectura.
  Future<String?> subir(String rutaLocal, String rutaRemota) async {
    if (!SupabaseConfig.estaInicializado) return null;
    try {
      await SupabaseConfig.cliente.storage.from(bucket).uploadBinary(
            rutaRemota,
            await File(rutaLocal).readAsBytes(),
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      return rutaRemota;
    } catch (e) {
      debugPrint('No se pudo subir la foto de la lectura ($rutaRemota): $e');
      return null;
    }
  }

  /// URL temporal (1 hora) para mostrar una foto del bucket privado.
  Future<String?> urlTemporal(String rutaRemota) async {
    if (!SupabaseConfig.estaInicializado) return null;
    try {
      return await SupabaseConfig.cliente.storage.from(bucket).createSignedUrl(rutaRemota, 3600);
    } catch (e) {
      debugPrint('No se pudo obtener la foto $rutaRemota: $e');
      return null;
    }
  }
}
