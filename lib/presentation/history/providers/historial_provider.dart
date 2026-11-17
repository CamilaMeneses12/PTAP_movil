import 'package:flutter/foundation.dart';
import '../../../data/models/item_historial_modelo.dart';
import '../../../data/repositories/historial_repository.dart';

/// Proveedor de estado para la pantalla de historial y filtros avanzados
class HistorialProvider extends ChangeNotifier {
  final HistorialRepository _repository;

  HistorialProvider({HistorialRepository? repository})
      : _repository = repository ?? HistorialRepository() {
    cargarHistorial();
  }

  // Lista cruda original y lista filtrada
  List<ItemHistorial> _todosLosItems = [];
  List<ItemHistorial> _itemsFiltrados = [];
  List<String> _usuariosDisponibles = [];

  bool _cargando = false;
  String? _error;

  // Filtros aplicables
  TipoRegistroHistorial _tipoSeleccionado = TipoRegistroHistorial.todos;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _usuarioSeleccionado;
  bool _soloAlertas = false;
  String _busquedaTexto = '';

  // Getters
  List<ItemHistorial> get items => _itemsFiltrados;
  List<ItemHistorial> get todosLosItems => _todosLosItems;
  List<String> get usuariosDisponibles => _usuariosDisponibles;
  bool get cargando => _cargando;
  String? get error => _error;

  TipoRegistroHistorial get tipoSeleccionado => _tipoSeleccionado;
  DateTime? get fechaInicio => _fechaInicio;
  DateTime? get fechaFin => _fechaFin;
  String? get usuarioSeleccionado => _usuarioSeleccionado;
  bool get soloAlertas => _soloAlertas;
  String get busquedaTexto => _busquedaTexto;

  int get totalItems => _itemsFiltrados.length;
  int get totalAlertas => _itemsFiltrados.where((i) => i.tieneAlerta).length;

  /// Cuenta cuántos filtros no predeterminados están activos
  int get conteoFiltrosActivos {
    int cuenta = 0;
    if (_tipoSeleccionado != TipoRegistroHistorial.todos) cuenta++;
    if (_fechaInicio != null || _fechaFin != null) cuenta++;
    if (_usuarioSeleccionado != null && _usuarioSeleccionado!.isNotEmpty && _usuarioSeleccionado != 'Todos') cuenta++;
    if (_soloAlertas) cuenta++;
    if (_busquedaTexto.trim().isNotEmpty) cuenta++;
    return cuenta;
  }

  /// Carga o recarga los datos desde los repositorios
  Future<void> cargarHistorial() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _todosLosItems = await _repository.obtenerHistorialCompleto();
      _usuariosDisponibles = await _repository.obtenerResponsablesUnicos();
      _aplicarFiltrosInternos();
    } catch (e) {
      _error = 'Error al cargar el historial: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Cambia el tipo de registro filtrado
  void setTipo(TipoRegistroHistorial tipo) {
    if (_tipoSeleccionado == tipo) return;
    _tipoSeleccionado = tipo;
    _aplicarFiltrosInternos();
    notifyListeners();
  }

  /// Define el rango de fechas
  void setRangoFechas(DateTime? inicio, DateTime? fin) {
    _fechaInicio = inicio != null ? DateTime(inicio.year, inicio.month, inicio.day) : null;
    _fechaFin = fin != null ? DateTime(fin.year, fin.month, fin.day, 23, 59, 59) : null;
    _aplicarFiltrosInternos();
    notifyListeners();
  }

  /// Filtra por responsable / usuario
  void setUsuario(String? usuario) {
    _usuarioSeleccionado = (usuario == null || usuario == 'Todos') ? null : usuario;
    _aplicarFiltrosInternos();
    notifyListeners();
  }

  /// Activa o desactiva mostrar solo registros con alertas
  void setSoloAlertas(bool solo) {
    if (_soloAlertas == solo) return;
    _soloAlertas = solo;
    _aplicarFiltrosInternos();
    notifyListeners();
  }

  /// Filtra por texto en título, responsable o subtítulo
  void setBusqueda(String texto) {
    _busquedaTexto = texto;
    _aplicarFiltrosInternos();
    notifyListeners();
  }

  /// Restaura los filtros a sus valores predeterminados
  void limpiarFiltros() {
    _tipoSeleccionado = TipoRegistroHistorial.todos;
    _fechaInicio = null;
    _fechaFin = null;
    _usuarioSeleccionado = null;
    _soloAlertas = false;
    _busquedaTexto = '';
    _aplicarFiltrosInternos();
    notifyListeners();
  }

  /// Lógica de filtrado combinada
  void _aplicarFiltrosInternos() {
    _itemsFiltrados = _todosLosItems.where((item) {
      // 1. Tipo
      if (_tipoSeleccionado != TipoRegistroHistorial.todos && item.tipo != _tipoSeleccionado) {
        return false;
      }

      // 2. Rango de fechas
      if (_fechaInicio != null) {
        final inicio = DateTime(_fechaInicio!.year, _fechaInicio!.month, _fechaInicio!.day);
        if (item.fecha.isBefore(inicio)) return false;
      }
      if (_fechaFin != null) {
        final fin = DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day, 23, 59, 59);
        if (item.fecha.isAfter(fin)) return false;
      }

      // 3. Usuario / responsable
      if (_usuarioSeleccionado != null && _usuarioSeleccionado!.isNotEmpty) {
        if (!item.responsable.toLowerCase().contains(_usuarioSeleccionado!.toLowerCase())) {
          return false;
        }
      }

      // 4. Solo alertas
      if (_soloAlertas && !item.tieneAlerta) {
        return false;
      }

      // 5. Búsqueda por texto
      if (_busquedaTexto.trim().isNotEmpty) {
        final busq = _busquedaTexto.trim().toLowerCase();
        final matchTitulo = item.titulo.toLowerCase().contains(busq);
        final matchSubtitulo = item.subtitulo.toLowerCase().contains(busq);
        final matchResponsable = item.responsable.toLowerCase().contains(busq);
        final matchAlerta = item.mensajeAlerta?.toLowerCase().contains(busq) ?? false;
        if (!matchTitulo && !matchSubtitulo && !matchResponsable && !matchAlerta) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
