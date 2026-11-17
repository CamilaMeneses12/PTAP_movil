import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Banner institucional moderno con bienvenida personalizada y dibujo oficial
class BannerBienvenida extends StatelessWidget {
  final String nombreUsuario;
  final String rolTexto;
  final Color rolColor;
  final String subtitulo;

  const BannerBienvenida({
    super.key,
    required this.nombreUsuario,
    required this.rolTexto,
    required this.rolColor,
    this.subtitulo = 'Centro de los Recursos Naturales Renovables La Salada',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.gradienteAzul,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.sombraElevada,
      ),
      child: Stack(
        children: [
          // Patrón visual decorativo de ondas de agua de fondo
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.water,
                size: 160,
                color: Colors.white,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(60)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: rolColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              rolTexto,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blanco,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Bienvenido,\n$nombreUsuario',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blanco,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withAlpha(210),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Imagen dibujo_app integrada con alta fidelidad y bordes redondeados
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'imagenes/dibujo_app.jpeg',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.azulClaro,
                      child: const Icon(Icons.water_drop, size: 40, color: AppColors.azulInstitucional),
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
}
