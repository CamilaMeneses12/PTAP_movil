import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  int _filtroTemporal = 1; // 0: Día, 1: Semana, 2: Mes

  @override
  Widget build(BuildContext context) {
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
              'Rendimiento del tratamiento',
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
            icon: const Icon(Icons.file_download_outlined, color: AppColors.azulMarino, size: 22),
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
                  _BotonPestanaTemporal(
                    texto: 'Día',
                    activo: _filtroTemporal == 0,
                    alPulsar: () => setState(() => _filtroTemporal = 0),
                  ),
                  _BotonPestanaTemporal(
                    texto: 'Semana',
                    activo: _filtroTemporal == 1,
                    alPulsar: () => setState(() => _filtroTemporal = 1),
                  ),
                  _BotonPestanaTemporal(
                    texto: 'Mes',
                    activo: _filtroTemporal == 2,
                    alPulsar: () => setState(() => _filtroTemporal = 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Selector de rango de fechas con flechas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.azulMarino),
                  onPressed: () {},
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.bordes),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.azulPrimario),
                      SizedBox(width: 6),
                      Text(
                        '10 - 16 nov 2026',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.azulMarino),
                  onPressed: () {},
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 3 Tarjetas resumen superiores (Total semana, Promedio día, Eficiencia)
            Row(
              children: [
                Expanded(
                  child: _MiniCardKpi(
                    titulo: 'Total semana',
                    valor: '76.045',
                    unidad: 'm³',
                    variacion: '+2,4 %',
                    positiva: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniCardKpi(
                    titulo: 'Promedio día',
                    valor: '10.864',
                    unidad: 'm³',
                    variacion: '-0,8 %',
                    positiva: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniCardKpi(
                    titulo: 'Eficiencia',
                    valor: '95,4',
                    unidad: '%',
                    variacion: '+0,3 %',
                    positiva: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tarjeta: Tratamiento diario (Gráfica de Barras con Meta Punteada)
            _construirGraficaBarrasTratamiento(),

            const SizedBox(height: 16),

            // Tarjeta: Evolución del volumen tratado (Área)
            _construirGraficaAreaEvolucion(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _construirGraficaBarrasTratamiento() {
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
              const Text(
                'Tratamiento diario',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoPrincipal,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 2,
                    color: AppColors.turquesa,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Meta 11.000',
                    style: TextStyle(
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
          const Text(
            'Volumen tratado por día · m³',
            style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 16),

          // Gráfica de Barras
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 13000,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.azulMarino,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                      return BarTooltipItem(
                        '${dias[group.x.toInt()]}\n${rod.toY.toInt()} m³',
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('0', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                        if (value == 5000) return const Text('5k', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                        if (value == 10000) return const Text('10k', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                        final esJueves = value.toInt() == 3;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dias[value.toInt()],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: esJueves ? FontWeight.w700 : FontWeight.w500,
                              color: esJueves ? AppColors.azulMarino : AppColors.textoSecundario,
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
                  getDrawingHorizontalLine: (val) {
                    if (val == 11000) {
                      return FlLine(
                        color: AppColors.turquesa,
                        strokeWidth: 1.5,
                        dashArray: [4, 4],
                      );
                    }
                    return FlLine(color: AppColors.bordes, strokeWidth: 0.8);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _crearGrupoBarra(0, 10200),
                  _crearGrupoBarra(1, 10800),
                  _crearGrupoBarra(2, 11100),
                  _crearGrupoBarra(3, 11320, esDestacado: true), // Jueves más alto
                  _crearGrupoBarra(4, 11050),
                  _crearGrupoBarra(5, 10700),
                  _crearGrupoBarra(6, 10875),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Nota informativa de Figma
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.informacionFondo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: AppColors.informacion),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El jueves se alcanzó el mayor volumen tratado: 4 de 7 días superaron la meta.',
                    style: TextStyle(
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

  BarChartGroupData _crearGrupoBarra(int x, double y, {bool esDestacado = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: esDestacado ? AppColors.azulMarino : AppColors.azulPrimario,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
        ),
      ],
    );
  }

  Widget _construirGraficaAreaEvolucion() {
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
          const Text(
            'Evolución del volumen tratado',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Últimos 30 días · m³/día',
            style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 12),

          // Resumen min / avg / acumulado
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ItemEvolucion(label: 'Mínimo', valor: '10.015 m³'),
              _ItemEvolucion(label: 'Promedio', valor: '10.864 m³'),
              _ItemEvolucion(label: 'Acumulado', valor: '317.389 m³'),
            ],
          ),
          const SizedBox(height: 16),

          // Gráfica de área ondulada suave
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('18 oct', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                        if (value == 5) return const Text('28 oct', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                        if (value == 10) return const Text('07 nov', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                        if (value == 14) return const Text('16 nov', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 14,
                minY: 8000,
                maxY: 13000,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 9500),
                      FlSpot(2, 10200),
                      FlSpot(4, 9900),
                      FlSpot(6, 11400),
                      FlSpot(8, 10600),
                      FlSpot(10, 11800),
                      FlSpot(12, 11100),
                      FlSpot(14, 11320),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.azulPrimario,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
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
  final String variacion;
  final bool positiva;

  const _MiniCardKpi({
    required this.titulo,
    required this.valor,
    required this.unidad,
    required this.variacion,
    required this.positiva,
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
            style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
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
                style: const TextStyle(fontSize: 10, color: AppColors.textoSecundario),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            variacion,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: positiva ? AppColors.exito : AppColors.critico,
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
          style: const TextStyle(fontSize: 10, color: AppColors.textoSecundario),
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
