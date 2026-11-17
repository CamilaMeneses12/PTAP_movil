import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/item_historial_modelo.dart';
import '../../common/widgets/app_drawer.dart';
import '../../reports/screens/exportar_reportes_screen.dart';
import '../providers/historial_provider.dart';
import '../widgets/filtro_historial_sheet.dart';
import '../widgets/tarjeta_item_historial.dart';

/// Pantalla principal del historial unificado con filtros avanzados
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final TextEditingController _busquedaController = TextEditingController();
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistorialProvider>();
    final filtrosActivos = provider.conteoFiltrosActivos;

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      drawer: const AppDrawer(rutaActual: AppRoutes.historial),
      appBar: AppBar(
        title: const Text('Historial de Registros'),
        actions: [
          // Botón de filtros avanzados con insignia de conteo
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Filtros avanzados',
                icon: const Icon(Icons.tune_outlined),
                onPressed: () => FiltroHistorialSheet.mostrar(context),
              ),
              if (filtrosActivos > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.alerta,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$filtrosActivos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (filtrosActivos > 0)
            IconButton(
              tooltip: 'Limpiar filtros',
              icon: const Icon(Icons.filter_alt_off_outlined),
              onPressed: () {
                _busquedaController.clear();
                provider.limpiarFiltros();
              },
            ),
          IconButton(
            tooltip: 'Exportar historial',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              context.push(AppRoutes.exportar, extra: TipoFormatoExportar.historial);
            },
          ),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.cargarHistorial(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Buscador por texto
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar por parámetro, operario o texto...',
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                suffixIcon: _busquedaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _busquedaController.clear();
                          provider.setBusqueda('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => provider.setBusqueda(val),
            ),
          ),

          // 2. Chips de tipo de registro y botón rápido de alertas
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _ChipTipo(
                    etiqueta: 'Todos',
                    tipo: TipoRegistroHistorial.todos,
                    seleccionado: provider.tipoSeleccionado == TipoRegistroHistorial.todos,
                    onSelected: () => provider.setTipo(TipoRegistroHistorial.todos),
                  ),
                  const SizedBox(width: 8),
                  _ChipTipo(
                    etiqueta: 'Fisicoquímicos',
                    tipo: TipoRegistroHistorial.fisicoquimico,
                    icono: Icons.science_outlined,
                    color: AppColors.senaVerde,
                    seleccionado: provider.tipoSeleccionado == TipoRegistroHistorial.fisicoquimico,
                    onSelected: () => provider.setTipo(TipoRegistroHistorial.fisicoquimico),
                  ),
                  const SizedBox(width: 8),
                  _ChipTipo(
                    etiqueta: 'Medidores',
                    tipo: TipoRegistroHistorial.medidores,
                    icono: Icons.speed_outlined,
                    color: AppColors.aguaPrimario,
                    seleccionado: provider.tipoSeleccionado == TipoRegistroHistorial.medidores,
                    onSelected: () => provider.setTipo(TipoRegistroHistorial.medidores),
                  ),
                  const SizedBox(width: 8),
                  _ChipTipo(
                    etiqueta: 'Caudal La Seca',
                    tipo: TipoRegistroHistorial.caudal,
                    icono: Icons.water_outlined,
                    color: AppColors.azulTecnologico,
                    seleccionado: provider.tipoSeleccionado == TipoRegistroHistorial.caudal,
                    onSelected: () => provider.setTipo(TipoRegistroHistorial.caudal),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: provider.soloAlertas ? Colors.white : AppColors.alerta,
                    ),
                    label: const Text('Solo Alertas'),
                    selected: provider.soloAlertas,
                    selectedColor: AppColors.alerta,
                    labelStyle: TextStyle(
                      color: provider.soloAlertas ? Colors.white : AppColors.textoPrincipal,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (val) => provider.setSoloAlertas(val),
                  ),
                ],
              ),
            ),
          ),

          // 3. Fila de filtros activos adicionales (Fecha o Usuario seleccionados)
          if (provider.fechaInicio != null || provider.usuarioSeleccionado != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  const Text(
                    'Filtros:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (provider.fechaInicio != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InputChip(
                                label: Text(
                                  '${_formatoFecha.format(provider.fechaInicio!)} - ${_formatoFecha.format(provider.fechaFin ?? provider.fechaInicio!)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () => provider.setRangoFechas(null, null),
                              ),
                            ),
                          if (provider.usuarioSeleccionado != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InputChip(
                                avatar: const Icon(Icons.person, size: 14),
                                label: Text(
                                  provider.usuarioSeleccionado!,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () => provider.setUsuario(null),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 4. Barra de conteo de resultados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mostrando ${provider.totalItems} registros',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textoPrincipal,
                  ),
                ),
                if (provider.totalAlertas > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.alerta.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${provider.totalAlertas} con alerta',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.alerta,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 5. Lista de Registros o Estado Vacío
          Expanded(
            child: provider.cargando
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: AppColors.alerta),
                              const SizedBox(height: 12),
                              Text(
                                provider.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.alerta),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => provider.cargarHistorial(),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : provider.items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.filter_alt_off_outlined,
                                      size: 54, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No se encontraron registros',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textoPrincipal,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Intenta cambiar o limpiar los filtros seleccionados',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textoSecundario,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _busquedaController.clear();
                                      provider.limpiarFiltros();
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Limpiar todos los filtros'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.cargarHistorial(),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(top: 8, bottom: 24),
                              itemCount: provider.items.length,
                              itemBuilder: (context, index) {
                                final item = provider.items[index];
                                return TarjetaItemHistorial(item: item);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ChipTipo extends StatelessWidget {
  final String etiqueta;
  final TipoRegistroHistorial tipo;
  final IconData? icono;
  final Color? color;
  final bool seleccionado;
  final VoidCallback onSelected;

  const _ChipTipo({
    required this.etiqueta,
    required this.tipo,
    this.icono,
    this.color,
    required this.seleccionado,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.senaVerde;
    return ChoiceChip(
      avatar: icono != null
          ? Icon(
              icono,
              size: 16,
              color: seleccionado ? Colors.white : chipColor,
            )
          : null,
      label: Text(etiqueta),
      selected: seleccionado,
      selectedColor: chipColor,
      labelStyle: TextStyle(
        color: seleccionado ? Colors.white : AppColors.textoPrincipal,
        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
