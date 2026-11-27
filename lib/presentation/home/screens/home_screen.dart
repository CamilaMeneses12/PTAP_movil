import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../alerts/providers/alertas_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/aviso_sincronizacion.dart';
import '../../common/widgets/banner_estado_planta.dart';
import '../../common/widgets/chip_estado.dart';
import '../../common/widgets/tarjeta_kpi.dart';
import '../../../domain/alertas/catalogo_parametros_alerta.dart';
import '../../../domain/calculations/resumen_inicio.dart';
import '../../flow/providers/caudal_provider.dart';
import '../../history/providers/historial_provider.dart';
import '../../meters/providers/medidores_provider.dart';
import '../../physicochemical/providers/fisicoquimico_provider.dart';
import '../widgets/tarjetas_inicio.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int indice)? alCambiarPestana;

  const HomeScreen({super.key, this.alCambiarPestana});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<SesionUsuarioProvider>();
    final perfil = authProvider.perfil;
    final nombre = perfil != null ? perfil.nombreCompleto.split(' ').first : 'Andrea';
    final puedeEditar = perfil?.puedeEditar ?? false;
    final esAdmin = perfil?.esAdministrador ?? false;

    final alertasProv = context.watch<AlertasProvider>();
    final historialProv = context.watch<HistorialProvider>();
    final fisicoProv = context.watch<FisicoquimicoProvider>();
    final caudalProv = context.watch<CaudalProvider>();
    final medidoresProv = context.watch<MedidoresProvider>();

    final calidad = ResumenInicio.calidadAguaTratada(fisicoProv.registros);
    final caudal = ResumenInicio.caudalQuebrada(caudalProv.aforos);
    final jornada = ResumenInicio.ultimaJornada(medidoresProv.jornadas);
    final resumenAlertas = ResumenInicio.resumenAlertas(alertasProv.activas);
    final VoidCallback? registrarFisico =
        puedeEditar ? () => context.push(AppRoutes.fisicoquimicoNuevo) : null;

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.azulPrimario,
          onRefresh: () async {
            await Future.wait([
              fisicoProv.cargarRegistros(),
              medidoresProv.cargarJornadas(),
              caudalProv.cargarAforos(),
              historialProv.cargarHistorial(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // 1. Header institucional fiel a Figma (Ubicación, Saludo y Campana con Badge)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.water_drop_outlined, size: 12, color: AppColors.turquesa),
                          const SizedBox(width: 4),
                          Text(
                            perfil?.plantaNombre ?? 'PTAP Villa Clara',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hola, $nombre',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),

                  // Botón del Asistente PTAP (chatbot)
                  Container(
                    width: 42,
                    height: 42,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.blanco,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bordes),
                      boxShadow: AppColors.sombraSuave,
                    ),
                    child: IconButton(
                      key: const Key('abrir_asistente'),
                      tooltip: 'Asistente PTAP',
                      icon: const Icon(Icons.smart_toy_outlined, size: 22, color: AppColors.azulMarino),
                      onPressed: () => context.push(AppRoutes.asistente),
                    ),
                  ),

                  // Botón campana de notificaciones con insignia de alertas activas
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.blanco,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bordes),
                          boxShadow: AppColors.sombraSuave,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, size: 22, color: AppColors.azulMarino),
                          onPressed: () => context.push(AppRoutes.alertas),
                        ),
                      ),
                      if (alertasProv.activasCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.critico,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${alertasProv.activasCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Registros guardados en el celular sin subir (modo sin conexión)
              const AvisoSincronizacion(),

              // Banner de estado y tarjetas de indicadores del Inicio anterior, ahora con los
              // valores de los registros (último DO-F-070, último aforo y última jornada).
              BannerEstadoPlanta(
                estado: resumenAlertas.criticas > 0 ? TipoEstadoPlanta.enAlerta : TipoEstadoPlanta.operativa,
                horaActualizacion: DateFormat('HH:mm').format(DateTime.now()),
                descripcion: _descripcionEstado(resumenAlertas, calidad),
                indicadores: [
                  ('pH', _valor(calidad?.ph.valor)),
                  ('Turbidez', _valor(calidad?.turbidez.valor, ' NTU')),
                  ('Cloro res.', _valor(calidad?.cloro.valor, ' mg/L')),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TarjetaKpi(
                      key: const Key('kpi_caudal'),
                      titulo: 'Caudal de entrada',
                      valor: caudal == null ? '—' : _num.format(caudal.ultimo.caudalLS),
                      unidad: caudal == null ? '' : 'L/s',
                      icono: Icons.arrow_downward_rounded,
                      variacion: _variacionCaudal(caudal),
                      variacionPositiva: (caudal?.diferenciaLS ?? 0) >= 0,
                      notaRango: caudal == null
                          ? 'Sin aforos registrados'
                          : 'Rango ${_num.format(CatalogoParametrosAlerta.caudalFuenteMinLS)}–'
                              '${_num.format(CatalogoParametrosAlerta.caudalFuenteMaxLS)} L/s',
                      alPulsar: () => alCambiarPestana?.call(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TarjetaKpi(
                      key: const Key('kpi_volumen'),
                      titulo: 'Volumen macromedidor',
                      valor: jornada == null ? '—' : _num.format(jornada.consumoMacromedidor),
                      unidad: jornada == null ? '' : 'm³',
                      icono: Icons.water_drop_outlined,
                      notaRango: jornada == null
                          ? 'Sin jornadas registradas'
                          : 'Jornada ${DateFormat('dd/MM').format(jornada.fecha)} · pérdida ${_num.format(jornada.porcentajePerdida)} %',
                      alPulsar: () => alCambiarPestana?.call(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Tarjetas calculadas con los registros del operario (DO-F-070, medidores,
              //    aforos y alertas). Se actualizan solas porque escuchan a los providers.
              TarjetaPendientesHoy(
                estado: ResumenInicio.pendientesDeHoy(
                  fisicoquimicos: fisicoProv.registros,
                  jornadas: medidoresProv.jornadas,
                  aforos: caudalProv.aforos,
                  ahora: DateTime.now(),
                ),
                alAbrirFormulario: puedeEditar ? (f) => context.push(_rutaFormulario(f)) : null,
              ),
              TarjetaCalidadAgua(
                calidad: calidad,
                alRegistrar: registrarFisico,
                alVerDetalle: calidad == null
                    ? null
                    : () => context.push(AppRoutes.fisicoquimicoDetalle, extra: calidad.registro),
              ),
              TarjetaTendenciaCloro(
                puntos: ResumenInicio.tendenciaCloro(fisicoProv.registros),
                alRegistrar: registrarFisico,
              ),
              TarjetaCaudalQuebrada(
                caudal: caudal,
                alRegistrar: puedeEditar ? () => context.push(AppRoutes.caudalNuevo) : null,
                alVerDetalle: caudal == null
                    ? null
                    : () => context.push(AppRoutes.caudalDetalle, extra: caudal.ultimo),
              ),
              TarjetaPerdidasAgua(
                jornada: jornada,
                alRegistrar: puedeEditar ? () => context.push(AppRoutes.medidoresNuevo) : null,
                alVerDetalle: jornada == null
                    ? null
                    : () => context.push(AppRoutes.medidoresDetalle, extra: jornada),
              ),
              TarjetaAlertasActivas(
                resumen: resumenAlertas,
                alPulsar: () => context.push(AppRoutes.alertas),
              ),

              const SizedBox(height: 2),

              // 7. Botón flotante para nuevo registro si puede editar
              if (puedeEditar) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarMenuNuevoRegistro(context),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Registrar medición en planta'),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // 8. Si es Administrador: Tarjeta de estado de usuarios y auditoría
              if (esAdmin) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.azulClaro.withAlpha(100),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.bordes),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panel de Administración',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.azulMarino),
                          ),
                          Text(
                            'Gestión de usuarios y catálogos normativos',
                            style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => context.push(AppRoutes.admin),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: AppColors.azulMarino,
                        ),
                        child: const Text('Gestionar', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static final _num = NumberFormat('#,##0.0#', 'es_CO');

  static String _valor(double? v, [String unidad = '']) => v == null ? '—' : '${_num.format(v)}$unidad';

  /// Variación porcentual del último aforo frente al anterior; null si es el primero.
  static String? _variacionCaudal(CaudalQuebrada? caudal) {
    final dif = caudal?.diferenciaLS;
    final anterior = caudal?.anterior?.caudalLS;
    if (dif == null || anterior == null || anterior == 0) return null;
    final pct = dif / anterior * 100;
    return '${pct >= 0 ? '+' : '−'}${_num.format(pct.abs())} %';
  }

  static String _descripcionEstado(ResumenAlertas alertas, CalidadAguaTratada? calidad) {
    if (alertas.total > 0) {
      final criticas = alertas.criticas > 0
          ? ' (${alertas.criticas} ${alertas.criticas == 1 ? 'crítica' : 'críticas'})'
          : '';
      return '${alertas.total} ${alertas.total == 1 ? 'alerta activa' : 'alertas activas'}$criticas. '
          'Revíselas en Notificaciones.';
    }
    if (calidad == null) return 'No hay alertas activas. Aún no hay análisis DO-F-070 registrados.';
    return calidad.conforme
        ? 'No hay alertas activas. El último DO-F-070 está dentro de rango.'
        : 'No hay alertas activas, pero el último DO-F-070 tiene valores fuera de rango.';
  }

  static String _rutaFormulario(FormatoDiario formato) => switch (formato) {
        FormatoDiario.fisicoquimico => AppRoutes.fisicoquimicoNuevo,
        FormatoDiario.medidores => AppRoutes.medidoresNuevo,
        FormatoDiario.aforo => AppRoutes.caudalNuevo,
      };

  void _mostrarMenuNuevoRegistro(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.blanco,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nuevo Registro en Planta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.science_outlined, color: AppColors.azulPrimario),
              title: const Text('Análisis Fisicoquímico (DO-F-070)'),
              subtitle: const Text('pH, cloro, turbidez y color'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.fisicoquimicoNuevo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.speed_outlined, color: AppColors.turquesa),
              title: const Text('Lectura de Medidores'),
              subtitle: const Text('Balance y pérdidas de agua'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.medidoresNuevo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.water_outlined, color: AppColors.azulMarino),
              title: const Text('Aforo de Caudal Quebrada La Seca'),
              subtitle: const Text('Método del flotador'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.caudalNuevo);
              },
            ),
          ],
        ),
      ),
    );
  }
}
