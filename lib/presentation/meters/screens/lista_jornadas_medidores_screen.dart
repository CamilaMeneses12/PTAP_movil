import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/medidores_provider.dart';

class ListaJornadasMedidoresScreen extends StatelessWidget {
  const ListaJornadasMedidoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<SesionUsuarioProvider>();
    final medidoresProvider = context.watch<MedidoresProvider>();
    final jornadas = medidoresProvider.jornadas;
    final puedeRegistrar = authProvider.perfil?.puedeEditar ?? false;

    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textoPrincipal),
          onPressed: () => context.pop(),
        ),
        title: const Text(AppStrings.moduloMedidores),
      ),
      body: SafeArea(
        child: medidoresProvider.cargando && jornadas.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => medidoresProvider.cargarJornadas(),
                child: jornadas.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 60),
                          Icon(
                            Icons.speed_outlined,
                            size: 72,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay jornadas de medidores registradas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textoSecundario,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            puedeRegistrar
                                ? 'Presiona el botón (+) para ingresar las lecturas de los medidores.'
                                : 'Actualmente no hay jornadas disponibles para consultar.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textoSecundario,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: jornadas.length,
                        itemBuilder: (context, index) {
                          final j = jornadas[index];
                          final perdida = j.aguaNoRegistrada;
                          final perdidaAlta = perdida > 5.0; // Alerta de pérdida considerable

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                context.push(
                                  AppRoutes.medidoresDetalle,
                                  extra: j,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Encabezado
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_outlined,
                                              size: 16,
                                              color: AppColors.senaAzul,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              formatoFecha.format(j.fecha),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppColors.textoPrincipal,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              j.hora,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textoSecundario,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: perdidaAlta
                                                ? AppColors.alertaFondo
                                                : AppColors.senaVerde.withAlpha(20),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: perdidaAlta
                                                  ? AppColors.alerta
                                                  : AppColors.senaVerde,
                                            ),
                                          ),
                                          child: Text(
                                            'Pérdida: ${perdida.toStringAsFixed(2)} m³',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: perdidaAlta
                                                  ? AppColors.alerta
                                                  : AppColors.senaVerde,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),

                                    // Balances
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _DatoConsumo(
                                          etiqueta: 'Macro Medidor',
                                          valor: '${j.consumoMacromedidor.toStringAsFixed(2)} m³',
                                          color: AppColors.senaAzul,
                                        ),
                                        _DatoConsumo(
                                          etiqueta: 'Total Micros (8)',
                                          valor: '${j.consumoTotalMicros.toStringAsFixed(2)} m³',
                                          color: AppColors.aguaPrimario,
                                        ),
                                        _DatoConsumo(
                                          etiqueta: 'No Registrada',
                                          valor: '${j.aguaNoRegistrada.toStringAsFixed(2)} m³',
                                          color: perdidaAlta ? AppColors.alerta : AppColors.exito,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Pie de tarjeta
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Lector: ${j.responsableLectura}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textoSecundario,
                                          ),
                                        ),
                                        Text(
                                          '${j.lecturas.length} medidores',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.senaVerde,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
      floatingActionButton: puedeRegistrar
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.senaVerde,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nueva Lectura'),
              onPressed: () => context.push(AppRoutes.medidoresNuevo),
            )
          : null,
    );
  }
}

class _DatoConsumo extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color color;

  const _DatoConsumo({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
        ),
        const SizedBox(height: 2),
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
