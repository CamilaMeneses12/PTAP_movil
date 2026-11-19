import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../data/models/usuario_perfil.dart';
import '../../../../domain/calculations/estadisticas_perfil.dart';
import '../../../history/providers/historial_provider.dart';
import '../../../reports/screens/exportar_reportes_screen.dart';
import '../../../settings/providers/preferencias_provider.dart';
import 'perfil_comunes.dart';

/// Perfil del consultor SIGA: consulta y auditoría, sin acciones de edición.
class PerfilConsultorView extends StatelessWidget {
  final UsuarioPerfil perfil;
  final DateTime? ahora;

  const PerfilConsultorView({super.key, required this.perfil, this.ahora});

  @override
  Widget build(BuildContext context) {
    final historial = context.watch<HistorialProvider>();
    final hoy = ahora ?? DateTime.now();
    final ultimos30 = EstadisticasPerfil.ultimosDias(historial.todosLosItems, hoy, 30);
    final cumplimiento = EstadisticasPerfil.cumplimientoPorParametro(ultimos30)
        .where((c) => c.total > 0)
        .toList();
    final cargandoInicial = historial.cargando && historial.todosLosItems.isEmpty;
    final incumplimientos = EstadisticasPerfil.conAviso(ultimos30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoPerfil(
          perfil: perfil,
          textoRol: 'Consultor SIGA · solo lectura',
          colorRol: AppColors.turquesaTexto,
          fondoRol: AppColors.turquesaFondo,
          estadisticas: [
            EstadisticaPerfil(cargandoInicial ? '…' : '${ultimos30.length}', 'Registros 30 días'),
            EstadisticaPerfil(cargandoInicial ? '…' : '$incumplimientos', 'Incumplimientos'),
            EstadisticaPerfil(
              cargandoInicial ? '…' : formatoPorcentaje(EstadisticasPerfil.porcentajeCumplimiento(ultimos30)),
              'Dentro de norma',
            ),
          ],
        ),

        const TituloSeccionPerfil('Cumplimiento por parámetro · 30 días'),
        EstadoSeccionPerfil(
          cargando: cargandoInicial,
          error: historial.error,
          vacio: cumplimiento.isEmpty,
          textoVacio: 'No hay registros en los últimos 30 días.',
          alReintentar: historial.cargarHistorial,
          hijo: TarjetaSeccionPerfil(
            hijos: [
              for (final c in cumplimiento)
                BarraCumplimientoPerfil(
                  nombre: c.nombre,
                  porcentaje: c.porcentaje,
                  detalle: '${c.incumplimientos} de ${c.total} fuera de norma',
                ),
            ],
          ),
        ),

        const TituloSeccionPerfil('Consulta'),
        TarjetaSeccionPerfil(
          hijos: [
            FilaNavegacionPerfil(
              icono: Icons.file_download_outlined,
              titulo: 'Reportes y exportación (PDF / Excel)',
              alPulsar: () => context.push(AppRoutes.exportar, extra: TipoFormatoExportar.historial),
            ),
            FilaNavegacionPerfil(
              icono: Icons.history_rounded,
              titulo: 'Histórico completo',
              alPulsar: () => context.go(AppRoutes.registros),
            ),
            FilaNavegacionPerfil(
              icono: Icons.notifications_none_rounded,
              titulo: 'Alertas',
              alPulsar: () => context.push(AppRoutes.alertas),
            ),
          ],
        ),

        const SeccionUmbralesPerfil(editable: false),

        const TituloSeccionPerfil('Preferencias'),
        const TarjetaSeccionPerfil(
          hijos: [
            SwitchPreferenciaPerfil(
              clave: PreferenciasProvider.resumenSemanal,
              titulo: 'Resumen semanal de cumplimiento',
              icono: Icons.calendar_month_outlined,
            ),
            SwitchPreferenciaPerfil(
              clave: PreferenciasProvider.notificacionesPush,
              titulo: 'Notificaciones push',
              icono: Icons.notifications_none_rounded,
            ),
          ],
        ),

        const SeccionCuentaPerfil(),
      ],
    );
  }
}
