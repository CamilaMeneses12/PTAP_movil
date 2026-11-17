import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/medidores_modelos.dart';

class DetalleJornadaMedidoresScreen extends StatelessWidget {
  final JornadaMedidores jornada;

  const DetalleJornadaMedidoresScreen({
    super.key,
    required this.jornada,
  });

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final perdida = jornada.aguaNoRegistrada;
    final perdidaAlta = perdida > 5.0;

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        title: const Text('Detalle de Medidores'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Cabecera de la jornada
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fecha: ${formatoFecha.format(jornada.fecha)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                        Text(
                          'Hora: ${jornada.hora}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Responsable de lectura: ${jornada.responsableLectura}',
                      style: const TextStyle(fontSize: 13, color: AppColors.senaAzul),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tarjeta de Balance Hídrico
            Card(
              color: AppColors.senaAzul.withAlpha(15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.aguaPrimario, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.pie_chart_outline, color: AppColors.aguaPrimario),
                        SizedBox(width: 8),
                        Text(
                          'Balance Hídrico del Día',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.senaAzul,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _FilaBalance(
                      etiqueta: 'Consumo Macro Medidor:',
                      valor: '${jornada.consumoMacromedidor.toStringAsFixed(4)} m³',
                      color: AppColors.senaAzul,
                    ),
                    const SizedBox(height: 6),
                    _FilaBalance(
                      etiqueta: 'Consumo Total Micromedidores (8):',
                      valor: '${jornada.consumoTotalMicros.toStringAsFixed(4)} m³',
                      color: AppColors.aguaPrimario,
                    ),
                    const SizedBox(height: 6),
                    _FilaBalance(
                      etiqueta: 'Agua en Pérdida o No Registrada:',
                      valor: '${jornada.aguaNoRegistrada.toStringAsFixed(4)} m³',
                      color: perdidaAlta ? AppColors.alerta : AppColors.exito,
                      resaltar: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tabla de lecturas detalladas de los 9 medidores
            const Text(
              'Lecturas por Medidor (Formato Excel)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textoPrincipal,
              ),
            ),
            const SizedBox(height: 10),

            Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.senaAzul.withAlpha(20),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Medidor',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Lectura Anterior (m³)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Lectura Actual (m³)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Consumo (m³)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: jornada.lecturas.map((l) {
                    final esMacro = l.tipoMedidor == 'macromedidor';
                    return DataRow(
                      color: esMacro
                          ? WidgetStateProperty.all(AppColors.senaVerde.withAlpha(20))
                          : null,
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                esMacro ? Icons.speed : Icons.water_drop_outlined,
                                size: 16,
                                color: esMacro ? AppColors.senaAzul : AppColors.aguaPrimario,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l.medidorNombre,
                                style: TextStyle(
                                  fontWeight: esMacro ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(l.lecturaAnterior.toStringAsFixed(4))),
                        DataCell(Text(l.lecturaActual.toStringAsFixed(4))),
                        DataCell(
                          Text(
                            l.consumo.toStringAsFixed(4),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: esMacro ? AppColors.senaAzul : AppColors.textoPrincipal,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Observaciones
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observaciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.senaAzul,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      jornada.observaciones?.isNotEmpty == true
                          ? jornada.observaciones!
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

class _FilaBalance extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color color;
  final bool resaltar;

  const _FilaBalance({
    required this.etiqueta,
    required this.valor,
    required this.color,
    this.resaltar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            fontSize: 13,
            fontWeight: resaltar ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textoPrincipal,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
