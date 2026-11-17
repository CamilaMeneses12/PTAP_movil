import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';

/// Dashboard de módulos
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<SesionUsuarioProvider>();
    final perfil = authProvider.perfil;
    final puedeRegistrar = perfil?.puedeEditar ?? false;
    final esAdmin = perfil?.esAdministrador ?? false;

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textoPrincipal),
          onPressed: () => context.pop(),
        ),
        title: const Text('Dashboard de Módulos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera descriptiva del Dashboard
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blanco,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.bordes),
                boxShadow: AppColors.sombraSuave,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.azulClaro,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.apps, color: AppColors.azulInstitucional, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Módulos del Sistema',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          esAdmin
                              ? 'Acceso total como Administrador (6 módulos)'
                              : puedeRegistrar
                                  ? 'Módulos operativos de captura y balance'
                                  : 'Módulos de auditoría y consulta (SIGA)',
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
            const SizedBox(height: 18),

            // Cuadrícula de tarjetas de módulos autorizados
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.05,
              children: [
                // 1. Módulo Parámetros Fisicoquímicos (DO-F-070)
                _TarjetaModuloModerna(
                  titulo: AppStrings.moduloFisicoquimicos,
                  descripcion: puedeRegistrar
                      ? 'pH, Cloro, Turbidez y Color'
                      : 'Auditoría calidad DO-F-070',
                  icono: Icons.science_outlined,
                  colorIcono: AppColors.turquesa,
                  onTap: () => context.push(AppRoutes.fisicoquimicos),
                ),

                // 2. Módulo Lectura de Medidores
                _TarjetaModuloModerna(
                  titulo: AppStrings.moduloMedidores,
                  descripcion: puedeRegistrar
                      ? 'Lecturas, consumos y balance'
                      : 'Consulta balance hídrico',
                  icono: Icons.speed_outlined,
                  colorIcono: AppColors.azulInstitucional,
                  onTap: () => context.push(AppRoutes.medidores),
                ),

                // 3. Módulo Caudal Quebrada La Seca
                _TarjetaModuloModerna(
                  titulo: AppStrings.moduloCaudal,
                  descripcion: puedeRegistrar
                      ? 'Aforo por flotador y gráficas'
                      : 'Histórico y análisis de aforos',
                  icono: Icons.water_outlined,
                  colorIcono: AppColors.azulTecnologico,
                  onTap: () => context.push(AppRoutes.caudal),
                ),

                // 4. Módulo Historial y Filtros
                _TarjetaModuloModerna(
                  titulo: AppStrings.moduloHistorial,
                  descripcion: 'Búsqueda por fecha, módulo y operario',
                  icono: Icons.history_outlined,
                  colorIcono: AppColors.azulInstitucional,
                  onTap: () => context.push(AppRoutes.historial),
                ),

                // 5. Módulo Exportar Reportes (PDF / Excel)
                _TarjetaModuloModerna(
                  titulo: AppStrings.moduloExportar,
                  descripcion: 'Formatos oficiales DO-F-070 y Caudal',
                  icono: Icons.file_download_outlined,
                  colorIcono: AppColors.azulTecnologico,
                  onTap: () => context.push(AppRoutes.exportar),
                ),

                // 6. Módulo Administración (Solo Administrador)
                if (esAdmin)
                  _TarjetaModuloModerna(
                    titulo: AppStrings.moduloAdmin,
                    descripcion: 'Usuarios, medidores y rangos',
                    icono: Icons.admin_panel_settings_outlined,
                    colorIcono: AppColors.azulMarino,
                    onTap: () => context.push(AppRoutes.admin),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaModuloModerna extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color colorIcono;
  final VoidCallback onTap;

  const _TarjetaModuloModerna({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.colorIcono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.bordes, width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.blanco,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.sombraSuave,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorIcono.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icono, color: colorIcono, size: 24),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textoPrincipal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textoSecundario,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
