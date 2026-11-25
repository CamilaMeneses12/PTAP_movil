import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../domain/telemetria/telemetria_planta.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

/// Barra de la gráfica principal: una hora (vista Día) o un día (vistas Semana y Mes).
class _Barra {
  final String etiqueta;
  final String etiquetaLarga;
  final double? valor; // null = periodo futuro, sin datos
  const _Barra(this.etiqueta, this.etiquetaLarga, this.valor);
}

class _PuntoEvolucion {
  final String etiqueta;
  final double valor;
  const _PuntoEvolucion(this.etiqueta, this.valor);
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  int _filtroTemporal = 1; // 0: Día, 1: Semana, 2: Mes
  DateTime _referencia = DateTime.now();

  static const double _metaDiariaM3 = 11000;
  static final _f0 = NumberFormat('#,##0', 'es_CO');
  static final _f1 = NumberFormat('#,##0.0', 'es_CO');

  // ---------------------------------------------------------------------------
  // Periodos
  // ---------------------------------------------------------------------------
  DateTime _inicioPeriodo(DateTime ref) => switch (_filtroTemporal) {
    0 => TelemetriaPlanta.inicioDia(ref),
    1 => TelemetriaPlanta.inicioSemana(ref),
    _ => TelemetriaPlanta.inicioMes(ref),
  };

  DateTime _finPeriodo(DateTime inicio) => switch (_filtroTemporal) {
    0 => DateTime(inicio.year, inicio.month, inicio.day + 1),
    1 => DateTime(inicio.year, inicio.month, inicio.day + 7),
    _ => DateTime(inicio.year, inicio.month + 1),
  };

  DateTime _desplazar(DateTime ref, int pasos) => switch (_filtroTemporal) {
    0 => DateTime(ref.year, ref.month, ref.day + pasos),
    1 => DateTime(ref.year, ref.month, ref.day + 7 * pasos),
    _ => DateTime(ref.year, ref.month + pasos, 1),
  };

  String _etiquetaPeriodo(DateTime inicio) {
    switch (_filtroTemporal) {
      case 0:
        return _capitalizar(
          DateFormat("EEE d 'de' MMM yyyy", 'es_ES').format(inicio),
        );
      case 1:
        final fin = DateTime(inicio.year, inicio.month, inicio.day + 6);
        final mismoMes = fin.month == inicio.month;
        return '${DateFormat(mismoMes ? 'd' : 'd MMM', 'es_ES').format(inicio)} – '
            '${DateFormat('d MMM yyyy', 'es_ES').format(fin)}';
      default:
        return _capitalizar(DateFormat('MMMM yyyy', 'es_ES').format(inicio));
    }
  }

  static String _capitalizar(String t) =>
      t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

  double get _meta => _filtroTemporal == 0 ? _metaDiariaM3 / 24 : _metaDiariaM3;

  List<_Barra> _barras(DateTime inicio, DateTime ahora) {
    if (_filtroTemporal == 0) {
      return [
        for (var h = 0; h < 24; h++)
          () {
            final hora = DateTime(inicio.year, inicio.month, inicio.day, h);
            final valor = hora.isAfter(ahora)
                ? null
                : TelemetriaPlanta.muestra(hora).volumenM3;
            return _Barra(
              h % 4 == 0 ? '${h.toString().padLeft(2, '0')}h' : '',
              '${h.toString().padLeft(2, '0')}:00',
              valor,
            );
          }(),
      ];
    }
    final dias = _finPeriodo(inicio).difference(inicio).inHours ~/ 24;
    const nombres = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return [
      for (var d = 0; d < dias; d++)
        () {
          final dia = DateTime(inicio.year, inicio.month, inicio.day + d);
          final resumen = TelemetriaPlanta.resumenDia(dia, ahora: ahora);
          final etiqueta = _filtroTemporal == 1
              ? nombres[dia.weekday - 1]
              : (dia.day == 1 || dia.day % 5 == 0 ? '${dia.day}' : '');
          return _Barra(
            etiqueta,
            _capitalizar(DateFormat("EEEE d 'de' MMM", 'es_ES').format(dia)),
            resumen.tieneDatos ? resumen.volumenM3 : null,
          );
        }(),
    ];
  }

