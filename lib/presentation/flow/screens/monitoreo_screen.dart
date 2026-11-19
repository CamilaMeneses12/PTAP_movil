import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/telemetria/telemetria_planta.dart';
import '../../../domain/validators/validador_rangos.dart';
import '../../common/widgets/chip_estado.dart';

class MonitoreoScreen extends StatefulWidget {
  const MonitoreoScreen({super.key});

  @override
  State<MonitoreoScreen> createState() => _MonitoreoScreenState();
}

/// Configuración de la gráfica de cada pestaña (Caudal, Presión, Nivel).
class _SerieGrafica {
  final String nombre;
  final Color color;
  final List<double> valores;
  const _SerieGrafica(this.nombre, this.color, this.valores);
}

class _VistaMonitoreo {
  final String titulo;
  final String unidad;
  final List<_SerieGrafica> series;
  final double? minimo;
  final double? maximo;
  final String textoRango;
  final String detalle;
  final int decimales;

  const _VistaMonitoreo({
    required this.titulo,
    required this.unidad,
    required this.series,
    required this.minimo,
    required this.maximo,
    required this.textoRango,
    required this.detalle,
    required this.decimales,
  });

  List<double> get principal => series.first.valores;
  bool fueraDeRango(double v) =>
      (minimo != null && v < minimo!) || (maximo != null && v > maximo!);
}

class _MonitoreoScreenState extends State<MonitoreoScreen> {
  int _indiceSubpestana = 0; // 0: Caudal, 1: Presión, 2: Nivel

  static final _f1 = NumberFormat('#,##0.0', 'es_CO');
  static final _f2 = NumberFormat('#,##0.00', 'es_CO');
  static final _f0 = NumberFormat('#,##0', 'es_CO');

  String _fmt(double v, int decimales) => switch (decimales) {
    0 => _f0.format(v),
    1 => _f1.format(v),
    _ => _f2.format(v),
  };

