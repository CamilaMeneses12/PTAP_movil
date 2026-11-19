import 'package:flutter/foundation.dart';
import '../../../data/models/umbral_alerta_modelo.dart';
import '../../../data/repositories/umbrales_repository.dart';

/// Estado de los umbrales de alerta. Al cargar o editar, actualiza el validador central.
class UmbralesProvider extends ChangeNotifier {
  final UmbralesRepository _repositorio;

  List<UmbralAlerta> _umbrales = UmbralesRepository.predeterminados();
  bool _cargando = false;
  String? _error;

  UmbralesProvider({UmbralesRepository? repositorio})
      : _repositorio = repositorio ?? UmbralesRepository();

  List<UmbralAlerta> get umbrales => _umbrales;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _umbrales = await _repositorio.obtener();
      UmbralesRepository.aplicarAValidador(_umbrales);
    } catch (e) {
      _error = 'No se pudieron cargar los umbrales: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Guarda el nuevo rango. Devuelve null si se guardó, o el mensaje de error.
  Future<String?> actualizar(UmbralAlerta umbral, {double? minimo, double? maximo}) async {
    if (minimo != null && maximo != null && minimo > maximo) {
      return 'El mínimo no puede ser mayor que el máximo.';
    }
    final nuevo = UmbralAlerta(
      seccion: umbral.seccion,
      parametro: umbral.parametro,
      nombre: umbral.nombre,
      unidad: umbral.unidad,
      minimo: minimo,
      maximo: maximo,
    );
    try {
      await _repositorio.actualizar(nuevo);
      _umbrales = [
        for (final u in _umbrales) u.clave == nuevo.clave ? nuevo : u,
      ];
      UmbralesRepository.aplicarAValidador([nuevo]);
      notifyListeners();
      return null;
    } catch (e) {
      return 'No se pudo guardar en el servidor: $e';
    }
  }
}
