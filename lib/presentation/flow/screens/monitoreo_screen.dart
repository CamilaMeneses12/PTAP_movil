import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../common/widgets/chip_estado.dart';

class MonitoreoScreen extends StatefulWidget {
  const MonitoreoScreen({super.key});

  @override
  State<MonitoreoScreen> createState() => _MonitoreoScreenState();
}

class _MonitoreoScreenState extends State<MonitoreoScreen> {
  int _indiceSubpestana = 0; // 0: Caudal, 1: Presión, 2: Nivel

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Tiempo real · Actualizado 09:41',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textoSecundario,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.azulMarino, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sensores y telemetría sincronizados correctamente')),
              );
            },
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

            // Tarjeta Principal: Caudal entrada vs salida (últimas 24h)
            _construirTarjetaGraficaCaudal(),

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
              detalle: 'Caudal 128,4 L/s',
              estado: TipoEstadoPlanta.operativa,
            ),
            _ItemEtapaProceso(
              numero: '2',
              nombre: 'Coagulación y floculación',
              detalle: 'Dosis de coagulante 18 mg/L',
              estado: TipoEstadoPlanta.operativa,
            ),
            _ItemEtapaProceso(
              numero: '3',
              nombre: 'Sedimentación',
              detalle: 'Turbidez 3,2 NTU',
              estado: TipoEstadoPlanta.operativa,
            ),
            _ItemEtapaProceso(
              numero: '4',
              nombre: 'Filtración',
              detalle: 'Filtro 3 en retrolavado',
              estado: TipoEstadoPlanta.mantenimiento,
            ),
            _ItemEtapaProceso(
              numero: '5',
              nombre: 'Desinfección',
              detalle: 'Cloro residual 1,1 mg/L',
              estado: TipoEstadoPlanta.operativa,
            ),
            _ItemEtapaProceso(
              numero: '6',
              nombre: 'Almacenamiento',
              detalle: 'Nivel 78 % · 1.950 m³',
              estado: TipoEstadoPlanta.operativa,
            ),

            const SizedBox(height: 16),

            // Fila de medidores y gauges (Presión de red + Nivel de tanque)
            Row(
              children: [
                Expanded(
                  child: _MedidorPresion(valorPresion: 3.4),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MedidorNivelTanque(porcentaje: 78, volumenM3: 1950),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaGraficaCaudal() {
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
          // Título de la tarjeta y estado en vivo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Caudal de entrada vs. salida',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoPrincipal,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.turquesaFondo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sensors_rounded, size: 12, color: AppColors.turquesa),
                    SizedBox(width: 3),
                    Text(
                      'En vivo',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.turquesa,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Últimas 24 h · Intervalo 1 h',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 12),

          // Valores actuales y leyenda
          Row(
            children: [
              _ItemValorCaudal(
                etiqueta: 'Entrada',
                valor: '128,4',
                unidad: 'L/s',
                colorPunto: AppColors.azulPrimario,
              ),
              const SizedBox(width: 24),
              _ItemValorCaudal(
                etiqueta: 'Salida',
                valor: '122,7',
                unidad: 'L/s',
                colorPunto: AppColors.turquesa,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Diferencia: 5,7 L/s (4,4 %) · Rango 110–140',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 16),

          // Gráfica de Líneas fl_chart con tooltip fuera de rango
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: AppColors.bordes,
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('10:00', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                          case 2:
                            return const Text('14:00', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                          case 4:
                            return const Text('18:00', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                          case 6:
                            return const Text('22:00', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                          case 8:
                            return const Text('02:00', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                          case 10:
                            return const Text('06:00', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                          case 11:
                            return const Text('Ahora', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.azulMarino));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 11,
                minY: 90,
                maxY: 155,
                lineBarsData: [
                  // Línea Entrada (Azul Primario)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 115),
                      FlSpot(2, 120),
                      FlSpot(4, 118),
                      FlSpot(6, 125),
                      FlSpot(8, 110),
                      FlSpot(9, 141.2), // Fuera de rango
                      FlSpot(10, 138),
                      FlSpot(11, 128.4),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.azulPrimario,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => spot.y > 140, // Marca el punto fuera de rango
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 5,
                        color: AppColors.critico,
                        strokeWidth: 2,
                        strokeColor: AppColors.blanco,
                      ),
                    ),
                  ),
                  // Línea Salida (Turquesa)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 110),
                      FlSpot(2, 114),
                      FlSpot(4, 112),
                      FlSpot(6, 119),
                      FlSpot(8, 106),
                      FlSpot(9, 134.6),
                      FlSpot(10, 131),
                      FlSpot(11, 122.7),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.turquesa,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Resumen min / avg / max
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.fondoGeneral,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniEstadistica(label: 'Máximo 24h', valor: '142,6 L/s', esAlerta: true),
                _MiniEstadistica(label: 'Mínimo 24h', valor: '103,1 L/s'),
                _MiniEstadistica(label: 'Promedio', valor: '124,3 L/s'),
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
              color: seleccionado ? AppColors.azulMarino : AppColors.textoSecundario,
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
          decoration: BoxDecoration(
            color: colorPunto,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          '$etiqueta ',
          style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
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
          style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
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
          style: const TextStyle(fontSize: 10, color: AppColors.textoSecundario),
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
              Icon(Icons.speed_rounded, size: 16, color: AppColors.azulPrimario),
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

  const _MedidorNivelTanque({required this.porcentaje, required this.volumenM3});

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
