import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FilaRegistro extends StatelessWidget {
  final String fecha;
  final String hora;
  final String entrada;
  final String salida;
  final String volumen;
  final bool fueraDeRango;
  final String? mensajeExplicativo;
  final VoidCallback? alPulsar;

  const FilaRegistro({
    super.key,
    required this.fecha,
    required this.hora,
    required this.entrada,
    required this.salida,
    required this.volumen,
    this.fueraDeRango = false,
    this.mensajeExplicativo,
    this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    final colorTexto = fueraDeRango ? AppColors.critico : AppColors.textoPrincipal;
    final colorSubtexto = fueraDeRango ? AppColors.critico.withAlpha(200) : AppColors.textoSecundario;
    final colorFondo = fueraDeRango ? AppColors.criticoFondo : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: colorFondo,
        border: const Border(
          bottom: BorderSide(color: AppColors.bordes, width: 0.8),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (alPulsar != null) {
              alPulsar!();
            } else if (fueraDeRango && mensajeExplicativo != null) {
              _mostrarDetalleFueraDeRango(context);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Columna Fecha / Hora
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fecha,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: fueraDeRango ? FontWeight.w700 : FontWeight.w600,
                          color: colorTexto,
                        ),
                      ),
                      Text(
                        hora,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorSubtexto,
                        ),
                      ),
                    ],
                  ),
                ),

                // Entrada
                Expanded(
                  flex: 2,
                  child: Text(
                    entrada,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: fueraDeRango ? FontWeight.w700 : FontWeight.w500,
                      color: colorTexto,
                    ),
                  ),
                ),

                // Salida
                Expanded(
                  flex: 2,
                  child: Text(
                    salida,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: fueraDeRango ? FontWeight.w700 : FontWeight.w500,
                      color: colorTexto,
                    ),
                  ),
                ),

                // Volumen
                Expanded(
                  flex: 2,
                  child: Text(
                    volumen,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: fueraDeRango ? FontWeight.w700 : FontWeight.w500,
                      color: colorTexto,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleFueraDeRango(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.blanco,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.criticoFondo,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_rounded, color: AppColors.critico, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Registro con Parámetro Fuera de Rango',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Fecha: $fecha - Hora: $hora',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textoSecundario,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.criticoFondo,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.critico.withAlpha(80)),
              ),
              child: Text(
                mensajeExplicativo ?? 'Uno o más parámetros superaron los límites normativos permitidos.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.critico,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
