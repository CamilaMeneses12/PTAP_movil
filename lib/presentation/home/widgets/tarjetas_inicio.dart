import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/medidores_modelos.dart';
import '../../../domain/calculations/resumen_inicio.dart';
import '../../../domain/validators/validador_rangos.dart';

final _num = NumberFormat('#,##0.0#', 'es_CO');
final _num2 = NumberFormat('#,##0.00', 'es_CO');
final _fecha = DateFormat('dd/MM/yyyy');

String _cuando(DateTime fecha, String hora) => '${_fecha.format(fecha)} · $hora';

/// Marco común de las tarjetas del Inicio.
class TarjetaInicio extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color colorIcono;
  final Widget child;
  final VoidCallback? alPulsar;
  final Widget? accion;

  const TarjetaInicio({
    super.key,
    required this.titulo,
    required this.icono,
    required this.child,
    this.colorIcono = AppColors.azulPrimario,
    this.alPulsar,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordes),
        boxShadow: AppColors.sombraSuave,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: alPulsar,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icono, size: 18, color: colorIcono),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                    ),
                    ?accion,
                    if (alPulsar != null && accion == null)
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textoSecundario),
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado vacío: "Aún no hay registros · Registrar ahora".
class EstadoVacioInicio extends StatelessWidget {
  final VoidCallback? alRegistrar;
  final String texto;

  const EstadoVacioInicio({super.key, this.alRegistrar, this.texto = 'Aún no hay registros'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.inbox_outlined, size: 18, color: AppColors.textoSecundario),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
          ),
        ),
        if (alRegistrar != null) ...[
          const Text(' · ', style: TextStyle(fontSize: 12, color: AppColors.textoSecundario)),
          InkWell(
            onTap: alRegistrar,
            child: const Text(
              'Registrar ahora',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.azulPrimario),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final Color color;
  final Color fondo;

  const _Chip(this.texto, this.color, this.fondo);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(12)),
      child: Text(texto, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. Pendientes de hoy
// -----------------------------------------------------------------------------
class TarjetaPendientesHoy extends StatelessWidget {
  final Map<FormatoDiario, bool> estado;
  final void Function(FormatoDiario formato)? alAbrirFormulario;

  const TarjetaPendientesHoy({super.key, required this.estado, this.alAbrirFormulario});

  static const _nombres = {
    FormatoDiario.fisicoquimico: ('DO-F-070 · Análisis fisicoquímico', Icons.science_outlined),
    FormatoDiario.medidores: ('Medidores · Balance de agua', Icons.speed_outlined),
    FormatoDiario.aforo: ('Aforo · Quebrada La Seca', Icons.water_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final hechos = estado.values.where((v) => v).length;
    return TarjetaInicio(
      titulo: 'Pendientes de hoy',
      icono: Icons.checklist_rounded,
      accion: Text(
        '$hechos de ${estado.length}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textoSecundario),
      ),
      child: Column(
        children: [
          for (final f in FormatoDiario.values)
            _FilaPendiente(
              key: Key('pendiente_${f.name}'),
              nombre: _nombres[f]!.$1,
              icono: _nombres[f]!.$2,
              hecho: estado[f] ?? false,
              alPulsar: (estado[f] ?? false) || alAbrirFormulario == null ? null : () => alAbrirFormulario!(f),
            ),
        ],
      ),
    );
  }
}

class _FilaPendiente extends StatelessWidget {
  final String nombre;
  final IconData icono;
  final bool hecho;
  final VoidCallback? alPulsar;

  const _FilaPendiente({super.key, required this.nombre, required this.icono, required this.hecho, this.alPulsar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alPulsar,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icono, size: 18, color: AppColors.textoSecundario),
            const SizedBox(width: 10),
            Expanded(
              child: Text(nombre, style: const TextStyle(fontSize: 13, color: AppColors.textoPrincipal)),
            ),
            if (hecho)
              const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.exito)
            else ...[
              const _Chip('Pendiente', AppColors.advertencia, AppColors.advertenciaFondo),
              if (alPulsar != null)
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textoSecundario),
            ],
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. Calidad del agua tratada
// -----------------------------------------------------------------------------
class TarjetaCalidadAgua extends StatelessWidget {
  final CalidadAguaTratada? calidad;
  final VoidCallback? alRegistrar;
  final VoidCallback? alVerDetalle;

  const TarjetaCalidadAgua({super.key, required this.calidad, this.alRegistrar, this.alVerDetalle});

  @override
  Widget build(BuildContext context) {
    final c = calidad;
    return TarjetaInicio(
      titulo: 'Calidad del agua tratada',
      icono: Icons.water_drop_outlined,
      alPulsar: c == null ? null : alVerDetalle,
      accion: c == null
          ? null
          : (c.conforme
              ? const _Chip('Conforme', AppColors.exito, AppColors.exitoFondo)
              : const _Chip('Fuera de rango', AppColors.critico, AppColors.criticoFondo)),
      child: c == null
          ? EstadoVacioInicio(alRegistrar: alRegistrar)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _ValorParametro('Cloro residual', c.cloro, 'mg/L')),
                    Expanded(child: _ValorParametro('pH', c.ph, '')),
                    Expanded(child: _ValorParametro('Turbidez', c.turbidez, 'NTU')),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'DO-F-070 · ${_cuando(c.registro.fecha, c.registro.hora)} · ${c.registro.responsableNombre}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                ),
              ],
            ),
    );
  }
}

