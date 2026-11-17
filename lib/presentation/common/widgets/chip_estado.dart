import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum TipoEstadoPlanta {
  operativa,
  mantenimiento,
  enAlerta,
}

class ChipEstado extends StatelessWidget {
  final TipoEstadoPlanta estado;
  final String? textoPersonalizado;
  final bool compacto;

  const ChipEstado({
    super.key,
    required this.estado,
    this.textoPersonalizado,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    Color colorPunto;
    Color colorFondo;
    Color colorTexto;
    String textoDefecto;

    switch (estado) {
      case TipoEstadoPlanta.operativa:
        colorPunto = AppColors.turquesa;
        colorFondo = AppColors.turquesaFondo;
        colorTexto = const Color(0xFF0D9488);
        textoDefecto = 'Operativa';
        break;
      case TipoEstadoPlanta.mantenimiento:
        colorPunto = AppColors.advertencia;
        colorFondo = AppColors.advertenciaFondo;
        colorTexto = AppColors.advertencia;
        textoDefecto = 'Mantenimiento';
        break;
      case TipoEstadoPlanta.enAlerta:
        colorPunto = AppColors.critico;
        colorFondo = AppColors.criticoFondo;
        colorTexto = AppColors.critico;
        textoDefecto = 'En alerta';
        break;
    }

    final etiqueta = textoPersonalizado ?? textoDefecto;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 8 : 10,
        vertical: compacto ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compacto ? 6 : 7,
            height: compacto ? 6 : 7,
            decoration: BoxDecoration(
              color: colorPunto,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: compacto ? 5 : 6),
          Text(
            etiqueta,
            style: TextStyle(
              color: colorTexto,
              fontSize: compacto ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
