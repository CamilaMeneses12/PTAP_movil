import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/aforo_caudal_modelo.dart';
import '../../../data/repositories/caudal_repository.dart';

/// Proveedor de estado para el monitoreo y cálculo de Caudal en la Quebrada La Seca
class CaudalProvider extends ChangeNotifier {
  final CaudalRepository _repositorio;

  List<AforoCaudal> _aforos = [];
  bool _cargando = false;
  String? _mensajeError;

  List<AforoCaudal> get aforos => _aforos;
  bool get cargando => _cargando;
  String? get mensajeError => _mensajeError;

  CaudalProvider({CaudalRepository? repositorio})
      : _repositorio = repositorio ?? CaudalRepository() {
    cargarAforos();
  }

  /// Caudal más reciente registrado
  AforoCaudal? get ultimoAforo => _aforos.isNotEmpty ? _aforos.last : null;

  /// Caudal promedio histórico en L/s (fórmula Excel AVERAGE: ~19.36 L/s)
  double get caudalPromedioLS {
    if (_aforos.isEmpty) return 0.0;
    final suma = _aforos.fold<double>(0.0, (acc, a) => acc + a.caudalLS);
    return suma / _aforos.length;
  }

  /// Caudal máximo histórico
  double get caudalMaximoLS {
    if (_aforos.isEmpty) return 0.0;
    return _aforos.map((a) => a.caudalLS).reduce((a, b) => a > b ? a : b);
  }

  /// Caudal mínimo histórico
  double get caudalMinimoLS {
    if (_aforos.isEmpty) return 0.0;
    return _aforos.map((a) => a.caudalLS).reduce((a, b) => a < b ? a : b);
  }

  /// Puntos formateados para el gráfico de líneas de fl_chart
  List<FlSpot> get spotsGrafica {
    final spots = <FlSpot>[];
    for (int i = 0; i < _aforos.length; i++) {
      spots.add(FlSpot(i.toDouble(), _aforos[i].caudalLS));
    }
    return spots;
  }

  /// Carga todos los aforos
  Future<void> cargarAforos() async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      _aforos = await _repositorio.obtenerAforos();
    } catch (e) {
      _mensajeError = 'Error al cargar aforos: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Guarda un nuevo aforo
  Future<bool> guardarAforo(AforoCaudal aforo) async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final exito = await _repositorio.guardarAforo(aforo);
      if (exito) {
        await cargarAforos();
        return true;
      }
      return false;
    } catch (e) {
      _mensajeError = 'Error al registrar aforo: $e';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
