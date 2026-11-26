import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/supabase_config.dart';
import '../local/almacen_local.dart';

/// Guarda y consulta las fotos de evidencia de las lecturas en Supabase Storage.
class FotoLecturaService {
  static const String bucket = 'lecturas-medidores';

  /// Ruta dentro del bucket: fecha/jornada/codigo-medidor.jpg
  static String rutaRemota({required DateTime fecha, required String jornadaId, required String codigoMedidor}) {
    final dia = fecha.toIso8601String().split('T').first;
    return '$dia/$jornadaId/$codigoMedidor.jpg';
  }

  /// Las fotos que aún no se suben se guardan en la lectura como `local:` + la ruta en el celular.
  static const String prefijoLocal = 'local:';

  /// Ruta en el celular de una foto pendiente de subir; null si la foto ya está en el bucket.
  static String? rutaLocalDe(String? fotoUrl) =>
      (fotoUrl != null && fotoUrl.startsWith(prefijoLocal)) ? fotoUrl.substring(prefijoLocal.length) : null;

  /// Copia la foto tomada a la carpeta privada de la app (la de la cámara puede borrarse)
  /// y devuelve la referencia 'local:...' que se guarda en la lectura hasta subirla.
  static Future<String> guardarCopiaLocal(String rutaTemporal, String nombre) async {
    try {
      final carpeta = await AlmacenLocal.instancia.carpetaFotos();
      if (carpeta != null) {
        final destino = '${carpeta.path}${Platform.pathSeparator}$nombre.jpg';
        await File(rutaTemporal).copy(destino);
        return '$prefijoLocal$destino';
      }
    } catch (e) {
      debugPrint('No se pudo copiar la foto al almacén local: $e');
    }
    return '$prefijoLocal$rutaTemporal';
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
