import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/app_drawer.dart';
import '../providers/caudal_provider.dart';

class CaudalDashboardScreen extends StatefulWidget {
  const CaudalDashboardScreen({super.key});

  @override
  State<CaudalDashboardScreen> createState() => _CaudalDashboardScreenState();
}

class _CaudalDashboardScreenState extends State<CaudalDashboardScreen> {
  int _vistaSeleccionada = 0; // 0: Gráfica, 1: Lista

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<SesionUsuarioProvider>();
    final caudalProvider = context.watch<CaudalProvider>();
    final aforos = caudalProvider.aforos;
    final puedeRegistrar = authProvider.perfil?.puedeEditar ?? false;

    final ultimo = caudalProvider.ultimoAforo;
    final promedio = caudalProvider.caudalPromedioLS;
    final maximo = caudalProvider.caudalMaximoLS;
    final minimo = caudalProvider.caudalMinimoLS;

    final formatoFechaCorta = DateFormat('dd/MM/yy');

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      drawer: const AppDrawer(rutaActual: AppRoutes.caudal),
      appBar: AppBar(
        title: const Text(AppStrings.moduloCaudal),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => caudalProvider.cargarAforos(),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. Tarjetas de Indicadores Clave
              Row(
                children: [
                  Expanded(
                    child: _TarjetaIndicador(
                      titulo: 'Último Caudal',
                      valor: ultimo != null
                          ? '${ultimo.caudalLS.toStringAsFixed(1)} L/s'
                          : '-',
                      subtitulo: ultimo != null
                          ? formatoFechaCorta.format(ultimo.fecha)
                          : '',
                      color: AppColors.aguaPrimario,
                      icono: Icons.water_drop,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TarjetaIndicador(
                      titulo: 'Promedio Histórico',
                      valor: '${promedio.toStringAsFixed(1)} L/s',
                      subtitulo: '${aforos.length} aforos',
                      color: AppColors.senaAzul,
                      icono: Icons.analytics_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TarjetaIndicador(
                      titulo: 'Mínimo Histórico',
                      valor: '${minimo.toStringAsFixed(1)} L/s',
                      subtitulo: 'Época de estiaje',
                      color: AppColors.turquesa,
                      icono: Icons.trending_down,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TarjetaIndicador(
                      titulo: 'Máximo Histórico',
                      valor: '${maximo.toStringAsFixed(1)} L/s',
                      subtitulo: 'Época de lluvias',
                      color: AppColors.azulInstitucional,
                      icono: Icons.trending_up,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Selector de Vista: Gráfica Temporal / Historial
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.show_chart),
                    label: Text('Gráfica Temporal'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.list_alt),
                    label: Text('Lista de Aforos'),
                  ),
                ],
                selected: {_vistaSeleccionada},
                onSelectionChanged: (val) {
                  setState(() => _vistaSeleccionada = val.first);
                },
              ),
              const SizedBox(height: 16),

              // Vista 0: Gráfica fl_chart
              if (_vistaSeleccionada == 0) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Comportamiento del Caudal (L/s)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.senaAzul,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.senaAzul.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Prom: ${promedio.toStringAsFixed(1)} L/s',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.senaAzul,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Quebrada La Seca - Serie mensual continua',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 240,
                          child: aforos.isEmpty
                              ? const Center(child: Text('Sin datos de aforo'))
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (v) => FlLine(
                                        color: Colors.grey.shade200,
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 32,
                                          getTitlesWidget: (val, meta) => Text(
                                            val.toInt().toString(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 24,
                                          interval: (aforos.length / 5).clamp(1.0, 10.0),
                                          getTitlesWidget: (val, meta) {
                                            final idx = val.toInt();
                                            if (idx >= 0 && idx < aforos.length) {
                                              return Text(
                                                DateFormat('MM/yy').format(aforos[idx].fecha),
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    minY: 0,
                                    maxY: (maximo + 5).ceilToDouble(),
                                    lineBarsData: [
                                      // Línea principal de caudal
                                      LineChartBarData(
                                        spots: caudalProvider.spotsGrafica,
                                        isCurved: true,
                                        color: AppColors.aguaPrimario,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (spot, percent, bar, index) =>
                                              FlDotCirclePainter(
                                            radius: 3.5,
                                            color: AppColors.aguaPrimario,
                                            strokeColor: Colors.white,
                                            strokeWidth: 1.5,
                                          ),
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              AppColors.aguaPrimario.withAlpha(60),
                                              AppColors.aguaPrimario.withAlpha(5),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            final idx = spot.spotIndex;
                                            final a = aforos[idx];
                                            return LineTooltipItem(
                                              '${DateFormat('dd/MM/yyyy').format(a.fecha)}\n${a.caudalLS.toStringAsFixed(2)} L/s',
                                              const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Vista 1: Lista detallada de aforos
                ...aforos.reversed.map((a) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.aguaPrimario.withAlpha(25),
                        child: const Icon(
                          Icons.water_drop_outlined,
                          color: AppColors.aguaPrimario,
                        ),
                      ),
                      title: Text(
                        '${a.caudalLS.toStringAsFixed(2)} L/s (${a.caudalM3H.toStringAsFixed(1)} m³/h)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Fecha: ${DateFormat('dd/MM/yyyy').format(a.fecha)} - Hora: ${a.hora}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        context.push(
                          AppRoutes.caudalDetalle,
                          extra: a,
                        );
                      },
                    ),
                  );
                }),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
      floatingActionButton: puedeRegistrar
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.senaVerde,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Aforo'),
              onPressed: () => context.push(AppRoutes.caudalNuevo),
            )
          : null,
    );
  }
}

class _TarjetaIndicador extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final Color color;
  final IconData icono;

  const _TarjetaIndicador({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                ),
                Icon(icono, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              valor,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitulo.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textoSecundario,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
