import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TarjetaKpi extends StatelessWidget {
  final String titulo;
  final String valor;
  final String unidad;
  final IconData icono;
  final String? variacion;
  final bool? variacionPositiva;
  final String? notaRango;
  final VoidCallback? alPulsar;

  const TarjetaKpi({
    super.key,
    required this.titulo,
    required this.valor,
    required this.unidad,
    required this.icono,
    this.variacion,
    this.variacionPositiva,
    this.notaRango,
    this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordes, width: 1.0),
        boxShadow: AppColors.sombraSuave,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: alPulsar,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Fila superior: Icono + Chip de variación
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.azulClaro,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icono,
                        color: AppColors.azulPrimario,
                        size: 19,
                      ),
                    ),
                    if (variacion != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: (variacionPositiva ?? true)
                              ? AppColors.exitoFondo
                              : AppColors.criticoFondo,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (variacionPositiva ?? true)
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 12,
                              color: (variacionPositiva ?? true)
                                  ? AppColors.exito
                                  : AppColors.critico,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              variacion!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: (variacionPositiva ?? true)
                                    ? AppColors.exito
                                    : AppColors.critico,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Título
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textoSecundario,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Valor grande + unidad
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      valor,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoPrincipal,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unidad,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ],
                ),

                // Nota rango
                if (notaRango != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    notaRango!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textoSecundario,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
