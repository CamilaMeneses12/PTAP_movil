import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/aforo_caudal_modelo.dart';

class DetalleAforoCaudalScreen extends StatelessWidget {
  final AforoCaudal aforo;

  const DetalleAforoCaudalScreen({
    super.key,
    required this.aforo,
  });

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        title: const Text('Detalle de Aforo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Cabecera con resultado principal
            Card(
              color: AppColors.senaAzul.withAlpha(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.senaAzul, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Caudal de la Quebrada La Seca',
                      style: TextStyle(fontSize: 13, color: AppColors.textoSecundario),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${aforo.caudalLS.toStringAsFixed(2)} L/s',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.senaAzul,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${aforo.caudalM3H.toStringAsFixed(2)} m³/h  •  ${aforo.caudalLH.toStringAsFixed(0)} L/h',
                      style: const TextStyle(fontSize: 13, color: AppColors.textoSecundario),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fecha: ${formatoFecha.format(aforo.fecha)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Hora: ${aforo.hora}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Memoria de cálculo 1: Sección
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.straighten, color: AppColors.senaAzul, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '1. Geometría de la Sección',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.senaAzul,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _FilaDato('Ancho del cauce (m):', '${aforo.anchoCauceM} m'),
                    _FilaDato(
                      'Profundidades (p1, p2, p3, p4):',
                      '${aforo.profundidad1M}, ${aforo.profundidad2M}, ${aforo.profundidad3M}, ${aforo.profundidad4M} m',
                    ),
                    _FilaDato(
                      'Profundidad promedio (m):',
                      '${aforo.profundidadPromedioM.toStringAsFixed(4)} m',
                    ),
                    _FilaDato(
                      'Área sección transversal (m²):',
                      '${aforo.areaSeccionM2.toStringAsFixed(4)} m²',
                      resaltar: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Memoria de cálculo 2: Velocidad
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.timer_outlined, color: AppColors.senaAzul, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '2. Velocidad del Flotador',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.senaAzul,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _FilaDato('Distancia recorrida:', '${aforo.distanciaFlotadorM} m'),
                    _FilaDato(
                      'Tiempos (t1, t2, t3, t4):',
                      '${aforo.tiempo1S}, ${aforo.tiempo2S}, ${aforo.tiempo3S}, ${aforo.tiempo4S} s',
                    ),
                    _FilaDato('Tiempo promedio:', '${aforo.tiempoPromedioS.toStringAsFixed(4)} s'),
                    _FilaDato(
                      'Velocidad superficial:',
                      '${aforo.velocidadSuperficialMS.toStringAsFixed(4)} m/s',
                    ),
                    _FilaDato('Factor de corrección:', '${aforo.factorCorreccion}'),
                    _FilaDato(
                      'Velocidad corregida:',
                      '${aforo.velocidadCorregidaMS.toStringAsFixed(4)} m/s',
                      resaltar: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Observaciones
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observaciones del Aforo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.senaAzul,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      aforo.observaciones?.isNotEmpty == true
                          ? aforo.observaciones!
                          : 'Sin observaciones adicionales.',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool resaltar;

  const _FilaDato(this.etiqueta, this.valor, {this.resaltar = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: const TextStyle(fontSize: 13, color: AppColors.textoSecundario)),
          Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: resaltar ? FontWeight.bold : FontWeight.w600,
              color: resaltar ? AppColors.senaAzul : AppColors.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}
