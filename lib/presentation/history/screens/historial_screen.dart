import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../domain/telemetria/telemetria_planta.dart';
import '../../../domain/validators/validador_rangos.dart';
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

  /// Cuántos bloques de historial se muestran (cada "Cargar registros anteriores" suma uno).
  int _bloques = 1;

  static final _f1 = NumberFormat('#,##0.0', 'es_CO');
  static final _fecha = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _aplicarFiltroAlProveedor(),
    );
  }

  void _cambiarFiltro(int filtro) {
    setState(() {
      _filtroRapido = filtro;
      _bloques = 1;
    });
    _aplicarFiltroAlProveedor();
  }

  /// La vista de tarjetas usa el mismo periodo que la tabla.
  void _aplicarFiltroAlProveedor() {
    if (!mounted) return;
    final provider = context.read<HistorialProvider>();
    final hoy = TelemetriaPlanta.inicioDia(DateTime.now());
    final dias = switch (_filtroRapido) {
      0 => 1,
      1 => 7,
      _ => 30,
    };
    provider.setRangoFechas(hoy.subtract(Duration(days: dias - 1)), hoy);
    provider.setSoloAlertas(_filtroRapido == 3);
  }

  String get _textoPeriodo {
    final hoy = DateTime.now();
    switch (_filtroRapido) {
      case 0:
        final dia = DateFormat("EEE d 'de' MMM", 'es_ES').format(hoy);
        final extra = _bloques > 1
            ? ' y ${_bloques - 1} día(s) anteriores'
            : '';
        return 'Hoy, $dia$extra · Intervalo 1 h';
      case 1:
        return 'Últimos ${7 * _bloques} días · Promedio diario';
      case 2:
        return 'Últimos ${30 * _bloques} días · Promedio diario';
      default:
        return 'Horas fuera de rango · Últimos ${30 * _bloques} días';
    }
  }

  _FilaCaudal _filaHora(MuestraTelemetria m) {
    final evaluacion = ValidadorRangos.validarCaudalEntrada(m.caudalEntrada);
    return _FilaCaudal(
      fecha: _fecha.format(m.hora),
      hora: DateFormat('HH:00').format(m.hora),
      entrada: m.caudalEntrada,
      volumen: m.volumenM3,
      fueraDeRango: !evaluacion.cumple,
      motivo: evaluacion.cumple ? null : evaluacion.mensajeCompleto,
    );
  }

  _FilaCaudal _filaDia(ResumenPeriodo dia, DateTime ahora) {
    final fuera = dia.horasFueraDeRango;
    String? motivo;
    if (fuera.isNotEmpty) {
      final peor = fuera.reduce(
        (a, b) => _desvio(a.caudalEntrada) >= _desvio(b.caudalEntrada) ? a : b,
      );
      final evaluacion = ValidadorRangos.validarCaudalEntrada(
        peor.caudalEntrada,
      );
      motivo =
          '${fuera.length} ${fuera.length == 1 ? 'hora' : 'horas'} con caudal de entrada fuera del rango '
          '${_f1.format(ValidadorRangos.caudalEntradaMin)}–${_f1.format(ValidadorRangos.caudalEntradaMax)} L/s. '
          'La mayor desviación fue a las ${DateFormat('HH:00').format(peor.hora)}: ${evaluacion.mensajeCompleto}';
    }
    final esHoy = TelemetriaPlanta.inicioDia(ahora) == dia.inicio;
    return _FilaCaudal(
      fecha: _fecha.format(dia.inicio),
      hora: esHoy ? 'Hasta ${DateFormat('HH:00').format(ahora)}' : 'Prom. día',
      entrada: dia.entradaPromedio,
      volumen: dia.volumenM3,
      fueraDeRango: fuera.isNotEmpty,
      motivo: motivo,
    );
  }

  static double _desvio(double v) {
    if (v > ValidadorRangos.caudalEntradaMax) {
      return v - ValidadorRangos.caudalEntradaMax;
    }
    if (v < ValidadorRangos.caudalEntradaMin) {
      return ValidadorRangos.caudalEntradaMin - v;
    }
    return 0;
  }

  /// Filas de la tabla según el filtro: horas de hoy, días (7 o 30) u horas fuera de rango.
  List<_FilaCaudal> _filasCaudal() {
    final ahora = DateTime.now();
    final hoy = TelemetriaPlanta.inicioDia(ahora);
    final manana = hoy.add(const Duration(days: 1));
    switch (_filtroRapido) {
      case 0:
        final desde = hoy.subtract(Duration(days: _bloques - 1));
        return TelemetriaPlanta.rango(
          desde,
          manana,
          ahora: ahora,
        ).reversed.map(_filaHora).toList();
      case 1:
      case 2:
        final dias = (_filtroRapido == 1 ? 7 : 30) * _bloques;
        return TelemetriaPlanta.resumenDiario(
          hoy.subtract(Duration(days: dias - 1)),
          hoy,
          ahora: ahora,
        ).reversed.map((d) => _filaDia(d, ahora)).toList();
      default:
        final desde = hoy.subtract(Duration(days: 30 * _bloques - 1));
        return TelemetriaPlanta.rango(desde, manana, ahora: ahora)
            .where((m) => m.caudalFueraDeRango)
            .toList()
            .reversed
            .map(_filaHora)
            .toList();
    }
  }

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
              _vistaTablaCaudal
                  ? Icons.view_agenda_outlined
                  : Icons.table_chart_outlined,
              color: AppColors.azulMarino,
              size: 22,
            ),
            onPressed: () =>
                setState(() => _vistaTablaCaudal = !_vistaTablaCaudal),
          ),
          IconButton(
            tooltip: 'Descargar / Exportar',
            icon: const Icon(
              Icons.file_download_outlined,
              color: AppColors.azulMarino,
              size: 22,
            ),
            onPressed: () => context.push(
              AppRoutes.exportar,
              extra: TipoFormatoExportar.historial,
            ),
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
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textoSecundario,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: AppColors.textoSecundario,
                          ),
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
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
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
                      icon: const Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: AppColors.blanco,
                      ),
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
                      alPulsar: () => _cambiarFiltro(0),
                    ),
                    const SizedBox(width: 8),
                    _ChipFiltroFigma(
                      etiqueta: '7 días',
                      seleccionado: _filtroRapido == 1,
                      alPulsar: () => _cambiarFiltro(1),
                    ),
                    const SizedBox(width: 8),
                    _ChipFiltroFigma(
                      etiqueta: '30 días',
                      seleccionado: _filtroRapido == 2,
                      alPulsar: () => _cambiarFiltro(2),
                    ),
                    const SizedBox(width: 8),
                    _ChipFiltroFigma(
                      etiqueta: 'Fuera de rango',
                      seleccionado: _filtroRapido == 3,
                      conPuntoRojo: true,
                      alPulsar: () => _cambiarFiltro(3),
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
                  Flexible(
                    child: Text(
                      _vistaTablaCaudal
                          ? _textoPeriodo
                          : 'Registros de la planta · ${_textoPeriodo.split(' · ').first}',
                      key: const Key('texto_periodo'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textoSecundario,
                        fontWeight: FontWeight.w500,
                      ),
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

  List<_FilaCaudal> get _registrosFiltrados {
    final busq = _busquedaController.text.trim().toLowerCase();
    final filas = _filasCaudal();
    if (busq.isEmpty) return filas;
    return filas
        .where(
          (f) =>
              f.fecha.toLowerCase().contains(busq) ||
              f.hora.toLowerCase().contains(busq),
        )
        .toList();
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
                      'Vol. captado\n(m³)',
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
              child: registros.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _filtroRapido == 3
                              ? 'No hubo horas con caudal fuera de rango en este periodo.'
                              : 'No hay registros que coincidan con la búsqueda.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: registros.length,
                      itemBuilder: (context, index) {
                        final reg = registros[index];
                        return FilaRegistro(
                          fecha: reg.fecha,
                          hora: reg.hora,
                          entrada: _f1.format(reg.entrada),
                          volumen: _f1.format(reg.volumen),
                          fueraDeRango: reg.fueraDeRango,
                          mensajeExplicativo: reg.motivo,
                        );
                      },
                    ),
            ),

            // Pie de tabla con leyenda y total
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.blanco,
                border: Border(
                  top: BorderSide(color: AppColors.bordes, width: 0.8),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
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
                            const Flexible(
                              child: Text(
                                'Registro fuera de rango',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textoSecundario,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Total: ${NumberFormat('#,##0', 'es_CO').format(registros.fold(0.0, (t, r) => t + r.volumen))} m³',
                        style: const TextStyle(
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
                      onPressed: () => setState(() => _bloques++),
                      child: const Text(
                        'Cargar registros anteriores',
                        style: TextStyle(fontSize: 12),
                      ),
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
        return TarjetaItemHistorial(item: item);
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipal,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.science_outlined,
                color: AppColors.azulPrimario,
              ),
              title: const Text('Análisis Fisicoquímico (DO-F-070)'),
              subtitle: const Text('pH, cloro, turbidez, color en red'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.fisicoquimicoNuevo);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.speed_outlined,
                color: AppColors.turquesa,
              ),
              title: const Text('Lectura de Medidores'),
              subtitle: const Text('Balance hídrico y cálculo de pérdidas'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.medidoresNuevo);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.water_outlined,
                color: AppColors.azulMarino,
              ),
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
                color: seleccionado
                    ? AppColors.blanco
                    : AppColors.textoPrincipal,
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

/// Fila de la tabla de caudal (una hora o el promedio de un día).
class _FilaCaudal {
  final String fecha;
  final String hora;
  final double entrada;
  final double volumen;
  final bool fueraDeRango;
  final String? motivo;

  const _FilaCaudal({
    required this.fecha,
    required this.hora,
    required this.entrada,
    required this.volumen,
    required this.fueraDeRango,
    required this.motivo,
  });
}
