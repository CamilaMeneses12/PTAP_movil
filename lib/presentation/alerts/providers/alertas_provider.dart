import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../data/models/alerta_sistema_modelo.dart';
import '../../../domain/validators/validador_rangos.dart';

/// Alertas generadas por los registros del operario (DO-F-070, medidores y aforos).
/// Se guardan en memoria: no hay una tabla de alertas en Supabase.
class AlertasProvider with ChangeNotifier {
  final List<AlertaSistema> _alertas = [];

  List<AlertaSistema> get todas => List.unmodifiable(_alertas);
  List<AlertaSistema> get activas => _alertas.where((a) => !a.resuelta).toList();
  List<AlertaSistema> get historial => _alertas.where((a) => a.resuelta).toList();

  int get activasCount => activas.length;
  int get criticasCount => activas.where((a) => a.severidad == SeveridadAlerta.critica).length;
  int get advertenciasCount => activas.where((a) => a.severidad == SeveridadAlerta.advertencia).length;
  int get informacionCount => activas.where((a) => a.severidad == SeveridadAlerta.informacion).length;

  int get noLeidasCount => _alertas.where((a) => !a.leida).length;

  AlertaSistema? buscar(String id) {
    for (final a in _alertas) {
      if (a.id == id) return a;
    }
    return null;
  }

  void marcarTodasLeidas() {
    for (int i = 0; i < _alertas.length; i++) {
      _alertas[i] = _alertas[i].copyWith(leida: true);
    }
    notifyListeners();
  }

  /// Abrir el detalle marca la alerta como leída, pero no como resuelta.
  void marcarLeida(String id) {
    final idx = _alertas.indexWhere((a) => a.id == id);
    if (idx != -1 && !_alertas[idx].leida) {
      _alertas[idx] = _alertas[idx].copyWith(leida: true);
      notifyListeners();
    }
  }

  void marcarResuelta(String id, {String? resueltaPor, String? nota}) {
    final idx = _alertas.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final notaLimpia = nota?.trim();
      _alertas[idx] = _alertas[idx].copyWith(
        resuelta: true,
        leida: true,
        resueltaPor: resueltaPor,
        fechaResolucion: DateTime.now(),
        notaResolucion: (notaLimpia == null || notaLimpia.isEmpty) ? null : notaLimpia,
      );
      notifyListeners();
    }
  }

  void agregarAlerta({
    required String titulo,
    required String descripcion,
    required SeveridadAlerta severidad,
    String? parametro,
    double? valorRegistrado,
    String? rangoEsperado,
    TipoFormatoAlerta? tipoFormato,
    String? registroId,
    String? responsable,
    String? puntoControl,
    String? parametroClave,
    double? minimo,
    double? maximo,
    String? unidad,
  }) {
    final ahora = DateTime.now();
    final hora = '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';
    _alertas.insert(
      0,
      AlertaSistema(
        id: 'alt-${ahora.microsecondsSinceEpoch}-${_alertas.length}',
        titulo: titulo,
        descripcion: descripcion,
        severidad: severidad,
        fechaHora: ahora,
        hora: hora,
        parametro: parametro,
        valorRegistrado: valorRegistrado,
        rangoEsperado: rangoEsperado ?? _textoRango(minimo, maximo, unidad),
        grupoFecha: 'HOY',
        tipoFormato: tipoFormato,
        registroId: registroId,
        responsable: responsable,
        puntoControl: puntoControl,
        parametroClave: parametroClave,
        minimo: minimo,
        maximo: maximo,
        unidad: unidad,
      ),
    );
    notifyListeners();
  }

  /// Crea la alerta de un valor fuera de rango con los datos de su evaluación.
  void agregarDesdeEvaluacion({
    required EvaluacionRango evaluacion,
    required String titulo,
    required String parametro,
    required String parametroClave,
    required TipoFormatoAlerta tipoFormato,
    required String registroId,
    required String responsable,
    String? puntoControl,
  }) {
    agregarAlerta(
      titulo: titulo,
      descripcion: evaluacion.mensajeCompleto,
      severidad: evaluacion.esCritico ? SeveridadAlerta.critica : SeveridadAlerta.advertencia,
      parametro: parametro,
      valorRegistrado: evaluacion.valor,
      tipoFormato: tipoFormato,
      registroId: registroId,
      responsable: responsable,
      puntoControl: puntoControl,
      parametroClave: parametroClave,
      minimo: evaluacion.minimo,
      maximo: evaluacion.maximo,
      unidad: evaluacion.unidad,
    );
  }

  static String? _textoRango(double? min, double? max, String? unidad) {
    if (min == null && max == null) return null;
    final f = NumberFormat('#,##0.0#', 'es_CO');
    final u = (unidad == null || unidad.isEmpty || unidad == 'pH') ? '' : ' $unidad';
    if (min != null && max != null) return '${f.format(min)}–${f.format(max)}$u';
    if (min != null) return 'mín. ${f.format(min)}$u';
    return 'máx. ${f.format(max)}$u';
  }
}
