import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BarraNavegacionInferior extends StatelessWidget {
  final int indiceActual;
  final ValueChanged<int> alSeleccionar;

  const BarraNavegacionInferior({
    super.key,
    required this.indiceActual,
    required this.alSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanco,
        border: const Border(
          top: BorderSide(color: AppColors.bordes, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.azulMarino.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _ElementoNav(
                indice: 0,
                indiceActual: indiceActual,
                etiqueta: 'Inicio',
                icono: Icons.home_outlined,
                iconoActivo: Icons.home_rounded,
                alPulsar: () => alSeleccionar(0),
              ),
              _ElementoNav(
                indice: 1,
                indiceActual: indiceActual,
                etiqueta: 'Monitoreo',
                icono: Icons.show_chart_rounded,
                iconoActivo: Icons.show_chart_rounded,
                alPulsar: () => alSeleccionar(1),
              ),
              _ElementoNav(
                indice: 2,
                indiceActual: indiceActual,
                etiqueta: 'Estadísticas',
                icono: Icons.bar_chart_rounded,
                iconoActivo: Icons.bar_chart_rounded,
                alPulsar: () => alSeleccionar(2),
              ),
              _ElementoNav(
                indice: 3,
                indiceActual: indiceActual,
                etiqueta: 'Registros',
                icono: Icons.description_outlined,
                iconoActivo: Icons.description_rounded,
                alPulsar: () => alSeleccionar(3),
              ),
              _ElementoNav(
                indice: 4,
                indiceActual: indiceActual,
                etiqueta: 'Perfil',
                icono: Icons.person_outline_rounded,
                iconoActivo: Icons.person_rounded,
                alPulsar: () => alSeleccionar(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ElementoNav extends StatelessWidget {
  final int indice;
  final int indiceActual;
  final String etiqueta;
  final IconData icono;
  final IconData iconoActivo;
  final VoidCallback alPulsar;

  const _ElementoNav({
    required this.indice,
    required this.indiceActual,
    required this.etiqueta,
    required this.icono,
    required this.iconoActivo,
    required this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    final estaActivo = indice == indiceActual;

    return Expanded(
      child: InkWell(
        onTap: alPulsar,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: estaActivo ? AppColors.azulClaro : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                estaActivo ? iconoActivo : icono,
                size: 22,
                color: estaActivo ? AppColors.azulMarino : AppColors.textoSecundario,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              style: TextStyle(
                fontSize: 11,
                fontWeight: estaActivo ? FontWeight.w700 : FontWeight.w500,
                color: estaActivo ? AppColors.azulMarino : AppColors.textoSecundario,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Container(
              height: 3,
              width: estaActivo ? 28 : 0,
              decoration: BoxDecoration(
                color: estaActivo ? AppColors.azulMarino : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
