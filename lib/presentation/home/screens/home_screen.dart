import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../alerts/providers/alertas_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/banner_estado_planta.dart';
import '../../common/widgets/chip_estado.dart';
import '../../common/widgets/tarjeta_alerta.dart';
import '../../common/widgets/tarjeta_kpi.dart';
import '../../flow/providers/caudal_provider.dart';
import '../../history/providers/historial_provider.dart';
import '../../meters/providers/medidores_provider.dart';
import '../../physicochemical/providers/fisicoquimico_provider.dart';

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
                            '${perfil?.plantaNombre ?? "PTAP Villa Clara"} · Turno A',
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

              // 2. Banner de estado de la planta con ondas
              BannerEstadoPlanta(
                estado: alertasProv.criticasCount > 0
                    ? TipoEstadoPlanta.enAlerta
                    : TipoEstadoPlanta.operativa,
                eficiencia: '95,6 %',
                turbidez: '0,42 NTU',
                cloro: '1,1 mg/L',
              ),

              const SizedBox(height: 18),

              // 3. Indicadores principales (Grid 2x2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Indicadores principales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.turquesaFondo,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sensors_rounded, size: 12, color: AppColors.turquesa),
                        SizedBox(width: 3),
                        Text(
                          'En vivo',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.turquesa,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Grid 2x2 de tarjetas KPI
              Row(
                children: [
                  Expanded(
                    child: TarjetaKpi(
                      titulo: 'Caudal de entrada',
                      valor: '128,4',
                      unidad: 'L/s',
                      icono: Icons.arrow_downward_rounded,
                      variacion: '+2,1 %',
                      variacionPositiva: true,
                      notaRango: 'Rango 110–140 L/s',
                      alPulsar: () => alCambiarPestana?.call(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TarjetaKpi(
                      titulo: 'Caudal de salida',
                      valor: '122,7',
                      unidad: 'L/s',
                      icono: Icons.arrow_upward_rounded,
                      variacion: '+1,6 %',
                      variacionPositiva: true,
                      notaRango: 'Rango 105–135 L/s',
                      alPulsar: () => alCambiarPestana?.call(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TarjetaKpi(
                      titulo: 'Volumen tratado hoy',
                      valor: '4.286',
                      unidad: 'm³',
                      icono: Icons.water_drop_outlined,
                      variacion: '+2,8 %',
                      variacionPositiva: true,
                      notaRango: 'Meta 4.000 m³/día',
                      alPulsar: () => alCambiarPestana?.call(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TarjetaKpi(
                      titulo: 'Presión de red',
                      valor: '3,4',
                      unidad: 'bar',
                      icono: Icons.speed_rounded,
                      notaRango: 'Rango 2,8–4,0 bar',
                      alPulsar: () => alCambiarPestana?.call(1),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 4. Tarjeta "Nivel de almacenamiento" con barra de progreso
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.bordes),
                  boxShadow: AppColors.sombraSuave,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nivel de almacenamiento',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textoPrincipal,
                              ),
                            ),
                            Text(
                              'Tanque principal · 2.500 m³',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '78 %',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Barra de progreso de nivel
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: 0.78,
                        minHeight: 8,
                        backgroundColor: AppColors.fondoGeneral,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.turquesa),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      '1.950 m³ disponibles · Mín. operativo 40 % · Autonomía 4.4 h',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 5. Comportamiento del caudal (últimas 24 h)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comportamiento del caudal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                  InkWell(
                    onTap: () => alCambiarPestana?.call(1),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Detalle',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.azulPrimario,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.azulPrimario),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Gráfica de Líneas Entrada vs Salida
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.bordes),
                  boxShadow: AppColors.sombraSuave,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.azulPrimario, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('Entrada', style: TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
                        const SizedBox(width: 14),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.turquesa, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('Salida', style: TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 130,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 18,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0:
                                      return const Text('00h', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                                    case 3:
                                      return const Text('06h', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                                    case 6:
                                      return const Text('12h', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                                    case 9:
                                      return const Text('18h', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                                    case 11:
                                      return const Text('24h', style: TextStyle(fontSize: 9, color: AppColors.textoSecundario));
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: 11,
                          minY: 90,
                          maxY: 150,
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 112),
                                FlSpot(2, 118),
                                FlSpot(4, 126),
                                FlSpot(6, 138),
                                FlSpot(8, 122),
                                FlSpot(11, 128.4),
                              ],
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: AppColors.azulPrimario,
                              barWidth: 2.2,
                              dotData: const FlDotData(show: false),
                            ),
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 108),
                                FlSpot(2, 114),
                                FlSpot(4, 120),
                                FlSpot(6, 131),
                                FlSpot(8, 117),
                                FlSpot(11, 122.7),
                              ],
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: AppColors.turquesa,
                              barWidth: 2.2,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 6. Alertas recientes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alertas recientes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push(AppRoutes.alertas),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver todas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.azulPrimario,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.azulPrimario),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ...alertasProv.activas.take(2).map(
                    (a) => TarjetaAlerta(
                      titulo: a.titulo,
                      descripcion: a.descripcion,
                      severidad: a.severidad,
                      hora: a.hora,
                      alPulsar: () => context.push(AppRoutes.alertas),
                    ),
                  ),

              const SizedBox(height: 14),

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
