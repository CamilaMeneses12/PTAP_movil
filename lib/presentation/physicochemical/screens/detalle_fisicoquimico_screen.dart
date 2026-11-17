import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/registro_fisicoquimico.dart';

class DetalleFisicoquimicoScreen extends StatelessWidget {
  final RegistroFisicoquimico registro;

  const DetalleFisicoquimicoScreen({
    super.key,
    required this.registro,
  });

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final fueraDeRango = registro.fueraDeRango;

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        title: const Text('Detalle Muestreo DO-F-070'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Banner de conformidad
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: fueraDeRango
                    ? AppColors.alertaFondo
                    : AppColors.senaVerde.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: fueraDeRango ? AppColors.alerta : AppColors.senaVerde,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    fueraDeRango
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color: fueraDeRango ? AppColors.alerta : AppColors.senaVerde,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fueraDeRango
                              ? 'Registro con Parámetros Fuera de Rango'
                              : 'Parámetros Conformes con Res. 2115/2007',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: fueraDeRango
                                ? AppColors.alerta
                                : AppColors.senaVerde,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fecha: ${formatoFecha.format(registro.fecha)} - Hora: ${registro.hora}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta 1: Información Institucional
            _SeccionDetalle(
              titulo: 'Información Institucional',
              icono: Icons.apartment,
              items: [
                _ItemFila('Regional:', registro.regional),
                _ItemFila('Centro de Formación:', registro.centroFormacion),
                _ItemFila('Sede:', registro.sede),
                _ItemFila('Responsable:', registro.responsableNombre),
              ],
            ),
            const SizedBox(height: 14),

            // Tarjeta 2: Agua Cruda
            _SeccionDetalle(
              titulo: 'Agua Cruda (Entrada)',
              icono: Icons.waves,
              items: [
                _ItemFila('Caudal de Entrada:',
                    registro.crudaCaudalEntrada != null ? '${registro.crudaCaudalEntrada} L/s' : 'N/R'),
                _ItemFila('pH (5.0 - 9.0):',
                    registro.crudaPh != null ? '${registro.crudaPh}' : 'N/R'),
                _ItemFila('Turbidez entrada (máx 10 UJT):',
                    registro.crudaTurbidez != null ? '${registro.crudaTurbidez} UJT' : 'N/R'),
                _ItemFila('Color (máx 20 UPC):',
                    registro.crudaColor != null ? '${registro.crudaColor} UPC' : 'N/R'),
                _ItemFila('Dureza:',
                    registro.crudaDureza != null ? '${registro.crudaDureza} mg/L CaCO₃' : 'N/R'),
                _ItemFila('Dosis de coagulante:', registro.crudaDosisCoagulante ?? 'N/R'),
              ],
            ),
            const SizedBox(height: 14),

            // Tarjeta 3: Agua Filtrada
            _SeccionDetalle(
              titulo: 'Agua Filtrada',
              icono: Icons.filter_alt_outlined,
              items: [
                _ItemFila('Turbidez (0.0 - 2.0 NTU):',
                    registro.filtradaTurbidez != null ? '${registro.filtradaTurbidez} NTU' : 'N/R'),
                _ItemFila('pH (6.5 - 9.0):',
                    registro.filtradaPh != null ? '${registro.filtradaPh}' : 'N/R'),
              ],
            ),
            const SizedBox(height: 14),

            // Tarjeta 4: Agua Clorada
            _SeccionDetalle(
              titulo: 'Agua Clorada (Salida PTAP)',
              icono: Icons.sanitizer_outlined,
              items: [
                _ItemFila('Turbidez (0.0 - 2.0 NTU):',
                    registro.cloradaTurbidez != null ? '${registro.cloradaTurbidez} NTU' : 'N/R'),
                _ItemFila('pH (6.5 - 9.0):',
                    registro.cloradaPh != null ? '${registro.cloradaPh}' : 'N/R'),
                _ItemFila('Color Aparente (máx 15 UPC):',
                    registro.cloradaColorAparente != null ? '${registro.cloradaColorAparente} UPC' : 'N/R'),
                _ItemFila('Cloro Residual Libre (0.3 - 2.0 mg/L):',
                    registro.cloradaCloroResidual != null ? '${registro.cloradaCloroResidual} mg/L' : 'N/R'),
              ],
            ),
            const SizedBox(height: 14),

            // Tarjeta 5: Puntos de Control en Red
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.location_on_outlined, color: AppColors.senaAzul, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Puntos de Control en Red',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.senaAzul,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    if (registro.puntosControl.isEmpty)
                      const Text(
                        'No se registraron puntos de red en esta toma.',
                        style: TextStyle(fontSize: 13, color: AppColors.textoSecundario),
                      )
                    else
                      ...registro.puntosControl.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: p.fueraDeRango
                                    ? AppColors.alertaFondo
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: p.fueraDeRango
                                      ? AppColors.alerta
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.areaNombre,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'pH: ${p.ph ?? "-"} | Turbidez: ${p.turbidez ?? "-"} NTU | Color: ${p.colorAparente ?? "-"} UPC | Cloro: ${p.cloroResidual ?? "-"} mg/L',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tarjeta 6: Observaciones
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.comment_outlined, color: AppColors.senaAzul, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Observaciones Registradas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.senaAzul,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    Text(
                      registro.observaciones?.isNotEmpty == true
                          ? registro.observaciones!
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

class _SeccionDetalle extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<_ItemFila> items;

  const _SeccionDetalle({
    required this.titulo,
    required this.icono,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: AppColors.senaAzul, size: 20),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.senaAzul,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            ...items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        it.titulo,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                      Text(
                        it.valor,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ItemFila {
  final String titulo;
  final String valor;
  _ItemFila(this.titulo, this.valor);
}
