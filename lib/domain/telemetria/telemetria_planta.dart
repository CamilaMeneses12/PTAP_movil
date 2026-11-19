import 'dart:math' as math;
import '../validators/validador_rangos.dart';

/// Lectura horaria de la planta: caudales, presión de red y nivel del tanque.
class MuestraTelemetria {
  final DateTime hora;
  final double caudalEntrada; // L/s
  final double caudalSalida; // L/s
  final double presion; // bar
  final double nivelTanque; // %

  const MuestraTelemetria({
    required this.hora,
    required this.caudalEntrada,
    required this.caudalSalida,
    required this.presion,
    required this.nivelTanque,
  });

  /// Volumen tratado (entregado a la red) durante esa hora, en m³.
  double get volumenM3 => caudalSalida * 3.6;

  bool get caudalFueraDeRango => !ValidadorRangos.validarCaudalEntrada(caudalEntrada).cumple;
  bool get presionFueraDeRango => !ValidadorRangos.validarPresionRed(presion).cumple;
  bool get nivelFueraDeRango => !ValidadorRangos.validarNivelTanque(nivelTanque).cumple;
}

/// Agregado de un periodo (una hora, un día, una semana o un mes).
class ResumenPeriodo {
  final DateTime inicio;
  final List<MuestraTelemetria> muestras;

  const ResumenPeriodo({required this.inicio, required this.muestras});

  bool get tieneDatos => muestras.isNotEmpty;
  int get horas => muestras.length;

  double _promedio(double Function(MuestraTelemetria) f) =>
      muestras.isEmpty ? 0 : muestras.map(f).reduce((a, b) => a + b) / muestras.length;

  double get entradaPromedio => _promedio((m) => m.caudalEntrada);
  double get salidaPromedio => _promedio((m) => m.caudalSalida);
  double get volumenM3 => muestras.fold(0.0, (s, m) => s + m.volumenM3);

  /// Porcentaje del agua captada que se entregó tratada a la red.
  double get eficiencia {
    final entrada = muestras.fold(0.0, (s, m) => s + m.caudalEntrada);
    if (entrada == 0) return 0;
    return muestras.fold(0.0, (s, m) => s + m.caudalSalida) / entrada * 100;
  }

  List<MuestraTelemetria> get horasFueraDeRango => muestras.where((m) => m.caudalFueraDeRango).toList();
}

/// Fuente única de telemetría de la planta.
///
/// IMPORTANTE: la planta aún no tiene sensores conectados a la app, así que estos valores son
/// SIMULADOS. Se generan de forma determinista (la misma hora siempre da el mismo valor) con el
/// ciclo diario típico de una PTAP, para que Monitoreo, Estadísticas y Registros muestren datos
/// coherentes entre sí. Cuando exista telemetría real (sensores, SCADA o una tabla en Supabase),
/// solo hay que reemplazar [muestra] y todas las pantallas usarán los datos reales.
class TelemetriaPlanta {
  static const double capacidadTanqueM3 = 2500;

  static DateTime _inicioHora(DateTime t) => DateTime(t.year, t.month, t.day, t.hour);
  static DateTime inicioDia(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Lunes de la semana de [t].
  static DateTime inicioSemana(DateTime t) => inicioDia(t).subtract(Duration(days: t.weekday - 1));
  static DateTime inicioMes(DateTime t) => DateTime(t.year, t.month);

  static MuestraTelemetria muestra(DateTime hora) {
    final h = _inicioHora(hora);
    final semilla = DateTime.utc(h.year, h.month, h.day, h.hour).millisecondsSinceEpoch ~/ 3600000;
    final r = math.Random(semilla);
    double ruido(double amplitud) => (r.nextDouble() - 0.5) * amplitud;
    double ciclo(double desfaseHoras) => math.sin(2 * math.pi * (h.hour - desfaseHoras) / 24);

    // Variación lenta entre días (algunos días se capta más agua que otros)
    final dia = DateTime.utc(h.year, h.month, h.day).millisecondsSinceEpoch ~/ 86400000;
    final variacionDia = math.sin(dia * 0.9) * 4 + math.Random(dia).nextDouble() * 3;

    var entrada = 123 + variacionDia + 11 * ciclo(8) + ruido(6);
    final eventoCaudal = r.nextInt(70);
    if (eventoCaudal == 0) entrada += 17; // pico de captación (fuera de rango por arriba)
    if (eventoCaudal == 1) entrada -= 15; // caída de captación (fuera de rango por abajo)
    final salida = entrada * (0.948 + r.nextDouble() * 0.012);

    var presion = 3.35 - 0.38 * ciclo(7) + ruido(0.16);
    if (r.nextInt(90) == 0) presion -= 0.75;

    var nivel = 72 + 14 * ciclo(4) + ruido(3);
    if (r.nextInt(150) == 0) nivel = 34 + r.nextDouble() * 4;

    return MuestraTelemetria(
      hora: h,
      caudalEntrada: double.parse(entrada.toStringAsFixed(1)),
      caudalSalida: double.parse(salida.toStringAsFixed(1)),
      presion: double.parse(presion.toStringAsFixed(2)),
      nivelTanque: double.parse(nivel.clamp(0, 100).toStringAsFixed(1)),
    );
  }

  /// Muestras horarias entre [desde] (incluido) y [hasta] (excluido), nunca posteriores a [ahora].
  static List<MuestraTelemetria> rango(DateTime desde, DateTime hasta, {required DateTime ahora}) {
    final limite = _inicioHora(ahora).add(const Duration(hours: 1));
    final fin = hasta.isAfter(limite) ? limite : hasta;
    final lista = <MuestraTelemetria>[];
    var t = _inicioHora(desde);
    while (t.isBefore(fin)) {
      lista.add(muestra(t));
      t = DateTime(t.year, t.month, t.day, t.hour + 1);
    }
    return lista;
  }

  /// Últimas [horas] horas terminando en la hora actual, en orden cronológico.
  static List<MuestraTelemetria> ultimasHoras(DateTime ahora, int horas) {
    final fin = _inicioHora(ahora);
    final inicio = DateTime(fin.year, fin.month, fin.day, fin.hour - (horas - 1));
    return rango(inicio, fin.add(const Duration(hours: 1)), ahora: ahora);
  }

  static ResumenPeriodo resumenDia(DateTime dia, {required DateTime ahora}) {
    final inicio = inicioDia(dia);
    return ResumenPeriodo(
      inicio: inicio,
      muestras: rango(inicio, DateTime(inicio.year, inicio.month, inicio.day + 1), ahora: ahora),
    );
  }

  /// Un resumen por día entre [desde] y [hasta] (ambos incluidos), en orden cronológico.
  static List<ResumenPeriodo> resumenDiario(DateTime desde, DateTime hasta, {required DateTime ahora}) {
    final lista = <ResumenPeriodo>[];
    var d = inicioDia(desde);
    final fin = inicioDia(hasta);
    while (!d.isAfter(fin)) {
      lista.add(resumenDia(d, ahora: ahora));
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return lista;
  }

  static ResumenPeriodo resumenRango(DateTime desde, DateTime hastaExcluido, {required DateTime ahora}) =>
      ResumenPeriodo(inicio: desde, muestras: rango(desde, hastaExcluido, ahora: ahora));
}