  /// Gráfica inferior: Día = caudal hora a hora; Semana = 8 semanas; Mes = 6 meses (promedio diario).
  List<_PuntoEvolucion> _evolucion(DateTime inicio, DateTime ahora) {
    if (_filtroTemporal == 0) {
      final muestras = TelemetriaPlanta.resumenDia(
        inicio,
        ahora: ahora,
      ).muestras;
      return [
        for (final m in muestras)
          _PuntoEvolucion(DateFormat('HH:00').format(m.hora), m.caudalEntrada),
      ];
    }
    final cantidad = _filtroTemporal == 1 ? 8 : 6;
    final puntos = <_PuntoEvolucion>[];
    for (var i = cantidad - 1; i >= 0; i--) {
      final ini = _inicioPeriodo(_desplazar(inicio, -i));
      final resumen = TelemetriaPlanta.resumenRango(
        ini,
        _finPeriodo(ini),
        ahora: ahora,
      );
      if (!resumen.tieneDatos) continue;
      final promedioDiario = resumen.volumenM3 / resumen.horas * 24;
      final etiqueta = _filtroTemporal == 1
          ? DateFormat('d MMM', 'es_ES').format(ini)
          : _capitalizar(DateFormat('MMM', 'es_ES').format(ini));
      puntos.add(_PuntoEvolucion(etiqueta, promedioDiario));
    }
    return puntos;
  }

  /// Variación porcentual comparando con las mismas unidades del periodo anterior.
  double? _variacion(double actual, double anterior) =>
      anterior == 0 ? null : (actual - anterior) / anterior * 100;

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final inicio = _inicioPeriodo(_referencia);
    final barras = _barras(inicio, ahora);
    final conDatos = barras.where((b) => b.valor != null).toList();
    final total = conDatos.fold(0.0, (s, b) => s + b.valor!);
    final promedio = conDatos.isEmpty ? 0.0 : total / conDatos.length;

    // Periodo anterior, recortado a la misma cantidad de horas/días con datos
    final inicioAnterior = _inicioPeriodo(_desplazar(inicio, -1));
    final barrasAnteriores = _barras(
      inicioAnterior,
      ahora,
    ).where((b) => b.valor != null).take(conDatos.length).toList();
    final totalAnterior = barrasAnteriores.fold(0.0, (s, b) => s + b.valor!);
    final promedioAnterior = barrasAnteriores.isEmpty
        ? 0.0
        : totalAnterior / barrasAnteriores.length;

