import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Tarjeta estadística moderna, uniforme y adaptable para mostrar métricas e indicadores de la PTAP.
/// Diseñada con contenido distribuido hacia el lado izquierdo (icono, título, valor y subtítulo),
/// manteniendo dimensiones uniformes, simetría y cero errores de overflow.
class TarjetaMetrica extends StatelessWidget {
  final String titulo;
  final String valor;
  final String? subtitulo;
  final IconData icono;
  final Color color;
  final VoidCallback? onTap;

  const TarjetaMetrica({
    super.key,
    required this.titulo,
    required this.valor,
    this.subtitulo,
    required this.icono,
    this.color = AppColors.azulTecnologico,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.bordes, width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Icono o imagen institucional alineado hacia la izquierda
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              const SizedBox(height: 8),

              // 2. Título de la tarjeta alineado hacia la izquierda
              Text(
                titulo,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoSecundario,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),

              // 3. Valor numérico o estado alineado hacia la izquierda
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  valor,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoPrincipal,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              // 4. Subtítulo complementario alineado hacia la izquierda
              if (subtitulo != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitulo!,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