  _VistaMonitoreo _vista(List<MuestraTelemetria> horas) {
    final actual = horas.last;
    switch (_indiceSubpestana) {
      case 1:
        return _VistaMonitoreo(
          titulo: 'Presión de la red de distribución',
          unidad: 'bar',
          series: [
            _SerieGrafica('Presión', AppColors.azulPrimario, [
              for (final h in horas) h.presion,
            ]),
          ],
          minimo: ValidadorRangos.presionRedMin,
          maximo: ValidadorRangos.presionRedMax,
          textoRango:
              'Rango ${_f1.format(ValidadorRangos.presionRedMin)}–${_f1.format(ValidadorRangos.presionRedMax)} bar',
          detalle: actual.presionFueraDeRango
              ? 'Presión actual fuera del rango operativo'
              : 'Presión actual dentro del rango operativo',
          decimales: 2,
        );
      case 2:
        final volumen =
            actual.nivelTanque / 100 * TelemetriaPlanta.capacidadTanqueM3;
        return _VistaMonitoreo(
          titulo: 'Nivel del tanque de almacenamiento',
          unidad: '%',
          series: [
            _SerieGrafica('Nivel', AppColors.turquesa, [
              for (final h in horas) h.nivelTanque,
            ]),
          ],
          minimo: ValidadorRangos.nivelTanqueMin,
          maximo: null,
          textoRango:
              'Mínimo operativo ${_f0.format(ValidadorRangos.nivelTanqueMin)} %',
          detalle:
              '${_f0.format(volumen)} m³ de ${_f0.format(TelemetriaPlanta.capacidadTanqueM3)} m³ disponibles',
          decimales: 1,
        );
      default:
        final dif = actual.caudalEntrada - actual.caudalSalida;
        final pct = actual.caudalEntrada == 0
            ? 0
            : dif / actual.caudalEntrada * 100;
        return _VistaMonitoreo(
          titulo: 'Caudal de entrada vs. salida',
          unidad: 'L/s',
          series: [
            _SerieGrafica('Entrada', AppColors.azulPrimario, [
              for (final h in horas) h.caudalEntrada,
            ]),
            _SerieGrafica('Salida', AppColors.turquesa, [
              for (final h in horas) h.caudalSalida,
            ]),
          ],
          minimo: ValidadorRangos.caudalEntradaMin,
          maximo: ValidadorRangos.caudalEntradaMax,
          textoRango:
              'Rango ${_f0.format(ValidadorRangos.caudalEntradaMin)}–${_f0.format(ValidadorRangos.caudalEntradaMax)} L/s',
          detalle: 'Diferencia: ${_f1.format(dif)} L/s (${_f1.format(pct)} %)',
          decimales: 1,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final horas = TelemetriaPlanta.ultimasHoras(ahora, 24);
    final actual = horas.last;
    final vista = _vista(horas);
    final horaTxt = DateFormat('HH:mm').format(ahora);

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        backgroundColor: AppColors.fondoGeneral,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monitoreo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipal,
                letterSpacing: -0.3,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.turquesa,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Datos simulados · Actualizado $horaTxt',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textoSecundario,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.azulMarino,
              size: 22,
            ),
            tooltip: 'Actualizar',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Segmented control: Caudal | Presión | Nivel
            Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.bordes.withAlpha(140),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _SegmentButton(
                    texto: 'Caudal',
                    seleccionado: _indiceSubpestana == 0,
                    alPulsar: () => setState(() => _indiceSubpestana = 0),
                  ),
                  _SegmentButton(
                    texto: 'Presión',
                    seleccionado: _indiceSubpestana == 1,
                    alPulsar: () => setState(() => _indiceSubpestana = 1),
                  ),
                  _SegmentButton(
                    texto: 'Nivel',
                    seleccionado: _indiceSubpestana == 2,
                    alPulsar: () => setState(() => _indiceSubpestana = 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Tarjeta principal: cambia con la pestaña seleccionada (últimas 24 h)
            _construirTarjetaGrafica(vista, horas),

            const SizedBox(height: 16),

            // Sección: Etapas del proceso
            const Text(
              'Etapas del proceso',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipal,
              ),
            ),
            const SizedBox(height: 10),

            _ItemEtapaProceso(
              numero: '1',
              nombre: 'Captación',
              detalle: 'Caudal ${_f1.format(actual.caudalEntrada)} L/s',
              estado: actual.caudalFueraDeRango
                  ? TipoEstadoPlanta.enAlerta
                  : TipoEstadoPlanta.operativa,
            ),
            const _ItemEtapaProceso(
              numero: '2',
              nombre: 'Coagulación y floculación',
              detalle: 'Dosis de coagulante 18 mg/L',
              estado: TipoEstadoPlanta.operativa,
            ),
            const _ItemEtapaProceso(
              numero: '3',
              nombre: 'Sedimentación',
              detalle: 'Turbidez 3,2 NTU',
              estado: TipoEstadoPlanta.operativa,
            ),
            const _ItemEtapaProceso(
              numero: '4',
              nombre: 'Filtración',
              detalle: 'Filtro 3 en retrolavado',
              estado: TipoEstadoPlanta.mantenimiento,
            ),
            const _ItemEtapaProceso(
              numero: '5',
              nombre: 'Desinfección',
              detalle: 'Cloro residual 1,1 mg/L',
              estado: TipoEstadoPlanta.operativa,
            ),
            _ItemEtapaProceso(
              numero: '6',
              nombre: 'Almacenamiento',
              detalle:
                  'Nivel ${_f0.format(actual.nivelTanque)} % · ${_f0.format(actual.nivelTanque / 100 * TelemetriaPlanta.capacidadTanqueM3)} m³',
              estado: actual.nivelFueraDeRango
                  ? TipoEstadoPlanta.enAlerta
                  : TipoEstadoPlanta.operativa,
            ),

            const SizedBox(height: 16),

            // Fila de medidores y gauges (Presión de red + Nivel de tanque)
            Row(
              children: [
                Expanded(child: _MedidorPresion(valorPresion: actual.presion)),
                const SizedBox(width: 12),
                Expanded(
                  child: _MedidorNivelTanque(
                    porcentaje: actual.nivelTanque.round(),
                    volumenM3:
                        (actual.nivelTanque /
                                100 *
                                TelemetriaPlanta.capacidadTanqueM3)
                            .round(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaGrafica(
    _VistaMonitoreo vista,
    List<MuestraTelemetria> horas,
  ) {
    final valores = vista.principal;
    final todos = [for (final s in vista.series) ...s.valores];
    final maximo = valores.reduce(math.max);
    final minimo = valores.reduce(math.min);
    final promedio = valores.reduce((a, b) => a + b) / valores.length;

    // Eje Y: incluye los datos y los límites del rango, con un margen
    final limites = [...todos, ?vista.minimo, ?vista.maximo];
    final bajo = limites.reduce(math.min);
    final alto = limites.reduce(math.max);
    final margen = (alto - bajo) * 0.12;
    final ultimo = valores.length - 1;
    final u = vista.unidad == '%' ? ' %' : ' ${vista.unidad}';

    return Container(
      key: ValueKey('grafica_monitoreo_$_indiceSubpestana'),
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
            vista.titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Últimas 24 h · Intervalo 1 h',
            style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 12),

          // Valor actual de cada serie
          Wrap(
            spacing: 24,
            runSpacing: 6,
            children: [
              for (final s in vista.series)
                _ItemValorCaudal(
                  etiqueta: s.nombre,
                  valor: _fmt(s.valores.last, vista.decimales),
                  unidad: vista.unidad,
                  colorPunto: s.color,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${vista.detalle} · ${vista.textoRango}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) =>
                      const FlLine(color: AppColors.bordes, strokeWidth: 0.8),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    for (final l in [?vista.minimo, ?vista.maximo])
                      HorizontalLine(
                        y: l,
                        color: AppColors.advertencia,
                        strokeWidth: 1.2,
                        dashArray: [5, 4],
                      ),
                  ],
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.azulMarino,
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          '${s.barIndex == 0 ? '${DateFormat('HH:00').format(horas[s.x.toInt()].hora)}\n' : ''}'
                          '${vista.series[s.barIndex].nombre}: ${_fmt(s.y, vista.decimales)}$u',
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
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _fmt(value, vista.decimales == 2 ? 1 : 0),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textoSecundario,
                          ),
                        );
                      },
                    ),
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
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i == ultimo) {
                          return const Text(
                            'Ahora',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.azulMarino,
                            ),
                          );
                        }
                        if (i % 6 != 0 || ultimo - i < 3) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          DateFormat('HH:00').format(horas[i].hora),
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
                maxX: ultimo.toDouble(),
                minY: bajo - margen,
                maxY: alto + margen,
                lineBarsData: [
                  for (var b = 0; b < vista.series.length; b++)
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < vista.series[b].valores.length; i++)
                          FlSpot(i.toDouble(), vista.series[b].valores[i]),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.3,
                      preventCurveOverShooting: true,
                      color: vista.series[b].color,
                      barWidth: 2.5,
                      belowBarData: BarAreaData(
                        show: vista.series.length == 1,
                        color: vista.series[b].color.withAlpha(28),
                      ),
                      dotData: FlDotData(
                        show: b == 0,
                        // Marca en rojo las horas fuera de rango
                        checkToShowDot: (spot, _) => vista.fueraDeRango(spot.y),
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 4.5,
                              color: AppColors.critico,
                              strokeWidth: 2,
                              strokeColor: AppColors.blanco,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Resumen máximo / mínimo / promedio de la serie principal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.fondoGeneral,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniEstadistica(
                  label: 'Máximo 24h',
                  valor: '${_fmt(maximo, vista.decimales)}$u',
                  esAlerta: vista.fueraDeRango(maximo),
                ),
                _MiniEstadistica(
                  label: 'Mínimo 24h',
                  valor: '${_fmt(minimo, vista.decimales)}$u',
                  esAlerta: vista.fueraDeRango(minimo),
                ),
                _MiniEstadistica(
                  label: 'Promedio',
                  valor: '${_fmt(promedio, vista.decimales)}$u',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String texto;
  final bool seleccionado;
  final VoidCallback alPulsar;

  const _SegmentButton({
    required this.texto,
    required this.seleccionado,
    required this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: alPulsar,
        child: Container(
          decoration: BoxDecoration(
            color: seleccionado ? AppColors.blanco : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: seleccionado ? AppColors.sombraSuave : null,
          ),
          alignment: Alignment.center,
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
              color: seleccionado
                  ? AppColors.azulMarino
                  : AppColors.textoSecundario,
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemValorCaudal extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final String unidad;
  final Color colorPunto;

  const _ItemValorCaudal({
    required this.etiqueta,
    required this.valor,
    required this.unidad,
    required this.colorPunto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: colorPunto, shape: BoxShape.circle),
        ),
        Text(
          '$etiqueta ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textoSecundario,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textoPrincipal,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          unidad,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textoSecundario,
          ),
        ),
      ],
    );
  }
}

class _MiniEstadistica extends StatelessWidget {
  final String label;
  final String valor;
  final bool esAlerta;

  const _MiniEstadistica({
    required this.label,
    required this.valor,
    this.esAlerta = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textoSecundario,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          valor,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: esAlerta ? AppColors.critico : AppColors.textoPrincipal,
          ),
        ),
      ],
    );
  }
}

class _ItemEtapaProceso extends StatelessWidget {
  final String numero;
  final String nombre;
  final String detalle;
  final TipoEstadoPlanta estado;

  const _ItemEtapaProceso({
    required this.numero,
    required this.nombre,
    required this.detalle,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordes, width: 0.9),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.azulClaro,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              numero,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.azulMarino,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  detalle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          ChipEstado(estado: estado, compacto: true),
        ],
      ),
    );
  }
}

