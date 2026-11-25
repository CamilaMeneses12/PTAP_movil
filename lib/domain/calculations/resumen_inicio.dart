import '../../data/models/aforo_caudal_modelo.dart';
import '../../data/models/alerta_sistema_modelo.dart';
import '../../data/models/medidores_modelos.dart';
import '../../data/models/registro_fisicoquimico.dart';
import '../validators/validador_rangos.dart';

/// Une la fecha del registro con su hora "HH:mm" para ordenarlos sin ambigüedad.
DateTime momentoRegistro(DateTime fecha, String hora) {
  final partes = hora.split(':');
  final h = partes.isNotEmpty ? int.tryParse(partes[0]) ?? 0 : 0;
  final m = partes.length > 1 ? int.tryParse(partes[1]) ?? 0 : 0;
  return DateTime(fecha.year, fecha.month, fecha.day, h, m);
}

bool _mismoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Formatos que el operario debe diligenciar cada día.
enum FormatoDiario { fisicoquimico, medidores, aforo }

/// Última calidad del agua tratada (sección "Agua clorada" del DO-F-070).
class CalidadAguaTratada {
  final RegistroFisicoquimico registro;
  final EvaluacionRango cloro;
  final EvaluacionRango ph;
  final EvaluacionRango turbidez;

  const CalidadAguaTratada({
    required this.registro,
    required this.cloro,
    required this.ph,
    required this.turbidez,
  });

  bool get conforme => cloro.cumple && ph.cumple && turbidez.cumple;
}

/// Último aforo de la Quebrada La Seca y su diferencia frente al anterior.
class CaudalQuebrada {
  final AforoCaudal ultimo;
  final AforoCaudal? anterior;

  const CaudalQuebrada({required this.ultimo, this.anterior});

  /// Diferencia en L/s frente al aforo anterior; null si es el primero.
  double? get diferenciaLS => anterior == null ? null : ultimo.caudalLS - anterior!.caudalLS;
}

/// Conteo de alertas activas por severidad.
class ResumenAlertas {
  final int criticas;
  final int advertencias;
  final int informativas;
  final AlertaSistema? masReciente;

  const ResumenAlertas({
    required this.criticas,
    required this.advertencias,
    required this.informativas,
    required this.masReciente,
  });

  int get total => criticas + advertencias + informativas;
}

/// Cálculos del menú principal. Solo usa lo que el operario registra: DO-F-070, jornadas de
/// medidores, aforos de caudal y alertas. Nada de valores fijos ni telemetría simulada.
class ResumenInicio {
  /// La app marca "pérdida elevada" cuando el agua no registrada supera 5 m³ (Medidores e Historial).
  static const double perdidaElevadaM3 = 5.0;

  /// Indica qué formatos ya tienen un registro con fecha de hoy.
  static Map<FormatoDiario, bool> pendientesDeHoy({
    required List<RegistroFisicoquimico> fisicoquimicos,
    required List<JornadaMedidores> jornadas,
    required List<AforoCaudal> aforos,
    required DateTime ahora,
  }) {
    return {
      FormatoDiario.fisicoquimico: fisicoquimicos.any((r) => _mismoDia(r.fecha, ahora)),
      FormatoDiario.medidores: jornadas.any((j) => _mismoDia(j.fecha, ahora)),
      FormatoDiario.aforo: aforos.any((a) => _mismoDia(a.fecha, ahora)),
    };
  }

  /// Registros DO-F-070 del más antiguo al más reciente.
  static List<RegistroFisicoquimico> _fisicoOrdenados(List<RegistroFisicoquimico> registros) =>
      [...registros]..sort((a, b) => momentoRegistro(a.fecha, a.hora).compareTo(momentoRegistro(b.fecha, b.hora)));

  static CalidadAguaTratada? calidadAguaTratada(List<RegistroFisicoquimico> registros) {
    if (registros.isEmpty) return null;
    final ultimo = _fisicoOrdenados(registros).last;
    return CalidadAguaTratada(
      registro: ultimo,
      cloro: ValidadorRangos.validarCloroResidual(ultimo.cloradaCloroResidual),
      ph: ValidadorRangos.validarPhTratada(ultimo.cloradaPh),
      turbidez: ValidadorRangos.validarTurbidezTratada(ultimo.cloradaTurbidez),
    );
  }

  /// Cloro residual libre de los últimos [cantidad] registros DO-F-070 que lo tienen, en orden cronológico.
  static List<({DateTime momento, double valor})> tendenciaCloro(
    List<RegistroFisicoquimico> registros, {
    int cantidad = 7,
  }) {
    final conCloro = _fisicoOrdenados(registros).where((r) => r.cloradaCloroResidual != null).toList();
    final desde = conCloro.length > cantidad ? conCloro.length - cantidad : 0;
    return [
      for (final r in conCloro.sublist(desde))
        (momento: momentoRegistro(r.fecha, r.hora), valor: r.cloradaCloroResidual!),
    ];
  }

  static CaudalQuebrada? caudalQuebrada(List<AforoCaudal> aforos) {
    if (aforos.isEmpty) return null;
    final ordenados = [...aforos]
      ..sort((a, b) => momentoRegistro(a.fecha, a.hora).compareTo(momentoRegistro(b.fecha, b.hora)));
    return CaudalQuebrada(
      ultimo: ordenados.last,
      anterior: ordenados.length > 1 ? ordenados[ordenados.length - 2] : null,
    );
  }

  static JornadaMedidores? ultimaJornada(List<JornadaMedidores> jornadas) {
    if (jornadas.isEmpty) return null;
    return ([...jornadas]
          ..sort((a, b) => momentoRegistro(a.fecha, a.hora).compareTo(momentoRegistro(b.fecha, b.hora))))
        .last;
  }

  static bool perdidaElevada(JornadaMedidores jornada) => jornada.aguaNoRegistrada > perdidaElevadaM3;

  static ResumenAlertas resumenAlertas(List<AlertaSistema> activas) {
    AlertaSistema? reciente;
    for (final a in activas) {
      if (reciente == null || a.fechaHora.isAfter(reciente.fechaHora)) reciente = a;
    }
    return ResumenAlertas(
      criticas: activas.where((a) => a.severidad == SeveridadAlerta.critica).length,
      advertencias: activas.where((a) => a.severidad == SeveridadAlerta.advertencia).length,
      informativas: activas.where((a) => a.severidad == SeveridadAlerta.informacion).length,
      masReciente: reciente,
    );
  }
}
