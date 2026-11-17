import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/alerta_sistema_modelo.dart';
import '../../common/widgets/tarjeta_alerta.dart';
import '../providers/alertas_provider.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertasProv = context.watch<AlertasProvider>();

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        backgroundColor: AppColors.fondoGeneral,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textoPrincipal),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            const Text(
              'Alertas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipal,
              ),
            ),
            Text(
              '${alertasProv.activasCount} activas · ${alertasProv.historial.length} resueltas ayer',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textoSecundario,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              alertasProv.marcarTodasLeidas();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todas las alertas fueron marcadas como leídas'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Marcar leídas',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.azulPrimario,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Selector de pestañas: Activas (n) | Historial
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.bordes.withAlpha(120),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.azulMarino,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: AppColors.blanco,
                  unselectedLabelColor: AppColors.textoSecundario,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: 'Activas (${alertasProv.activasCount})'),
                    const Tab(text: 'Historial'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Contadores de severidad (Críticas / Advertencias / Informativas)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _ContadorSeveridad(
                      cuenta: alertasProv.criticasCount,
                      etiqueta: 'Críticas',
                      color: AppColors.critico,
                      colorFondo: AppColors.criticoFondo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ContadorSeveridad(
                      cuenta: alertasProv.advertenciasCount,
                      etiqueta: 'Advertencias',
                      color: AppColors.advertencia,
                      colorFondo: AppColors.advertenciaFondo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ContadorSeveridad(
                      cuenta: alertasProv.informacionCount,
                      etiqueta: 'Informativas',
                      color: AppColors.informacion,
                      colorFondo: AppColors.informacionFondo,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Lista de alertas tabulada
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pestaña 1: Activas
                  _ListaAlertasAgrupadas(
                    alertas: alertasProv.activas,
                    esHistorial: false,
                  ),

                  // Pestaña 2: Historial
                  _ListaAlertasAgrupadas(
                    alertas: alertasProv.historial,
                    esHistorial: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContadorSeveridad extends StatelessWidget {
  final int cuenta;
  final String etiqueta;
  final Color color;
  final Color colorFondo;

  const _ContadorSeveridad({
    required this.cuenta,
    required this.etiqueta,
    required this.color,
    required this.colorFondo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Column(
        children: [
          Text(
            '$cuenta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaAlertasAgrupadas extends StatelessWidget {
  final List<AlertaSistema> alertas;
  final bool esHistorial;

  const _ListaAlertasAgrupadas({
    required this.alertas,
    required this.esHistorial,
  });

  @override
  Widget build(BuildContext context) {
    if (alertas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.exito.withAlpha(180)),
            const SizedBox(height: 12),
            Text(
              esHistorial ? 'No hay alertas en el historial' : 'No hay alertas activas en este momento',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textoSecundario,
              ),
            ),
          ],
        ),
      );
    }

    final alertasHoy = alertas.where((a) => a.grupoFecha == 'HOY').toList();
    final alertasAyer = alertas.where((a) => a.grupoFecha != 'HOY').toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (alertasHoy.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
            child: Text(
              'HOY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textoSecundario,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...alertasHoy.map(
            (alerta) => TarjetaAlerta(
              titulo: alerta.titulo,
              descripcion: alerta.descripcion,
              severidad: alerta.severidad,
              hora: alerta.hora,
              alPulsar: () => _mostrarAccionAlerta(context, alerta),
            ),
          ),
        ],
        if (alertasAyer.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8, top: 12),
            child: Text(
              'AYER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textoSecundario,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...alertasAyer.map(
            (alerta) => TarjetaAlerta(
              titulo: alerta.titulo,
              descripcion: alerta.descripcion,
              severidad: alerta.severidad,
              hora: alerta.hora,
              alPulsar: () => _mostrarAccionAlerta(context, alerta),
            ),
          ),
        ],
      ],
    );
  }

  void _mostrarAccionAlerta(BuildContext context, AlertaSistema alerta) {
    final prov = context.read<AlertasProvider>();
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    alerta.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                ),
                Text(
                  alerta.hora,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              alerta.descripcion,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textoSecundario,
                height: 1.4,
              ),
            ),
            if (alerta.rangoEsperado != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.fondoGeneral,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Rango técnico esperado: ${alerta.rangoEsperado}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textoPrincipal,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (!alerta.resuelta)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        prov.marcarResuelta(alerta.id);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alerta marcada como resuelta')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.exito,
                      ),
                      child: const Text('Resolver'),
                    ),
                  ),
                if (!alerta.resuelta) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