class _ValorParametro extends StatelessWidget {
  final String nombre;
  final EvaluacionRango evaluacion;
  final String unidad;

  const _ValorParametro(this.nombre, this.evaluacion, this.unidad);

  @override
  Widget build(BuildContext context) {
    final v = evaluacion.valor;
    final color = v == null
        ? AppColors.textoSecundario
        : (evaluacion.cumple ? AppColors.textoPrincipal : AppColors.critico);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nombre, style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            text: v == null ? '—' : _num.format(v),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
            children: [
              if (v != null && unidad.isNotEmpty)
                TextSpan(
                  text: ' $unidad',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textoSecundario),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 3. Tendencia de cloro residual
// -----------------------------------------------------------------------------
class TarjetaTendenciaCloro extends StatelessWidget {
  final List<({DateTime momento, double valor})> puntos;
  final VoidCallback? alRegistrar;

  const TarjetaTendenciaCloro({super.key, required this.puntos, this.alRegistrar});

  @override
  Widget build(BuildContext context) {
    final min = ValidadorRangos.cloroMin;
    final max = ValidadorRangos.cloroMax;
    return TarjetaInicio(
      titulo: 'Tendencia de cloro residual',
      icono: Icons.show_chart_rounded,
      child: puntos.isEmpty
          ? EstadoVacioInicio(alRegistrar: alRegistrar)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Últimos ${puntos.length} registros DO-F-070 · banda permitida ${_num.format(min)}–${_num.format(max)} mg/L',
                  style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 12),
                SizedBox(height: 110, child: _grafica(min, max)),
              ],
            ),
    );
  }

  Widget _grafica(double min, double max) {
    final valores = puntos.map((p) => p.valor);
    final bajo = math.min(0.0, valores.reduce(math.min));
    final alto = math.max(max, valores.reduce(math.max)) * 1.15;
    bool fuera(double v) => v < min || v > max;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, puntos.length - 1).toDouble(),
        minY: bajo,
        maxY: alto,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(y1: min, y2: max, color: AppColors.exito.withAlpha(30)),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) => (v == meta.min || v == meta.max)
                  ? const SizedBox.shrink()
                  : Text(_num.format(v), style: const TextStyle(fontSize: 9, color: AppColors.textoSecundario)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 18,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= puntos.length || v != i.toDouble()) return const SizedBox.shrink();
                return Text(
                  DateFormat('dd/MM').format(puntos[i].momento),
                  style: const TextStyle(fontSize: 9, color: AppColors.textoSecundario),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.azulMarino,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${DateFormat('dd/MM HH:mm').format(puntos[s.x.toInt()].momento)}\n${_num.format(s.y)} mg/L',
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < puntos.length; i++) FlSpot(i.toDouble(), puntos[i].valor)],
            color: AppColors.azulPrimario,
            barWidth: 2.2,
            isCurved: false,
            dotData: FlDotData(
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 3.5,
                color: fuera(spot.y) ? AppColors.critico : AppColors.azulPrimario,
                strokeWidth: 1.5,
                strokeColor: AppColors.blanco,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. Caudal de la Quebrada La Seca
// -----------------------------------------------------------------------------
class TarjetaCaudalQuebrada extends StatelessWidget {
  final CaudalQuebrada? caudal;
  final VoidCallback? alRegistrar;
  final VoidCallback? alVerDetalle;

  const TarjetaCaudalQuebrada({super.key, required this.caudal, this.alRegistrar, this.alVerDetalle});

  @override
  Widget build(BuildContext context) {
    final c = caudal;
    return TarjetaInicio(
      titulo: 'Caudal de la Quebrada La Seca',
      icono: Icons.waves_rounded,
      colorIcono: AppColors.turquesa,
      alPulsar: c == null ? null : alVerDetalle,
      child: c == null
          ? EstadoVacioInicio(alRegistrar: alRegistrar)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _num2.format(c.ultimo.caudalLS),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
                    ),
                    const Text(' L/s', style: TextStyle(fontSize: 12, color: AppColors.textoSecundario)),
                    const SizedBox(width: 12),
                    if (c.diferenciaLS != null) _Variacion(c.diferenciaLS!),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Último aforo · ${_cuando(c.ultimo.fecha, c.ultimo.hora)}'
                  '${c.anterior == null ? ' · primer aforo registrado' : ' · frente al aforo anterior'}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                ),
              ],
            ),
    );
  }
}