class _MedidorPresion extends StatelessWidget {
  final double valorPresion;

  const _MedidorPresion({required this.valorPresion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordes, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.speed_rounded,
                size: 16,
                color: AppColors.azulPrimario,
              ),
              SizedBox(width: 6),
              Text(
                'Presión de red',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoPrincipal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 80,
              height: 50,
              child: CustomPaint(
                painter: _ArcoGaugePainter(
                  valor: valorPresion,
                  min: 0,
                  max: 6,
                  color: AppColors.turquesa,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      '${valorPresion.toString().replaceAll('.', ',')} bar',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Rango 2,8–4,0 bar',
              style: TextStyle(fontSize: 10, color: AppColors.textoSecundario),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedidorNivelTanque extends StatelessWidget {
  final int porcentaje;
  final int volumenM3;

  const _MedidorNivelTanque({
    required this.porcentaje,
    required this.volumenM3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordes, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_rounded, size: 16, color: AppColors.turquesa),
              SizedBox(width: 6),
              Text(
                'Nivel del tanque',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoPrincipal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Barra vertical de nivel tipo tanque
              Container(
                width: 24,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.fondoGeneral,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.bordes),
                ),
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 52 * (porcentaje / 100),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.turquesa,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$porcentaje %',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                    Text(
                      '$volumenM3 m³',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Mín. operativo 40 %',
            style: TextStyle(fontSize: 10, color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }
}

class _ArcoGaugePainter extends CustomPainter {
  final double valor;
  final double min;
  final double max;
  final Color color;

  _ArcoGaugePainter({
    required this.valor,
    required this.min,
    required this.max,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = AppColors.bordes
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      backgroundPaint,
    );

    final porcentaje = ((valor - min) / (max - min)).clamp(0.0, 1.0);
    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * porcentaje,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
