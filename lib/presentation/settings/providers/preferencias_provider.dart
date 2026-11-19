import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias del usuario guardadas en el dispositivo.
class PreferenciasProvider extends ChangeNotifier {
  static const notificacionesPush = 'pref_notificaciones_push';
  static const sonidoAlerta = 'pref_sonido_alerta';
  static const alertasSms = 'pref_alertas_sms';
  static const camaraMedidores = 'pref_camara_medidores';
  static const resumenSemanal = 'pref_resumen_semanal';

  static const Map<String, bool> _porDefecto = {
    notificacionesPush: true,
    sonidoAlerta: true,
    alertasSms: true,
    camaraMedidores: false,
    resumenSemanal: true,
  };

  final Map<String, bool> _valores = Map.of(_porDefecto);
  SharedPreferences? _prefs;

  PreferenciasProvider() {
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      for (final clave in _porDefecto.keys) {
        final guardado = _prefs!.getBool(clave);
        if (guardado != null) _valores[clave] = guardado;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Preferencias no disponibles, usando valores por defecto: $e');
    }
  }

  bool valor(String clave) => _valores[clave] ?? false;

  /// Indica si el operario quiere abrir la cámara al registrar medidores.
  bool get usarCamaraMedidores => valor(camaraMedidores);

  Future<void> cambiar(String clave, bool nuevo) async {
    _valores[clave] = nuevo;
    notifyListeners();
    try {
      await _prefs?.setBool(clave, nuevo);
    } catch (e) {
      debugPrint('No se pudo guardar la preferencia $clave: $e');
    }
  }
}
