import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/validators/validador_rangos.dart';

class MensajeFueraDeRango extends StatelessWidget {
  final EvaluacionRango evaluacion;

  const MensajeFueraDeRango({
    super.key,
    required this.evaluacion,
  });

  @override
  Widget build(BuildContext context) {
    if (evaluacion.cumple) {
      return const SizedBox.shrink();
    }

    final esCritico = evaluacion.esCritico || evaluacion.tipo == 'invalido';
    final colorBorde = esCritico ? AppColors.critico : AppColors.advertencia;
    final colorFondo = esCritico ? AppColors.criticoFondo : AppColors.advertenciaFondo;
    final colorTexto = esCritico ? AppColors.critico : AppColors.advertencia;
    final icono = esCritico ? Icons.error_outline_rounded : Icons.warning_amber_rounded;

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorBorde, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: colorTexto),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  esCritico ? '¡Alerta Crítica!' : '¡Advertencia Operativa!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  evaluacion.mensajeCompleto.isNotEmpty
                      ? evaluacion.mensajeCompleto
                      : (evaluacion.mensajeAlerta ?? 'Valor fuera de rango'),
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: colorTexto,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta sutil debajo de cada campo indicando el rango permitido
class IndicadorRangoPermitido extends StatelessWidget {
  final String textoRango;

  const IndicadorRangoPermitido({
    super.key,
    required this.textoRango,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        'Rango permitido: $textoRango',
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textoSecundario,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
