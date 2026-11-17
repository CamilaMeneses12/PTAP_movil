import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/supabase_config.dart';
import '../../common/widgets/app_drawer.dart';

/// Pantalla de configuración del sistema PTAP
class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _alertasSonoras = true;
  bool _precargaMedidores = true;

  @override
  Widget build(BuildContext context) {
    final conectado = SupabaseConfig.estaInicializado;

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      drawer: const AppDrawer(rutaActual: AppRoutes.configuracion),
      appBar: AppBar(
        title: const Text('Configuración'),
        actions: [
          IconButton(
            tooltip: 'Ir a Inicio',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Sección 1: Conectividad y Sincronización
          const Text(
            'CONECTIVIDAD Y BASE DE DATOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textoSecundario,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.bordes, width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: conectado ? AppColors.exitoFondo : AppColors.azulClaro,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          conectado ? Icons.cloud_done : Icons.cloud_off,
                          color: conectado ? AppColors.verdeAmbiental : AppColors.azulInstitucional,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conectado ? 'Supabase Conectado' : 'Modo Autónomo Local',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              conectado
                                  ? 'Sincronización en tiempo real habilitada con PostgreSQL.'
                                  : 'Los datos se gestionan en memoria y archivos locales.',
                              style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sección 2: Preferencias de Operación en Campo
          const Text(
            'PREFERENCIAS DE OPERACIÓN EN CAMPO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textoSecundario,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.bordes, width: 1.2),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeThumbColor: AppColors.azulInstitucional,
                  title: const Text('Alertas visuales normativas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Resaltar parámetros fuera de la Resolución 2115', style: TextStyle(fontSize: 12, color: AppColors.textoSecundario)),
                  value: _alertasSonoras,
                  onChanged: (val) => setState(() => _alertasSonoras = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeThumbColor: AppColors.azulInstitucional,
                  title: const Text('Precarga de lecturas anteriores', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Rellenar automáticamente la última lectura tomada en medidores', style: TextStyle(fontSize: 12, color: AppColors.textoSecundario)),
                  value: _precargaMedidores,
                  onChanged: (val) => setState(() => _precargaMedidores = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sección 3: Información de la Aplicación
          const Text(
            'INFORMACIÓN DEL SISTEMA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textoSecundario,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.bordes, width: 1.2),
            ),
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.azulInstitucional),
                  title: Text('Versión de la Aplicación', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('1.0.0 (Investigación SENA PTAP 2026)', style: TextStyle(fontSize: 12)),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.location_on_outlined, color: AppColors.azulInstitucional),
                  title: Text('Centro de Formación', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('Centro de los Recursos Naturales Renovables La Salada - Regional Antioquia', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
