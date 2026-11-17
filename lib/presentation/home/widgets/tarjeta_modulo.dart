import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TarjetaModulo extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color colorIcono;
  final VoidCallback onTap;

  const TarjetaModulo({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.colorIcono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: colorIcono.withAlpha(40),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorIcono.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: colorIcono, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
