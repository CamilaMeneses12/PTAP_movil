import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/fila_registro.dart';
import '../../reports/screens/exportar_reportes_screen.dart';
import '../providers/historial_provider.dart';
import '../widgets/filtro_historial_sheet.dart';
import '../widgets/tarjeta_item_historial.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final TextEditingController _busquedaController = TextEditingController();
  int _filtroRapido = 0; // 0: Hoy, 1: 7 días, 2: 30 días, 3: Fuera de rango
  bool _vistaTablaCaudal = true; // Por defecto vista de tabla como el Figma

  // Datos de tabla caudal fieles a Figma (pantalla 04 Registros)
  final List<Map<String, dynamic>> _registrosFigma = [
    {
      'fecha': '17/11/2026',
      'hora': '08:00',
      'entrada': '129,0',
      'salida': '124,1',
      'volumen': '446,8',
      'fueraDeRango': false,
      'motivo': null,
    },
    {
      'fecha': '17/11/2026',
      'hora': '07:00',
      'entrada': '141,2',
      'salida': '134,6',
      'volumen': '484,6',
      'fueraDeRango': true,
      'motivo':
          'Caudal de entrada (141,2 L/s) superó el límite máximo operativo de 140,0 L/s (+1,2 L/s, +0,9 %). Riesgo de sobrecargar la floculación y sedimentación.',
    },
    {
      'fecha': '17/11/2026',
      'hora': '06:00',
      'entrada': '138,9',
      'salida': '132,0',
      'volumen': '478,1',
      'fueraDeRango': false,
      'motivo': null,
    },
    {
      'fecha': '17/11/2026',
      'hora': '05:00',
      'entrada': '133,5',
      'salida': '127,4',
      'volumen': '458,6',
      'fueraDeRango': false,
      'motivo': null,
    },
    {
      'fecha': '17/11/2026',
      'hora': '04:00',
      'entrada': '124,6',
      'salida': '118,9',
      'volumen': '428,0',
      'fueraDeRango': false,
      'motivo': null,
    },
    {
      'fecha': '17/11/2026',
      'hora': '03:00',
      'entrada': '110,8',
      'salida': '105,6',
      'volumen': '380,2',
      'fueraDeRango': false,
      'motivo': null,
    },
    {
      'fecha': '17/11/2026',
      'hora': '02:00',
      'entrada': '103,1',
      'salida': '98,2',
      'volumen': '353,5',
      'fueraDeRango': false,
      'motivo': null,
    },
    {
      'fecha': '17/11/2026',
      'hora': '01:00',
      'entrada': '104,9',
      'salida': '100,1',
      'volumen': '360,4',
      'fueraDeRango': false,
      'motivo': null,
    },
    {
      'fecha': '17/11/2026',
      'hora': '00:00',
      'entrada': '108,7',
      'salida': '103,8',
      'volumen': '373,7',
      'fueraDeRango': false,
      'motivo': null,
    },
    {
      'fecha': '16/11/2026',
      'hora': '23:00',
      'entrada': '113,6',
      'salida': '108,5',
      'volumen': '390,6',
      'fueraDeRango': false,
      'motivo': null,
    },
  ];

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistorialProvider>();
    final sesion = context.watch<SesionUsuarioProvider>();
    final puedeEditar = sesion.perfil?.puedeEditar ?? false;

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        backgroundColor: AppColors.fondoGeneral,
        elevation: 0,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registros',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipal,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Histórico de mediciones de caudal',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textoSecundario,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cambiar modo de visualización',
            icon: Icon(
              _vistaTablaCaudal ? Icons.view_agenda_outlined : Icons.table_chart_outlined,
              color: AppColors.azulMarino,
              size: 22,
            ),
            onPressed: () => setState(() => _vistaTablaCaudal = !_vistaTablaCaudal),
          ),
          IconButton(
            tooltip: 'Descargar / Exportar',
            icon: const Icon(Icons.file_download_outlined, color: AppColors.azulMarino, size: 22),
            onPressed: () => context.push(AppRoutes.exportar, extra: TipoFormatoExportar.historial),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Buscador con campo estilizado y botón de filtro
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.blanco,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.bordes),
                      ),
                      child: TextField(
                        controller: _busquedaController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por fecha u hora...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textoSecundario),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textoSecundario),
                          suffixIcon: _busquedaController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _busquedaController.clear();
                                    provider.setBusqueda('');
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                        onChanged: (val) {
                          provider.setBusqueda(val);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.azulMarino,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune_rounded, size: 20, color: AppColors.blanco),
                      onPressed: () => FiltroHistorialSheet.mostrar(context),
                      tooltip: 'Filtros avanzados',
                    ),
                  ),
                ],
              ),
            ),

            // 2. Chips de filtro rápido estilo Figma: Hoy | 7 días | 30 días | • Fuera de rango
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _ChipFiltroFigma(
                      etiqueta: 'Hoy',
                      seleccionado: _filtroRapido == 0,
                      alPulsar: () => setState(() => _filtroRapido = 0),
                    ),
                    const SizedBox(width: 8),
                    _ChipFiltroFigma(
                      etiqueta: '7 días',
                      seleccionado: _filtroRapido == 1,
                      alPulsar: () => setState(() => _filtroRapido = 1),
                    ),
                    const SizedBox(width: 8),
                    _ChipFiltroFigma(
                      etiqueta: '30 días',
                      seleccionado: _filtroRapido == 2,
                      alPulsar: () => setState(() => _filtroRapido = 2),
                    ),
                    const SizedBox(width: 8),
                    _ChipFiltroFigma(
                      etiqueta: 'Fuera de rango',
                      seleccionado: _filtroRapido == 3,
                      conPuntoRojo: true,
                      alPulsar: () => setState(() => _filtroRapido = 3),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Accesos rápidos a los 3 módulos del sistema
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _BotonAccesoModulo(
                      titulo: 'Fisicoquímicos',
                      icono: Icons.science_outlined,
                      alPulsar: () => context.push(AppRoutes.fisicoquimicos),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _BotonAccesoModulo(
                      titulo: 'Medidores',
                      icono: Icons.speed_outlined,
                      alPulsar: () => context.push(AppRoutes.medidores),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _BotonAccesoModulo(
                      titulo: 'Caudal La Seca',
                      icono: Icons.water_outlined,
                      alPulsar: () => context.push(AppRoutes.caudal),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // 4. Subencabezado de tabla y conteo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Martes 17 nov 2026 · Intervalo 1 h',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textoSecundario,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _vistaTablaCaudal
                        ? '${_registrosFiltrados.length} registros'
                        : '${provider.itemsFiltrados.length} registros',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textoSecundario,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // 5. Contenido principal (Tabla o Tarjetas)
            Expanded(
              child: _vistaTablaCaudal
                  ? _construirTablaCaudalFigma()
                  : _construirListaHistorial(provider),
            ),

            // 6. Botón flotante opcional si puede crear
            if (puedeEditar)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                color: AppColors.blanco,
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarMenuNuevoRegistro(context),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Nuevo registro en planta'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _registrosFiltrados {
    final busq = _busquedaController.text.trim().toLowerCase();
    return _registrosFigma.where((reg) {
      if (_filtroRapido == 3 && !(reg['fueraDeRango'] as bool)) {
        return false;
      }
      if (busq.isNotEmpty) {
        final f = (reg['fecha'] as String).toLowerCase();
        final h = (reg['hora'] as String).toLowerCase();
        if (!f.contains(busq) && !h.contains(busq)) return false;
      }
      return true;
    }).toList();
  }

  Widget _construirTablaCaudalFigma() {
    final registros = _registrosFiltrados;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordes, width: 1),
        boxShadow: AppColors.sombraSuave,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Encabezado de la tabla
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppColors.fondoGeneral,
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Fecha',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Entrada\n(L/s)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Salida\n(L/s)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Volumen\n(m³)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filas
            Expanded(
              child: ListView.builder(
                itemCount: registros.length,
                itemBuilder: (context, index) {
                  final reg = registros[index];
                  return FilaRegistro(
                    fecha: reg['fecha'] as String,
                    hora: reg['hora'] as String,
                    entrada: reg['entrada'] as String,
                    salida: reg['salida'] as String,
                    volumen: reg['volumen'] as String,
                    fueraDeRango: reg['fueraDeRango'] as bool,
                    mensajeExplicativo: reg['motivo'] as String?,
                  );
                },
              ),
            ),

            // Pie de tabla con leyenda y total
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.blanco,
                border: Border(top: BorderSide(color: AppColors.bordes, width: 0.8)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.critico,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Registro fuera de rango',
                            style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                          ),
                        ],
                      ),
                      const Text(
                        'Total: 4.286 m³',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Se cargaron registros históricos de jornadas previas')),
                        );
                      },
                      child: const Text('Cargar registros anteriores', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirListaHistorial(HistorialProvider provider) {
    if (provider.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = provider.itemsFiltrados;
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron registros con los filtros seleccionados',
          style: TextStyle(fontSize: 13, color: AppColors.textoSecundario),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return TarjetaItemHistorial(
          item: item,
        );
      },
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
              'Seleccionar Tipo de Registro',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.science_outlined, color: AppColors.azulPrimario),
              title: const Text('Análisis Fisicoquímico (DO-F-070)'),
              subtitle: const Text('pH, cloro, turbidez, color en red'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.fisicoquimicoNuevo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.speed_outlined, color: AppColors.turquesa),
              title: const Text('Lectura de Medidores'),
              subtitle: const Text('Balance hídrico y cálculo de pérdidas'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.medidoresNuevo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.water_outlined, color: AppColors.azulMarino),
              title: const Text('Aforo Caudal Quebrada La Seca'),
              subtitle: const Text('Método flotador y sección transversal'),
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

class _ChipFiltroFigma extends StatelessWidget {
  final String etiqueta;
  final bool seleccionado;
  final bool conPuntoRojo;
  final VoidCallback alPulsar;

  const _ChipFiltroFigma({
    required this.etiqueta,
    required this.seleccionado,
    this.conPuntoRojo = false,
    required this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alPulsar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.azulMarino : AppColors.blanco,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? AppColors.azulMarino : AppColors.bordes,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (conPuntoRojo) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.critico,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              etiqueta,
              style: TextStyle(
                fontSize: 12,
                fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
                color: seleccionado ? AppColors.blanco : AppColors.textoPrincipal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonAccesoModulo extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final VoidCallback alPulsar;

  const _BotonAccesoModulo({
    required this.titulo,
    required this.icono,
    required this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alPulsar,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.azulClaro.withAlpha(120),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 14, color: AppColors.azulPrimario),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.azulMarino,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