class _Variacion extends StatelessWidget {
  final double diferencia;
  const _Variacion(this.diferencia);

  @override
  Widget build(BuildContext context) {
    final sube = diferencia > 0;
    final igual = diferencia.abs() < 0.005;
    final icono = igual ? Icons.remove_rounded : (sube ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded);
    final texto = igual ? 'Sin cambio' : '${sube ? '+' : '−'}${_num2.format(diferencia.abs())} L/s';
    return Row(
      key: const Key('variacion_caudal'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: AppColors.azulMarino),
        const SizedBox(width: 2),
        Text(texto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.azulMarino)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 5. Pérdidas de agua
// -----------------------------------------------------------------------------
class TarjetaPerdidasAgua extends StatelessWidget {
  final JornadaMedidores? jornada;
  final VoidCallback? alRegistrar;
  final VoidCallback? alVerDetalle;

  const TarjetaPerdidasAgua({super.key, required this.jornada, this.alRegistrar, this.alVerDetalle});

  @override
  Widget build(BuildContext context) {
    final j = jornada;
    final elevada = j != null && ResumenInicio.perdidaElevada(j);
    final colorPerdida = elevada ? AppColors.advertencia : AppColors.textoPrincipal;
    return TarjetaInicio(
      titulo: 'Pérdidas de agua',
      icono: Icons.water_damage_outlined,
      colorIcono: elevada ? AppColors.advertencia : AppColors.azulPrimario,
      alPulsar: j == null ? null : alVerDetalle,
      accion: elevada ? const _Chip('Pérdida elevada', AppColors.advertencia, AppColors.advertenciaFondo) : null,
      child: j == null
          ? EstadoVacioInicio(alRegistrar: alRegistrar)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _Dato('Macromedidor', '${_num2.format(j.consumoMacromedidor)} m³')),
                    Expanded(child: _Dato('No registrada', '${_num2.format(j.aguaNoRegistrada)} m³', color: colorPerdida)),
                    Expanded(child: _Dato('Pérdida', '${_num.format(j.porcentajePerdida)} %', color: colorPerdida)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Última jornada · ${_cuando(j.fecha, j.hora)}'
                  '${elevada ? ' · supera ${_num.format(ResumenInicio.perdidaElevadaM3)} m³' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                ),
              ],
            ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color color;

  const _Dato(this.etiqueta, this.valor, {this.color = AppColors.textoPrincipal});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
        const SizedBox(height: 2),
        Text(valor, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 6. Alertas activas
// -----------------------------------------------------------------------------
class TarjetaAlertasActivas extends StatelessWidget {
  final ResumenAlertas resumen;
  final VoidCallback? alPulsar;

  const TarjetaAlertasActivas({super.key, required this.resumen, this.alPulsar});

  @override
  Widget build(BuildContext context) {
    final reciente = resumen.masReciente;
    return TarjetaInicio(
      key: const Key('tarjeta_alertas_activas'),
      titulo: 'Alertas activas',
      icono: Icons.notifications_active_outlined,
      colorIcono: resumen.criticas > 0 ? AppColors.critico : AppColors.azulPrimario,
      alPulsar: alPulsar,
      child: resumen.total == 0
          ? const EstadoVacioInicio(texto: 'No hay alertas activas')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Contador(resumen.criticas, 'Críticas', AppColors.critico),
                    _Contador(resumen.advertencias, 'Advertencias', AppColors.advertencia),
                    _Contador(resumen.informativas, 'Informativas', AppColors.informacion),
                  ],
                ),
                if (reciente != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Más reciente: ${reciente.titulo}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textoPrincipal),
                  ),
                ],
              ],
            ),
    );
  }
}

class _Contador extends StatelessWidget {
  final int cantidad;
  final String etiqueta;
  final Color color;

  const _Contador(this.cantidad, this.etiqueta, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$cantidad',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cantidad > 0 ? color : AppColors.textoSecundario,
            ),
          ),
          Text(etiqueta, style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
        ],
      ),
    );
  }
}