    final puedeAvanzar = !_finPeriodo(inicio).isAfter(ahora);
    final unidad = _filtroTemporal == 0 ? 'hora' : 'día';
    final nombreTotal = switch (_filtroTemporal) {
      0 => 'Total día',
      1 => 'Total semana',
      _ => 'Total mes',
    };

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        backgroundColor: AppColors.fondoGeneral,
        elevation: 0,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipal,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Rendimiento del tratamiento · datos simulados',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textoSecundario,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.file_download_outlined,
              color: AppColors.azulMarino,
              size: 22,
            ),
            onPressed: () => context.push(AppRoutes.exportar),
            tooltip: 'Exportar Reportes',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Tabs temporales: Día | Semana | Mes
            Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.bordes.withAlpha(140),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  for (final (i, texto) in const [
                    (0, 'Día'),
                    (1, 'Semana'),
                    (2, 'Mes'),
                  ])
                    _BotonPestanaTemporal(
                      texto: texto,
                      activo: _filtroTemporal == i,
                      alPulsar: () => setState(() {
                        _filtroTemporal = i;
                        _referencia = DateTime.now();
                      }),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Selector de periodo con flechas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Periodo anterior',
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    size: 22,
                    color: AppColors.azulMarino,
                  ),
                  onPressed: () =>
                      setState(() => _referencia = _desplazar(inicio, -1)),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blanco,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.bordes),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.azulPrimario,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _etiquetaPeriodo(inicio),
                            key: const Key('etiqueta_periodo'),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textoPrincipal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Periodo siguiente',
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: puedeAvanzar
                        ? AppColors.azulMarino
                        : AppColors.bordes,
                  ),
                  onPressed: puedeAvanzar
                      ? () =>
                            setState(() => _referencia = _desplazar(inicio, 1))
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _MiniCardKpi(
                    titulo: nombreTotal,
                    valor: _f0.format(total),
                    unidad: 'm³',
                    variacion: _variacion(total, totalAnterior),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniCardKpi(
                    titulo: 'Promedio por $unidad',
                    valor: _f0.format(promedio),
                    unidad: 'm³',
                    variacion: _variacion(promedio, promedioAnterior),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _construirGraficaBarrasTratamiento(barras, conDatos),

            const SizedBox(height: 16),

            _construirGraficaAreaEvolucion(_evolucion(inicio, ahora)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _construirGraficaBarrasTratamiento(
    List<_Barra> barras,
    List<_Barra> conDatos,
  ) {
    final meta = _meta;
    final indiceMax = conDatos.isEmpty
        ? -1
        : barras.indexOf(
            conDatos.reduce((a, b) => a.valor! >= b.valor! ? a : b),
          );
    final superanMeta = conDatos.where((b) => b.valor! >= meta).length;
    final maxY =
        [meta, ...conDatos.map((b) => b.valor!)].reduce(math.max) * 1.15;
    final anchoBarra = barras.length > 20
        ? 6.0
        : (barras.length > 10 ? 9.0 : 16.0);
    final unidad = _filtroTemporal == 0 ? 'horas' : 'días';

    final String nota;
    if (conDatos.isEmpty) {
      nota = 'Todavía no hay datos para este periodo.';
    } else {
      final mayor = barras[indiceMax];
      final cuando = _filtroTemporal == 0
          ? 'La hora de mayor volumen fue las ${mayor.etiquetaLarga}'
          : 'El ${mayor.etiquetaLarga.toLowerCase()} se alcanzó el mayor volumen';
      nota =
          '$cuando (${_f0.format(mayor.valor)} m³). $superanMeta de ${conDatos.length} $unidad superaron la meta.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordes, width: 1),
        boxShadow: AppColors.sombraSuave,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _filtroTemporal == 0
                      ? 'Tratamiento por hora'
                      : 'Tratamiento diario',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textoPrincipal,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(width: 12, height: 2, color: AppColors.turquesa),
                  const SizedBox(width: 4),
                  Text(
                    'Meta ${_f0.format(meta)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.turquesa,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _filtroTemporal == 0
                ? 'Volumen captado por hora · m³'
                : 'Volumen captado por día · m³',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.azulMarino,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          '${barras[group.x].etiquetaLarga}\n${_f0.format(rod.toY)} m³',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: meta,
                      color: AppColors.turquesa,
                      strokeWidth: 1.5,
                      dashArray: [4, 4],
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        final texto = value >= 1000
                            ? '${_f0.format(value / 1000)}k'
                            : _f0.format(value);
                        return Text(
                          texto,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textoSecundario,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        final destacado = i == indiceMax;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            barras[i].etiqueta,
                            style: TextStyle(
                              fontSize: barras.length > 10 ? 9 : 11,
                              fontWeight: destacado
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: destacado
                                  ? AppColors.azulMarino
                                  : AppColors.textoSecundario,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) =>
                      const FlLine(color: AppColors.bordes, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < barras.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: barras[i].valor ?? 0,
                          color: i == indiceMax
                              ? AppColors.azulMarino
                              : AppColors.azulPrimario,
                          width: anchoBarra,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(anchoBarra > 8 ? 5 : 2),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.informacionFondo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.informacion,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nota,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.informacion,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirGraficaAreaEvolucion(List<_PuntoEvolucion> puntos) {
    final esDia = _filtroTemporal == 0;
    final titulo = esDia
        ? 'Caudal de entrada durante el día'
        : 'Evolución del volumen captado';
    final subtitulo = switch (_filtroTemporal) {
      0 => 'Hora a hora · L/s',
      1 => 'Últimas 8 semanas · promedio m³/día',
      _ => 'Últimos 6 meses · promedio m³/día',
    };
    final unidad = esDia ? 'L/s' : 'm³';
    String fmt(double v) => esDia ? _f1.format(v) : _f0.format(v);

    if (puntos.isEmpty) {
      return const SizedBox.shrink();
    }
    final valores = puntos.map((p) => p.valor).toList();
    final minimo = valores.reduce(math.min);
    final maximo = valores.reduce(math.max);
    final promedio = valores.reduce((a, b) => a + b) / valores.length;
    final margen = math.max((maximo - minimo) * 0.25, maximo * 0.02);
    final paso = puntos.length > 8 ? (puntos.length / 4).ceil() : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordes, width: 1),
        boxShadow: AppColors.sombraSuave,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ItemEvolucion(label: 'Mínimo', valor: '${fmt(minimo)} $unidad'),
              _ItemEvolucion(
                label: 'Promedio',
                valor: '${fmt(promedio)} $unidad',
              ),
              _ItemEvolucion(label: 'Máximo', valor: '${fmt(maximo)} $unidad'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.azulMarino,
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          '${puntos[s.x.toInt()].etiqueta}\n${fmt(s.y)} $unidad',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i % paso != 0 && i != puntos.length - 1) {
                          return const SizedBox.shrink();
                        }
                        if (i != puntos.length - 1 &&
                            puntos.length - 1 - i < paso / 2) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          puntos[i].etiqueta,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textoSecundario,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: math.max(1, puntos.length - 1).toDouble(),
                minY: minimo - margen,
                maxY: maximo + margen,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < puntos.length; i++)
                        FlSpot(i.toDouble(), puntos[i].valor),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    preventCurveOverShooting: true,
                    color: AppColors.azulPrimario,
                    barWidth: 2,
                    dotData: FlDotData(show: puntos.length <= 8),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.azulPrimario.withAlpha(50),
                          AppColors.azulPrimario.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonPestanaTemporal extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback alPulsar;

  const _BotonPestanaTemporal({
    required this.texto,
    required this.activo,
    required this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: alPulsar,
        child: Container(
          decoration: BoxDecoration(
            color: activo ? AppColors.azulMarino : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
              color: activo ? AppColors.blanco : AppColors.textoSecundario,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniCardKpi extends StatelessWidget {
  final String titulo;
  final String valor;
  final String unidad;

  /// Variación porcentual frente al periodo anterior; null si no hay con qué comparar.
  final double? variacion;

  const _MiniCardKpi({
    required this.titulo,
    required this.valor,
    required this.unidad,
    required this.variacion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordes),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textoSecundario,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textoPrincipal,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unidad,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            variacion == null
                ? 'Sin comparación'
                : '${variacion! >= 0 ? '+' : ''}${NumberFormat('#,##0.0', 'es_CO').format(variacion)} %',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: variacion == null
                  ? AppColors.textoSecundario
                  : (variacion! >= 0 ? AppColors.exito : AppColors.critico),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemEvolucion extends StatelessWidget {
  final String label;
  final String valor;

  const _ItemEvolucion({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textoSecundario,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textoPrincipal,
          ),
        ),
      ],
    );
  }
}
