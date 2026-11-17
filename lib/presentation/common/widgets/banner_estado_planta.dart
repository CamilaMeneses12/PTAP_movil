import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'chip_estado.dart';

class BannerEstadoPlanta extends StatelessWidget {
  final TipoEstadoPlanta estado;
  final String? horaActualizacion;
  final String? titulo;
  final String? descripcion;
  final String eficiencia;
  final String turbidez;
  final String cloro;

  const BannerEstadoPlanta({
    super.key,
    required this.estado,
    this.horaActualizacion,
    this.titulo,
    this.descripcion,
    this.eficiencia = '95,6 %',
    this.turbidez = '0,42 NTU',
    this.cloro = '1,1 mg/L',
  });

  @override
  Widget build(BuildContext context) {
    String tituloDefecto;
    String descDefecto;

    switch (estado) {
      case TipoEstadoPlanta.operativa:
        tituloDefecto = 'Planta operativa';
        descDefecto = 'Todos los procesos operan dentro de los rangos normales.';
        break;
      case TipoEstadoPlanta.mantenimiento:
        tituloDefecto = 'Mantenimiento en curso';
        descDefecto = 'Filtro 3 en retrolavado. Capacidad de tratamiento al 85%.';
        break;
      case TipoEstadoPlanta.enAlerta:
        tituloDefecto = 'Planta en alerta';
        descDefecto = '1 alerta crítica requiere atención inmediata del operador.';
        break;
    }

    final hora = horaActualizacion ?? '09:41';
    final tit = titulo ?? tituloDefecto;
    final desc = descripcion ?? descDefecto;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.azulMarino,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.sombraElevada,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Ondas decorativas de agua en el fondo
            Positioned.fill(
              child: CustomPaint(
                painter: _OndasBannerPainter(),
              ),
            ),

            // Contenido del banner
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior: Chip de estado + Hora
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ChipEstado(estado: estado),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: Colors.white.withAlpha(180),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Actualizado $hora',
                            style: TextStyle(
                              color: Colors.white.withAlpha(190),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Título principal
                  Text(
                    tit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Descripción
                  Text(
                    desc,
                    style: TextStyle(
                      color: Colors.white.withAlpha(210),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Mini KPIs inferiores en contenedor translúcido
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(28),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withAlpha(35),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MiniKpi(label: 'Eficiencia', valor: eficiencia),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withAlpha(40),
                        ),
                        _MiniKpi(label: 'Turbidez', valor: turbidez),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withAlpha(40),
                        ),
                        _MiniKpi(label: 'Cloro res.', valor: cloro),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final String label;
  final String valor;

  const _MiniKpi({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _OndasBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF14B8A6).withAlpha(30)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.55,
        size.width * 0.7,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.85,
        size.width,
        size.height * 0.8,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFF1565C0).withAlpha(45)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.95,
        size.width,
        size.height * 0.7,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
