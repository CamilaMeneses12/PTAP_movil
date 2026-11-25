import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/registro_fisicoquimico.dart';
import '../../../domain/calculations/resumen_inicio.dart';
import '../../../domain/validators/validador_rangos.dart';
import '../../common/widgets/chip_estado.dart';
import '../../physicochemical/providers/fisicoquimico_provider.dart';
import '../providers/caudal_provider.dart';

/// Monitoreo de la planta con los registros reales del operario:
/// - Caudal: aforos de la Quebrada La Seca (método del flotador).
/// - Calidad: agua tratada del formato DO-F-070 (cloro residual, pH y turbidez).
/// No hay sensores conectados, así que no se muestra telemetría simulada.
class MonitoreoScreen extends StatefulWidget {
  const MonitoreoScreen({super.key});

  @override
  State<MonitoreoScreen> createState() => _MonitoreoScreenState();
}

class _Punto {
  final DateTime momento;
  final double valor;
  final bool fueraDeRango;
  const _Punto(this.momento, this.valor, this.fueraDeRango);
}

class _VistaMonitoreo {
  final String titulo;
  final String subtitulo;
  final String unidad;
  final List<_Punto> puntos;
  final double? minimo;
  final double? maximo;
  final String textoRango;
  final String textoVacio;

  const _VistaMonitoreo({
    required this.titulo,
    required this.subtitulo,
    required this.unidad,
    required this.puntos,
    required this.minimo,
    required this.maximo,
    required this.textoRango,
    required this.textoVacio,
  });
}

enum _ParametroCalidad { cloro, ph, turbidez }

class _MonitoreoScreenState extends State<MonitoreoScreen> {
  int _indiceSubpestana = 0; // 0: Caudal, 1: Calidad
  _ParametroCalidad _parametro = _ParametroCalidad.cloro;

  /// Cantidad de registros que se grafican.
  static const _cantidad = 15;

  static final _num = NumberFormat('#,##0.0#', 'es_CO');

  List<T> _ultimos<T>(List<T> lista) =>
      lista.length > _cantidad ? lista.sublist(lista.length - _cantidad) : lista;

  _VistaMonitoreo _vistaCaudal(CaudalProvider caudal) {
    final aforos = [...caudal.aforos]
      ..sort((a, b) => momentoRegistro(a.fecha, a.hora).compareTo(momentoRegistro(b.fecha, b.hora)));
    final ultimos = _ultimos(aforos);
    return _VistaMonitoreo(
      titulo: 'Caudal de la Quebrada La Seca',
      subtitulo: 'Aforos con flotador · últimos ${ultimos.length} registros',
      unidad: 'L/s',
      puntos: [
        for (final a in ultimos) _Punto(momentoRegistro(a.fecha, a.hora), a.caudalLS, a.fueraDeRango),
      ],
      minimo: null,
      maximo: null,
      textoRango: 'Caudal calculado en cada aforo',
      textoVacio: 'Aún no hay aforos registrados.',
    );
  }

