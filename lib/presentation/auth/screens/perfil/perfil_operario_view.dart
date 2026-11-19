import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../data/models/item_historial_modelo.dart';
import '../../../../data/models/usuario_perfil.dart';
import '../../../../domain/calculations/estadisticas_perfil.dart';
import '../../../history/providers/historial_provider.dart';
import '../../../settings/providers/preferencias_provider.dart';
import 'perfil_comunes.dart';

/// Perfil del operario: su trabajo del día, sus registros y preferencias de campo.
class PerfilOperarioView extends StatelessWidget {
  final UsuarioPerfil perfil;
  final DateTime? ahora;

  const PerfilOperarioView({super.key, required this.perfil, this.ahora});

  @override
  Widget build(BuildContext context) {
    final historial = context.watch<HistorialProvider>();
    final hoy = ahora ?? DateTime.now();
    final mios = EstadisticasPerfil.delUsuario(historial.todosLosItems, perfil);
    final delMes = EstadisticasPerfil.delMes(mios, hoy);
    final tareas = EstadisticasPerfil.tareasDeHoy(historial.todosLosItems, hoy);
    final cargandoInicial = historial.cargando && historial.todosLosItems.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoPerfil(
          perfil: perfil,
          textoRol: 'Operador de planta',
          colorRol: AppColors.azulPrimario,
          fondoRol: AppColors.azulClaro,
          estadisticas: [
            EstadisticaPerfil(cargandoInicial ? '…' : '${delMes.length}', 'Registros este mes'),
            EstadisticaPerfil(cargandoInicial ? '…' : '${EstadisticasPerfil.conAviso(delMes)}', 'Con aviso este mes'),
            EstadisticaPerfil(cargandoInicial ? '…' : '${EstadisticasPerfil.diasSeguidos(mios, hoy)}', 'Días seguidos'),
          ],
        ),

        TituloSeccionPerfil('Mis tareas de hoy'),
        EstadoSeccionPerfil(
          cargando: cargandoInicial,
          error: historial.error,
          vacio: false,
          textoVacio: '',
          alReintentar: historial.cargarHistorial,
          hijo: TarjetaSeccionPerfil(
            hijos: [
              _FilaTarea(
                titulo: 'Parámetros fisicoquímicos',
                hecho: tareas[TipoRegistroHistorial.fisicoquimico]!,
                ruta: AppRoutes.fisicoquimicoNuevo,
              ),
              _FilaTarea(
                titulo: 'Jornada de medidores',
                hecho: tareas[TipoRegistroHistorial.medidores]!,
                ruta: AppRoutes.medidoresNuevo,
              ),
              _FilaTarea(
                titulo: 'Aforo de caudal',
                hecho: tareas[TipoRegistroHistorial.caudal]!,
                ruta: AppRoutes.caudalNuevo,
              ),
            ],
          ),
        ),

        TituloSeccionPerfil(
          'Mis últimos registros',
          textoAccion: 'Ver todo',
          alPulsarAccion: () => context.go(AppRoutes.registros),
        ),
        EstadoSeccionPerfil(
          cargando: cargandoInicial,
          error: historial.error,
          vacio: mios.isEmpty,
          textoVacio: 'Aún no tienes registros.',
          alReintentar: historial.cargarHistorial,
          hijo: TarjetaSeccionPerfil(
            hijos: [for (final item in mios.take(5)) FilaRegistroPerfil(item: item)],
          ),
        ),

        const SeccionUmbralesPerfil(editable: false),

        const TituloSeccionPerfil('Preferencias'),
        const TarjetaSeccionPerfil(
          hijos: [
            SwitchPreferenciaPerfil(
              clave: PreferenciasProvider.notificacionesPush,
              titulo: 'Notificaciones push',
              icono: Icons.notifications_none_rounded,
            ),
            SwitchPreferenciaPerfil(
              clave: PreferenciasProvider.sonidoAlerta,
              titulo: 'Sonido de alerta',
              icono: Icons.volume_up_outlined,
            ),
            SwitchPreferenciaPerfil(
              clave: PreferenciasProvider.camaraMedidores,
              titulo: 'Usar cámara por defecto en medidores',
              subtitulo: 'Abre la cámara al registrar una jornada',
              icono: Icons.photo_camera_outlined,
            ),
          ],
        ),

        const SeccionCuentaPerfil(),
      ],
    );
  }
}

class _FilaTarea extends StatelessWidget {
  final String titulo;
  final bool hecho;
  final String ruta;

  const _FilaTarea({required this.titulo, required this.hecho, required this.ruta});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        hecho ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        color: hecho ? AppColors.exito : AppColors.textoSecundario,
      ),
      title: Text(titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: hecho
          ? const Text('Hecho', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.exito))
          : TextButton(
              onPressed: () => context.push(ruta),
              child: const Text('Registrar'),
            ),
    );
  }
}
