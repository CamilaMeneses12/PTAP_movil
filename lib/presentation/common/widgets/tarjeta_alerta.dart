import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/alerta_sistema_modelo.dart';

class TarjetaAlerta extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final SeveridadAlerta severidad;
  final String hora;
  final VoidCallback? alPulsar;

  const TarjetaAlerta({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.severidad,
    required this.hora,
    this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    Color colorTema;
    Color colorFondo;
    IconData icono;
    String etiqueta;

    switch (severidad) {
      case SeveridadAlerta.critica:
        colorTema = AppColors.critico;
        colorFondo = AppColors.criticoFondo;
        icono = Icons.warning_rounded;
        etiqueta = 'CRÍTICA';
        break;
      case SeveridadAlerta.advertencia:
        colorTema = AppColors.advertencia;
        colorFondo = AppColors.advertenciaFondo;
        icono = Icons.warning_amber_rounded;
        etiqueta = 'ADVERTENCIA';
        break;
      case SeveridadAlerta.informacion:
        colorTema = AppColors.informacion;
        colorFondo = AppColors.informacionFondo;
        icono = Icons.info_outline_rounded;
        etiqueta = 'INFORMACIÓN';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono con círculo de color suave
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorFondo,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icono,
                    color: colorTema,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y hora
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              titulo,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textoPrincipal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hora,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Descripción
                      Text(
                        descripcion,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textoSecundario,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Etiqueta de severidad
                      Text(
                        etiqueta,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: colorTema,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
