import 'package:flutter/foundation.dart';
import '../../../data/models/medidores_modelos.dart';
import '../../../data/repositories/medidores_repository.dart';

/// Proveedor de estado para el módulo de Medidores y Balance Hídrico
class MedidoresProvider extends ChangeNotifier {
  final MedidoresRepository _repositorio;

  List<JornadaMedidores> _jornadas = [];
  bool _cargando = false;
  String? _mensajeError;

  List<JornadaMedidores> get jornadas => _jornadas;
  bool get cargando => _cargando;
  String? get mensajeError => _mensajeError;

  MedidoresProvider({MedidoresRepository? repositorio})
      : _repositorio = repositorio ?? MedidoresRepository() {
    cargarJornadas();
  }

  List<Medidor> get catalogoMedidores => _repositorio.obtenerMedidores();

  /// Obtiene el mapa de lecturas anteriores para precargar el formulario
  Map<int, double> get ultimasLecturas => _repositorio.obtenerUltimasLecturas();

  /// Carga todas las jornadas de lecturas
  Future<void> cargarJornadas() async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      _jornadas = await _repositorio.obtenerJornadas();
    } catch (e) {
      _mensajeError = 'Error al cargar jornadas de medidores: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Guarda una nueva jornada de medidores
  Future<bool> guardarJornada(JornadaMedidores jornada) async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final exito = await _repositorio.guardarJornada(jornada);
      if (exito) {
        await cargarJornadas();
        return true;
      } else {
        _mensajeError = 'No se pudo guardar la jornada de medidores.';
        return false;
      }
    } catch (e) {
      _mensajeError = 'Error inesperado: $e';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
