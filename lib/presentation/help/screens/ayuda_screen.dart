import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// Pantalla de ayuda, manual técnico y normatividad para el operario y auditor
class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textoPrincipal),
          onPressed: () => context.pop(),
        ),
        title: const Text('Ayuda y Soporte'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner de ayuda
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.gradienteAgua,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.help_outline, color: Colors.white, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guía Técnica y Normativa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Documentación de campo para la PTAP SENA La Salada',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. Límites Normativos
          _TarjetaAyuda(
            icono: Icons.verified_outlined,
            color: AppColors.azulTecnologico,
            titulo: 'Límites Normativos (Resolución 2115 de 2007)',
            contenido: [
              '• pH Agua Tratada: 6.5 a 9.0 unidades de pH.',
              '• Cloro Residual Libre: 0.3 a 2.0 mg/L (en cualquier punto de la red).',
              '• Turbidez Agua Tratada: Máximo 2.0 UNT (óptimo < 1.0).',
              '• Color Aparente: Máximo 15 unidades UPC.',
              '• Agua Filtrada (Turbidez): 0.0 a 2.0 UNT antes de cloración.',
            ],
          ),
          const SizedBox(height: 14),

          // 2. Balance Hídrico de Medidores
          _TarjetaAyuda(
            icono: Icons.speed_outlined,
            color: AppColors.azulInstitucional,
            titulo: 'Fórmulas de Medidores y Pérdidas',
            contenido: [
              '• Total Consumo Micros: Suma de los 8 micromedidores de la sede (ENCC, SENNOVA, Labs, Biocabaña, Cafetería, Pecuaria, Agroindustria, Gastronomía).',
              '• Agua No Registrada (m³): Consumo Macro Medidor - Total Consumo Micromedidores.',
              '• Porcentaje de Pérdida (%): (Agua No Registrada / Consumo Macromedidor) × 100.',
            ],
          ),
          const SizedBox(height: 14),

          // 3. Método del Flotador Caudal La Seca
          _TarjetaAyuda(
            icono: Icons.water_outlined,
            color: AppColors.turquesa,
            titulo: 'Aforo por Flotador (Quebrada La Seca)',
            contenido: [
              '• Velocidad Superficial: Distancia (L) / Tiempo Promedio (s).',
              '• Velocidad Media Corregida: Vel. Superficial × Factor K (0.80 - 0.85).',
              '• Área de la Sección: Ancho Superficial (W) × Profundidad Promedio.',
              '• Caudal (Q): Área × Velocidad Media.',
              '• Conversión a L/s: Q (m³/s) × 1000.',
            ],
          ),
          const SizedBox(height: 14),

          // 4. Contacto Institucional
          _TarjetaAyuda(
            icono: Icons.support_agent_outlined,
            color: AppColors.azulMarino,
            titulo: 'Contacto y Soporte de Investigación',
            contenido: [
              '• Investigador Líder: Diego Calderón.',
              '• Ficha SENA: 3312744.',
              '• Centro: Recursos Naturales Renovables - La Salada.',
              '• Caldas, Antioquia.',
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaAyuda extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final List<String> contenido;

  const _TarjetaAyuda({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.bordes, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...contenido.map(
              (linea) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  linea,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textoSecundario, height: 1.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