  _VistaMonitoreo _vistaCalidad(FisicoquimicoProvider fisico) {
    final (nombre, unidad, min, max, valor, evaluar) = switch (_parametro) {
      _ParametroCalidad.cloro => (
          'Cloro residual libre',
          'mg/L',
          ValidadorRangos.cloroMin as double?,
          ValidadorRangos.cloroMax,
          (RegistroFisicoquimico r) => r.cloradaCloroResidual,
          (double v) => ValidadorRangos.validarCloroResidual(v),
        ),
      _ParametroCalidad.ph => (
          'pH del agua tratada',
          'pH',
          ValidadorRangos.phTratadaMin as double?,
          ValidadorRangos.phTratadaMax,
          (RegistroFisicoquimico r) => r.cloradaPh,
          (double v) => ValidadorRangos.validarPhTratada(v),
        ),
      _ParametroCalidad.turbidez => (
          'Turbidez del agua tratada',
          'NTU',
          null as double?,
          ValidadorRangos.turbidezTratadaMax,
          (RegistroFisicoquimico r) => r.cloradaTurbidez,
          (double v) => ValidadorRangos.validarTurbidezTratada(v),
        ),
    };
    final registros = fisico.registros.where((r) => valor(r) != null).toList()
      ..sort((a, b) => momentoRegistro(a.fecha, a.hora).compareTo(momentoRegistro(b.fecha, b.hora)));
    final ultimos = _ultimos(registros);
    final u = unidad == 'pH' ? '' : ' $unidad';
    return _VistaMonitoreo(
      titulo: nombre,
      subtitulo: 'Formato DO-F-070 · últimos ${ultimos.length} registros',
      unidad: unidad,
      puntos: [
        for (final r in ultimos)
          _Punto(momentoRegistro(r.fecha, r.hora), valor(r)!, !evaluar(valor(r)!).cumple),
      ],
      minimo: min,
      maximo: max,
      textoRango: min == null ? 'Máximo ${_num.format(max)}$u' : 'Rango ${_num.format(min)}–${_num.format(max)}$u',
      textoVacio: 'Aún no hay registros DO-F-070 con este parámetro.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final caudal = context.watch<CaudalProvider>();
    final fisico = context.watch<FisicoquimicoProvider>();
    final vista = _indiceSubpestana == 0 ? _vistaCaudal(caudal) : _vistaCalidad(fisico);

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
              'Monitoreo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipal,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Según los registros del operario',
              style: TextStyle(fontSize: 11, color: AppColors.textoSecundario, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.azulMarino, size: 22),
            tooltip: 'Actualizar',
            onPressed: () {
              caudal.cargarAforos();
              fisico.cargarRegistros();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Segmented control: Caudal | Calidad
            Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.bordes.withAlpha(140),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _SegmentButton(
                    texto: 'Caudal',
                    seleccionado: _indiceSubpestana == 0,
                    alPulsar: () => setState(() => _indiceSubpestana = 0),
                  ),
                  _SegmentButton(
                    texto: 'Calidad',
                    seleccionado: _indiceSubpestana == 1,
                    alPulsar: () => setState(() => _indiceSubpestana = 1),
                  ),
                ],
              ),
            ),
            if (_indiceSubpestana == 1) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final (p, texto) in const [
                    (_ParametroCalidad.cloro, 'Cloro residual'),
                    (_ParametroCalidad.ph, 'pH'),
                    (_ParametroCalidad.turbidez, 'Turbidez'),
                  ])
                    ChoiceChip(
                      label: Text(texto, style: const TextStyle(fontSize: 12)),
                      selected: _parametro == p,
                      onSelected: (_) => setState(() => _parametro = p),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            _TarjetaGrafica(
              key: ValueKey('grafica_monitoreo_${_indiceSubpestana}_${_parametro.name}'),
              vista: vista,
            ),

            const SizedBox(height: 16),

            const Text(
              'Etapas del proceso',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
            ),
            const SizedBox(height: 4),
            const Text(
              'Valores del último aforo y del último registro DO-F-070',
              style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
            ),
            const SizedBox(height: 10),
            ..._etapas(caudal, fisico),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _etapas(CaudalProvider caudal, FisicoquimicoProvider fisico) {
    final aforo = ResumenInicio.caudalQuebrada(caudal.aforos)?.ultimo;
    final calidad = ResumenInicio.calidadAguaTratada(fisico.registros);
    final r = calidad?.registro;
    const sinDato = 'Sin registros';

    TipoEstadoPlanta estado(bool fuera) => fuera ? TipoEstadoPlanta.enAlerta : TipoEstadoPlanta.operativa;
    String valor(double? v, String unidad) => v == null ? 'sin dato' : '${_num.format(v)} $unidad';

    final dosis = r?.crudaDosisCoagulante;
    final turbFiltrada = r?.filtradaTurbidez;

    return [
      _ItemEtapaProceso(
        numero: '1',
        nombre: 'Captación',
        detalle: aforo == null ? sinDato : 'Caudal de la quebrada ${valor(aforo.caudalLS, 'L/s')}',
        estado: aforo == null ? null : estado(aforo.fueraDeRango),
      ),
      _ItemEtapaProceso(
        numero: '2',
        nombre: 'Coagulación y floculación',
        detalle: r == null
            ? sinDato
            : (dosis == null || dosis.trim().isEmpty ? 'Dosis de coagulante sin dato' : 'Dosis de coagulante $dosis'),
        estado: null,
      ),
      _ItemEtapaProceso(
        numero: '3',
        nombre: 'Filtración',
        detalle: r == null ? sinDato : 'Turbidez agua filtrada ${valor(turbFiltrada, 'NTU')}',
        estado: turbFiltrada == null
            ? null
            : estado(!ValidadorRangos.validarTurbidezTratada(turbFiltrada).cumple),
      ),
      _ItemEtapaProceso(
        numero: '4',
        nombre: 'Desinfección',
        detalle: r == null ? sinDato : 'Cloro residual ${valor(r.cloradaCloroResidual, 'mg/L')}',
        estado: r?.cloradaCloroResidual == null ? null : estado(!calidad!.cloro.cumple),
      ),
    ];
  }
}

class _TarjetaGrafica extends StatelessWidget {
  final _VistaMonitoreo vista;

  const _TarjetaGrafica({super.key, required this.vista});

  static final _num = NumberFormat('#,##0.0#', 'es_CO');

