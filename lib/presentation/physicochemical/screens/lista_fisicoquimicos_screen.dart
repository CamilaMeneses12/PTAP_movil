import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/app_drawer.dart';
import '../providers/fisicoquimico_provider.dart';

class ListaFisicoquimicosScreen extends StatelessWidget {
  const ListaFisicoquimicosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<SesionUsuarioProvider>();
    final fisicoquimicoProvider = context.watch<FisicoquimicoProvider>();
    final registros = fisicoquimicoProvider.registros;
    final puedeRegistrar = authProvider.perfil?.puedeEditar ?? false;

    final formatoFecha = DateFormat('dd/MM/yyyy', 'es_ES');

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      drawer: const AppDrawer(rutaActual: AppRoutes.fisicoquimicos),
      appBar: AppBar(
        title: const Text(AppStrings.moduloFisicoquimicos),
      ),
      body: SafeArea(
        child: fisicoquimicoProvider.cargando && registros.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => fisicoquimicoProvider.cargarRegistros(),
                child: registros.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 60),
                          Icon(
                            Icons.science_outlined,
                            size: 72,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay registros fisicoquímicos aún.',
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
                                ? 'Presiona el botón (+) para diligenciar el formato DO-F-070.'
                                : 'Actualmente no hay mediciones para consultar.',
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
                        itemCount: registros.length,
                        itemBuilder: (context, index) {
                          final reg = registros[index];
                          final fueraDeRango = reg.fueraDeRango;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: fueraDeRango
                                    ? AppColors.alerta
                                    : const Color(0xFFE0E0E0),
                                width: fueraDeRango ? 1.5 : 0.8,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                context.push(
                                  AppRoutes.fisicoquimicoDetalle,
                                  extra: reg,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Encabezado tarjeta
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
                                              formatoFecha.format(reg.fecha),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppColors.textoPrincipal,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              reg.hora,
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
                                            color: fueraDeRango
                                                ? AppColors.alertaFondo
                                                : AppColors.senaVerde.withAlpha(25),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: fueraDeRango
                                                  ? AppColors.alerta
                                                  : AppColors.senaVerde,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                fueraDeRango
                                                    ? Icons.warning_amber_rounded
                                                    : Icons.check_circle_outline,
                                                size: 13,
                                                color: fueraDeRango
                                                    ? AppColors.alerta
                                                    : AppColors.senaVerde,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                fueraDeRango
                                                    ? 'Fuera de Rango'
                                                    : 'Conforme',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: fueraDeRango
                                                      ? AppColors.alerta
                                                      : AppColors.senaVerde,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),

                                    // Parámetros principales medidos
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _DatoResumen(
                                          etiqueta: 'Cloro Clorada',
                                          valor: reg.cloradaCloroResidual != null
                                              ? '${reg.cloradaCloroResidual} mg/L'
                                              : '-',
                                          alerta: reg.cloradaCloroResidual != null &&
                                              (reg.cloradaCloroResidual! < 0.3 ||
                                                  reg.cloradaCloroResidual! > 2.0),
                                        ),
                                        _DatoResumen(
                                          etiqueta: 'pH Clorada',
                                          valor: reg.cloradaPh != null
                                              ? '${reg.cloradaPh}'
                                              : '-',
                                          alerta: reg.cloradaPh != null &&
                                              (reg.cloradaPh! < 6.5 ||
                                                  reg.cloradaPh! > 9.0),
                                        ),
                                        _DatoResumen(
                                          etiqueta: 'Turbidez Clorada',
                                          valor: reg.cloradaTurbidez != null
                                              ? '${reg.cloradaTurbidez} NTU'
                                              : '-',
                                          alerta: reg.cloradaTurbidez != null &&
                                              reg.cloradaTurbidez! > 2.0,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Responsable y puntos de red
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Resp: ${reg.responsableNombre}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textoSecundario,
                                          ),
                                        ),
                                        Text(
                                          '${reg.puntosControl.length} puntos de red',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.senaAzul,
                                            fontWeight: FontWeight.w600,
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
              label: const Text('Nuevo Registro'),
              onPressed: () => context.push(AppRoutes.fisicoquimicoNuevo),
            )
          : null,
    );
  }
}

class _DatoResumen extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool alerta;

  const _DatoResumen({
    required this.etiqueta,
    required this.valor,
    required this.alerta,
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
            color: alerta ? AppColors.alerta : AppColors.textoPrincipal,
          ),
        ),
      ],
    );
  }
}
