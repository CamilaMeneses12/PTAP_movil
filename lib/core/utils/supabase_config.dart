import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración y cliente centralizado de Supabase
class SupabaseConfig {
  static bool _inicializado = false;
  static bool get estaInicializado => _inicializado;

  /// Obtiene la instancia del cliente Supabase
  static SupabaseClient get cliente {
    if (!_inicializado) {
      throw StateError('Supabase aún no ha sido inicializado.');
    }
    return Supabase.instance.client;
  }

  /// Carga las variables de entorno y conecta con Supabase si los valores son válidos
  static Future<void> inicializar() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('No se pudo cargar el archivo .env, usando valores por defecto: $e');
    }

    final url = dotenv.maybeGet('SUPABASE_URL') ?? '';
    final anonKey = dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

    // Validar si tiene una URL y llave real
    final tieneValoresReales = url.isNotEmpty &&
        anonKey.isNotEmpty &&
        !url.contains('tu-proyecto') &&
        !anonKey.contains('tu-anon-key');

    if (tieneValoresReales) {
      try {
        await Supabase.initialize(
          url: url,
          publishableKey: anonKey,
        );
        _inicializado = true;
        debugPrint('Supabase inicializado correctamente.');
      } catch (e) {
        debugPrint('Error al conectar con Supabase: $e');
      }
    } else {
      debugPrint('Aviso: Variables de Supabase no configuradas en .env. Configure SUPABASE_URL y SUPABASE_ANON_KEY.');
    }
  }
}