  @override
  Widget build(BuildContext context) {
    final u = vista.unidad == 'pH' ? '' : ' ${vista.unidad}';
    final puntos = vista.puntos;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordes, width: 1),
        boxShadow: AppColors.sombraSuave,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vista.titulo,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
          ),
          const SizedBox(height: 2),
          Text(vista.subtitulo, style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
          const SizedBox(height: 12),
          if (puntos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(vista.textoVacio, style: const TextStyle(fontSize: 13, color: AppColors.textoSecundario)),
              ),
            )
          else ...[
            Text.rich(
              TextSpan(
                text: 'Último ',
                style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                children: [
                  TextSpan(
                    text: _num.format(puntos.last.valor),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: puntos.last.fueraDeRango ? AppColors.critico : AppColors.textoPrincipal,
                    ),
                  ),
                  TextSpan(text: '$u · ${DateFormat('dd/MM/yyyy HH:mm').format(puntos.last.momento)}'),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              vista.textoRango,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textoSecundario),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 170, child: _grafica(u)),
            const SizedBox(height: 12),
            _resumen(u),
          ],
        ],
      ),
    );
  }

  Widget _grafica(String u) {
    final puntos = vista.puntos;
    final valores = puntos.map((p) => p.valor).toList();
    final limites = [...valores, ?vista.minimo, ?vista.maximo];
    final bajo = limites.reduce(math.min);
    final alto = limites.reduce(math.max);
    final margen = alto == bajo ? (alto.abs() * 0.2 + 1) : (alto - bajo) * 0.15;
    final ultimo = puntos.length - 1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.bordes, strokeWidth: 0.8),
        ),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            if (vista.maximo != null)
              HorizontalRangeAnnotation(
                y1: vista.minimo ?? math.max(0, bajo - margen),
                y2: vista.maximo!,
                color: AppColors.exito.withAlpha(26),
              ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.azulMarino,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${DateFormat('dd/MM HH:mm').format(puntos[s.x.toInt()].momento)}\n${_num.format(s.y)}$u',
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) => (value == meta.min || value == meta.max)
                  ? const SizedBox.shrink()
                  : Text(_num.format(value), style: const TextStyle(fontSize: 9, color: AppColors.textoSecundario)),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (value != i.toDouble() || i < 0 || i > ultimo) return const SizedBox.shrink();
                final paso = math.max(1, (puntos.length / 5).ceil());
                if (i != ultimo && (i % paso != 0 || ultimo - i < paso / 2)) return const SizedBox.shrink();
                return Text(
                  DateFormat('dd/MM').format(puntos[i].momento),
                  style: const TextStyle(fontSize: 9, color: AppColors.textoSecundario),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: math.max(1, ultimo).toDouble(),
        minY: bajo - margen,
        maxY: alto + margen,
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < puntos.length; i++) FlSpot(i.toDouble(), puntos[i].valor)],
            color: AppColors.azulPrimario,
            barWidth: 2.5,
            belowBarData: BarAreaData(show: true, color: AppColors.azulPrimario.withAlpha(22)),
            dotData: FlDotData(
              getDotPainter: (spot, _, _, index) => FlDotCirclePainter(
                radius: puntos[index].fueraDeRango ? 4.5 : 3,
                color: puntos[index].fueraDeRango ? AppColors.critico : AppColors.azulPrimario,
                strokeWidth: 2,
                strokeColor: AppColors.blanco,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumen(String u) {
    final valores = vista.puntos.map((p) => p.valor).toList();
    final maximo = valores.reduce(math.max);
    final minimo = valores.reduce(math.min);
    final promedio = valores.reduce((a, b) => a + b) / valores.length;
    final fuera = vista.puntos.where((p) => p.fueraDeRango).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.fondoGeneral, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(child: _MiniEstadistica(label: 'Máximo', valor: '${_num.format(maximo)}$u')),
          Expanded(child: _MiniEstadistica(label: 'Mínimo', valor: '${_num.format(minimo)}$u')),
          Expanded(child: _MiniEstadistica(label: 'Promedio', valor: '${_num.format(promedio)}$u')),
          Expanded(child: _MiniEstadistica(label: 'Fuera de rango', valor: '$fuera', esAlerta: fuera > 0)),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String texto;
  final bool seleccionado;
  final VoidCallback alPulsar;

  const _SegmentButton({required this.texto, required this.seleccionado, required this.alPulsar});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: alPulsar,
        child: Container(
          decoration: BoxDecoration(
            color: seleccionado ? AppColors.blanco : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: seleccionado ? AppColors.sombraSuave : null,
          ),
          alignment: Alignment.center,
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
              color: seleccionado ? AppColors.azulMarino : AppColors.textoSecundario,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniEstadistica extends StatelessWidget {
  final String label;
  final String valor;
  final bool esAlerta;

  const _MiniEstadistica({required this.label, required this.valor, this.esAlerta = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: AppColors.textoSecundario),
        ),
        const SizedBox(height: 1),
        Text(
          valor,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: esAlerta ? AppColors.critico : AppColors.textoPrincipal,
          ),
        ),
      ],
    );
  }
}

class _ItemEtapaProceso extends StatelessWidget {
  final String numero;
  final String nombre;
  final String detalle;

  /// null cuando no hay un valor que comparar con un rango.
  final TipoEstadoPlanta? estado;

  const _ItemEtapaProceso({required this.numero, required this.nombre, required this.detalle, required this.estado});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordes, width: 0.9),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(color: AppColors.azulClaro, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              numero,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.azulMarino),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textoPrincipal),
                ),
                const SizedBox(height: 1),
                Text(detalle, style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
              ],
            ),
          ),
          if (estado != null)
            ChipEstado(
              estado: estado!,
              compacto: true,
              textoPersonalizado: estado == TipoEstadoPlanta.enAlerta ? 'Fuera de rango' : 'En rango',
            ),
        ],
      ),
    );
  }
}
