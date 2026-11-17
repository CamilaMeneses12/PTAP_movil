import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/app_drawer.dart';
import '../../common/widgets/banner_bienvenida.dart';
import '../../common/widgets/tarjeta_metrica.dart';
import '../../flow/providers/caudal_provider.dart';
import '../../history/providers/historial_provider.dart';
import '../../meters/providers/medidores_provider.dart';
import '../../physicochemical/providers/fisicoquimico_provider.dart';

/// Página Principal informativa personalizada según el rol del usuario.
/// Muestra bienvenida institucional, estado del sistema, indicadores en tiempo real
/// y actividad reciente. (Las tarjetas de módulos se encuentran exclusivamente en el Dashboard).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Color _obtenerColorRol(String rol) {
    // Identidad unificada basada en referencia.png para todos los perfiles
    return AppColors.azulTecnologico;
  }

  String _obtenerTextoRol(String rol) {
    switch (rol) {
      case 'administrador':
        return 'Administrador';
      case 'operario':
        return 'Operario PTAP';
      case 'consultor_siga':
        return 'Consultor SIGA';
      default:
        return rol;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<SesionUsuarioProvider>();
    final perfil = authProvider.perfil;
    final rol = perfil?.rol ?? 'operario';
    final rolColor = _obtenerColorRol(rol);
    final rolTexto = _obtenerTextoRol(rol);

    // Datos reales de los proveedores
    final fisicoquimicoP = context.watch<FisicoquimicoProvider>();
    final medidoresP = context.watch<MedidoresProvider>();
    final caudalP = context.watch<CaudalProvider>();
    final historialP = context.watch<HistorialProvider>();
    final adminP = context.watch<AdminProvider>();

    final totalFisicoquimicos = fisicoquimicoP.registros.length;
    final totalMedidores = medidoresP.jornadas.length;
    final totalAforos = caudalP.aforos.length;
    final totalRegistros = totalFisicoquimicos + totalMedidores + totalAforos;
    final totalUsuariosActivos = adminP.usuarios.where((u) => u.activo).length;

    // Último caudal registrado
    final ultimoCaudal = caudalP.aforos.isNotEmpty
        ? '${caudalP.aforos.first.caudalLS.toStringAsFixed(1)} L/s'
        : '0.0 L/s';

    // Actividad reciente (los 5 registros más recientes del historial)
    final ultimosMovimientos = historialP.todosLosItems.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      drawer: const AppDrawer(rutaActual: AppRoutes.home),
      appBar: AppBar(
        title: const Text('PTAP'),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              tooltip: 'Módulos de la Planta',
              icon: const Icon(Icons.dashboard_customize_outlined),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          IconButton(
            tooltip: 'Mi Perfil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(AppRoutes.perfil),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            fisicoquimicoP.cargarRegistros(),
            medidoresP.cargarJornadas(),
            caudalP.cargarAforos(),
            historialP.cargarHistorial(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Bienvenida Institucional con imagen dibujo_app
              BannerBienvenida(
                nombreUsuario: perfil?.nombreCompleto ?? 'Usuario',
                rolTexto: rolTexto,
                rolColor: rolColor,
              ),
              const SizedBox(height: 18),

              // 2. Acceso destacado a Módulos del Sistema en el Menú Lateral
              Builder(
                builder: (ctx) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.azulTecnologico.withAlpha(90)),
                    boxShadow: AppColors.sombraSuave,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.azulInstitucional,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.dashboard_customize, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Módulos del Sistema',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textoPrincipal,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Abre el menú lateral para acceder a los módulos',
                              style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulInstitucional,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Ver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.menu_open, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Estado General de la Planta
              const Row(
                children: [
                  Icon(Icons.insights, size: 20, color: AppColors.azulInstitucional),
                  SizedBox(width: 8),
                  Text(
                    'Estado General de la Planta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tarjetas de Métricas Estadísticas Reales (distribución uniforme y adaptativa)
              LayoutBuilder(
                builder: (context, constraints) {
                  final esAncho = constraints.maxWidth > 580;
                  final columnas = esAncho ? 4 : 2;
                  final aspect = esAncho ? 1.15 : 1.10;

                  return GridView.count(
                    crossAxisCount: columnas,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: aspect,
                    children: [
                      TarjetaMetrica(
                        titulo: 'Total Registros',
                        valor: '$totalRegistros',
                        subtitulo: 'Consolidado PTAP',
                        icono: Icons.folder_open_outlined,
                        color: AppColors.azulInstitucional,
                        onTap: () => context.push(AppRoutes.historial),
                      ),
                      TarjetaMetrica(
                        titulo: 'Calidad Agua (DO-F-070)',
                        valor: '$totalFisicoquimicos',
                        subtitulo: 'Monitoreos',
                        icono: Icons.science_outlined,
                        color: AppColors.turquesa,
                        onTap: () => context.push(AppRoutes.fisicoquimicos),
                      ),
                      TarjetaMetrica(
                        titulo: 'Jornadas Medidores',
                        valor: '$totalMedidores',
                        subtitulo: 'Balances hídricos',
                        icono: Icons.speed_outlined,
                        color: AppColors.azulTecnologico,
                        onTap: () => context.push(AppRoutes.medidores),
                      ),
                      if (perfil?.esAdministrador ?? false)
                        TarjetaMetrica(
                          titulo: 'Usuarios Activos',
                          valor: '$totalUsuariosActivos',
                          subtitulo: 'Personal planta',
                          icono: Icons.people_alt_outlined,
                          color: AppColors.azulMarino,
                          onTap: () => context.push(AppRoutes.admin),
                        )
                      else
                        TarjetaMetrica(
                          titulo: 'Caudal La Seca',
                          valor: ultimoCaudal,
                          subtitulo: '$totalAforos aforos',
                          icono: Icons.water_outlined,
                          color: AppColors.azulMarino,
                          onTap: () => context.push(AppRoutes.caudal),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),

              // 4. Actividad Reciente del Sistema
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, size: 20, color: AppColors.azulInstitucional),
                      SizedBox(width: 8),
                      Text(
                        'Actividad Reciente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.historial),
                    child: const Text('Ver todo', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (ultimosMovimientos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.bordes),
                  ),
                  child: const Center(
                    child: Text(
                      'No hay actividades recientes registradas.',
                      style: TextStyle(color: AppColors.textoSecundario, fontSize: 13),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ultimosMovimientos.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = ultimosMovimientos[index];
                    final fecha = DateFormat('dd/MM/yyyy').format(item.fecha);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.bordes, width: 1),
                      ),
                      child: ListTile(
                        isThreeLine: true,
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.tieneAlerta
                                ? AppColors.alertaFondo
                                : AppColors.azulClaro,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.tieneAlerta
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            size: 20,
                            color: item.tieneAlerta
                                ? AppColors.alerta
                                : AppColors.azulInstitucional,
                          ),
                        ),
                        title: Text(
                          item.titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          '${item.subtitulo}\nOperario: ${item.responsable}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                        ),
                        trailing: Text(
                          '$fecha\n${item.hora}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textoSecundario),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
