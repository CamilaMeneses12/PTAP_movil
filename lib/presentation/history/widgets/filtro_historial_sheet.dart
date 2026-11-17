import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/historial_provider.dart';

/// Hoja modal inferior para configurar filtros avanzados de historial
class FiltroHistorialSheet extends StatefulWidget {
  const FiltroHistorialSheet({super.key});

  static Future<void> mostrar(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FiltroHistorialSheet(),
    );
  }

  @override
  State<FiltroHistorialSheet> createState() => _FiltroHistorialSheetState();
}

class _FiltroHistorialSheetState extends State<FiltroHistorialSheet> {
  DateTime? _fechaInicioTemp;
  DateTime? _fechaFinTemp;
  String? _usuarioTemp;
  bool _soloAlertasTemp = false;

  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final p = context.read<HistorialProvider>();
    _fechaInicioTemp = p.fechaInicio;
    _fechaFinTemp = p.fechaFin;
    _usuarioTemp = p.usuarioSeleccionado;
    _soloAlertasTemp = p.soloAlertas;
  }

  Future<void> _seleccionarRangoFechas() async {
    final ahora = DateTime.now();
    final initialDateRange = (_fechaInicioTemp != null && _fechaFinTemp != null)
        ? DateTimeRange(start: _fechaInicioTemp!, end: _fechaFinTemp!)
        : DateTimeRange(
            start: ahora.subtract(const Duration(days: 30)),
            end: ahora,
          );

    final resultado = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: initialDateRange,
      helpText: 'SELECCIONAR RANGO DE FECHAS',
      cancelText: 'CANCELAR',
      confirmText: 'APLICAR',
      saveText: 'LISTO',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.azulInstitucional,
              onPrimary: Colors.white,
              onSurface: AppColors.textoPrincipal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (resultado != null) {
      setState(() {
        _fechaInicioTemp = resultado.start;
        _fechaFinTemp = resultado.end;
      });
    }
  }

  void _establecerAtajoFecha(int dias) {
    final ahora = DateTime.now();
    setState(() {
      _fechaInicioTemp = ahora.subtract(Duration(days: dias));
      _fechaFinTemp = ahora;
    });
  }

  void _limpiarTodo() {
    setState(() {
      _fechaInicioTemp = null;
      _fechaFinTemp = null;
      _usuarioTemp = null;
      _soloAlertasTemp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistorialProvider>();
    final usuarios = ['Todos', ...provider.usuariosDisponibles];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra superior de agarre
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtros Avanzados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoPrincipal,
                  ),
                ),
                TextButton.icon(
                  onPressed: _limpiarTodo,
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                  label: const Text(
                    'Restablecer',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Sección 1: Rango de Fechas
            const Text(
              'Rango de Fechas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),

            // Botón de selector de fechas
            InkWell(
              onTap: _seleccionarRangoFechas,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 20, color: AppColors.senaVerde),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (_fechaInicioTemp != null && _fechaFinTemp != null)
                            ? '${_formatoFecha.format(_fechaInicioTemp!)} - ${_formatoFecha.format(_fechaFinTemp!)}'
                            : 'Cualquier fecha (Sin límite)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: (_fechaInicioTemp != null)
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: (_fechaInicioTemp != null)
                              ? AppColors.senaVerde
                              : AppColors.textoSecundario,
                        ),
                      ),
                    ),
                    if (_fechaInicioTemp != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _fechaInicioTemp = null;
                            _fechaFinTemp = null;
                          });
                        },
                      )
                    else
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Atajos rápidos de fecha
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Últimos 7 días', style: TextStyle(fontSize: 12)),
                  onPressed: () => _establecerAtajoFecha(7),
                ),
                ActionChip(
                  label: const Text('Últimos 30 días', style: TextStyle(fontSize: 12)),
                  onPressed: () => _establecerAtajoFecha(30),
                ),
                ActionChip(
                  label: const Text('Último año', style: TextStyle(fontSize: 12)),
                  onPressed: () => _establecerAtajoFecha(365),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sección 2: Filtrar por Operario / Responsable
            const Text(
              'Operario / Responsable',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: (_usuarioTemp != null && usuarios.contains(_usuarioTemp))
                  ? _usuarioTemp
                  : 'Todos',
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.azulTecnologico),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: usuarios.map((user) {
                return DropdownMenuItem<String>(
                  value: user,
                  child: Text(user),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _usuarioTemp = (val == 'Todos') ? null : val;
                });
              },
            ),
            const SizedBox(height: 16),

            // Sección 3: Interruptor Solo Alertas
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Solo alertas y fuera de norma',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textoPrincipal,
                ),
              ),
              subtitle: const Text(
                'Muestra registros con parámetros fuera de Res. 2115 o pérdidas altas',
                style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
              ),
              activeThumbColor: AppColors.alerta,
              value: _soloAlertasTemp,
              onChanged: (val) {
                setState(() {
                  _soloAlertasTemp = val;
                });
              },
            ),
            const SizedBox(height: 20),

            // Botón aplicar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulInstitucional,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final p = context.read<HistorialProvider>();
                p.setRangoFechas(_fechaInicioTemp, _fechaFinTemp);
                p.setUsuario(_usuarioTemp);
                p.setSoloAlertas(_soloAlertasTemp);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Aplicar Filtros',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
