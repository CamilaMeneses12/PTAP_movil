import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../data/models/usuario_perfil.dart';
import '../../../../domain/calculations/estadisticas_perfil.dart';
import '../../../admin/providers/admin_provider.dart';
import '../../../alerts/providers/alertas_provider.dart';
import '../../../history/providers/historial_provider.dart';
import '../../../reports/screens/exportar_reportes_screen.dart';
import '../../../settings/providers/preferencias_provider.dart';
import 'perfil_comunes.dart';

/// Perfil del administrador: resumen de la planta, gestión y umbrales editables.
class PerfilAdministradorView extends StatelessWidget {
  final UsuarioPerfil perfil;
  final DateTime? ahora;

  const PerfilAdministradorView({super.key, required this.perfil, this.ahora});

  @override
  Widget build(BuildContext context) {
    final historial = context.watch<HistorialProvider>();
    final admin = context.watch<AdminProvider>();
    final alertas = context.watch<AlertasProvider>();
    final hoy = ahora ?? DateTime.now();
    final items = historial.todosLosItems;
    final cargandoInicial = historial.cargando && items.isEmpty;
    final usuariosActivos = admin.usuarios.where((u) => u.activo).length;
    final ultimos30 = EstadisticasPerfil.ultimosDias(items, hoy, 30);

    String dato(String v) => cargandoInicial ? '…' : v;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoPerfil(
          perfil: perfil,
          textoRol: 'Administrador',
          colorRol: AppColors.azulMarino,
          fondoRol: AppColors.azulClaro,
          estadisticas: const [],
        ),

        const TituloSeccionPerfil('Resumen de la planta'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.9,
          children: [
            _TarjetaResumen(
              icono: Icons.people_alt_outlined,
              valor: admin.cargando && admin.usuarios.isEmpty ? '…' : '$usuariosActivos',
              etiqueta: 'Usuarios activos',
            ),
            _TarjetaResumen(
              icono: Icons.description_outlined,
              valor: dato('${EstadisticasPerfil.delMes(items, hoy).length}'),
              etiqueta: 'Registros del mes',
            ),
            _TarjetaResumen(
              icono: Icons.verified_outlined,
              valor: dato(formatoPorcentaje(EstadisticasPerfil.porcentajeCumplimiento(ultimos30))),
              etiqueta: 'Cumplimiento 30 días',
            ),
            _TarjetaResumen(
              icono: Icons.notifications_active_outlined,
              valor: '${alertas.activasCount}',
              etiqueta: 'Alertas abiertas',
              color: alertas.criticasCount > 0 ? AppColors.critico : AppColors.azulPrimario,
              alPulsar: () => context.push(AppRoutes.alertas),
            ),
          ],
        ),

        const TituloSeccionPerfil('Gestión'),
        TarjetaSeccionPerfil(
          hijos: [
            FilaNavegacionPerfil(
              key: const Key('gestion_usuarios'),
              icono: Icons.manage_accounts_outlined,
              titulo: 'Usuarios y roles',
              alPulsar: () => context.push(AppRoutes.admin, extra: 0),
            ),
            FilaNavegacionPerfil(
              icono: Icons.speed_outlined,
              titulo: 'Medidores',
              alPulsar: () => context.push(AppRoutes.admin, extra: 1),
            ),
            FilaNavegacionPerfil(
              icono: Icons.tune_rounded,
              titulo: 'Catálogo de parámetros',
              alPulsar: () => context.push(AppRoutes.admin, extra: 2),
            ),
            FilaNavegacionPerfil(
              icono: Icons.file_download_outlined,
              titulo: 'Exportar reportes',
              alPulsar: () => context.push(AppRoutes.exportar, extra: TipoFormatoExportar.historial),
            ),
          ],
        ),

        const SeccionUmbralesPerfil(editable: true),

        TituloSeccionPerfil(
          'Actividad reciente de operarios',
          textoAccion: 'Ver todo',
          alPulsarAccion: () => context.go(AppRoutes.registros),
        ),
        EstadoSeccionPerfil(
          cargando: cargandoInicial,
          error: historial.error,
          vacio: items.isEmpty,
          textoVacio: 'Todavía no hay registros en la planta.',
          alReintentar: historial.cargarHistorial,
          hijo: TarjetaSeccionPerfil(
            hijos: [for (final item in items.take(6)) FilaRegistroPerfil(item: item, mostrarResponsable: true)],
          ),
        ),

        const TituloSeccionPerfil('Preferencias'),
        const TarjetaSeccionPerfil(
          hijos: [
            SwitchPreferenciaPerfil(
              clave: PreferenciasProvider.notificacionesPush,
              titulo: 'Notificaciones push',
              icono: Icons.notifications_none_rounded,
            ),
            SwitchPreferenciaPerfil(
              clave: PreferenciasProvider.alertasSms,
              titulo: 'Alertas críticas por SMS',
              icono: Icons.sms_outlined,
            ),
          ],
        ),

        const SeccionCuentaPerfil(),
      ],
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;
  final VoidCallback? alPulsar;

  const _TarjetaResumen({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.color = AppColors.azulPrimario,
    this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blanco,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: alPulsar,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.bordes),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: AppColors.azulClaro, borderRadius: BorderRadius.circular(10)),
                child: Icon(icono, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        valor,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color == AppColors.azulPrimario ? AppColors.textoPrincipal : color),
                      ),
                    ),
                    Text(
                      etiqueta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.textoSecundario),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
