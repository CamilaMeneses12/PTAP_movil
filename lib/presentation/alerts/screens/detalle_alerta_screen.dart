import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/alerta_sistema_modelo.dart';
import '../../../domain/alertas/catalogo_parametros_alerta.dart';
import '../../../domain/calculations/resumen_inicio.dart';
import '../../../domain/validators/validador_rangos.dart';
import '../../auth/providers/auth_provider.dart';
import '../../flow/providers/caudal_provider.dart';
import '../../meters/providers/medidores_provider.dart';
import '../../physicochemical/providers/fisicoquimico_provider.dart';
import '../providers/alertas_provider.dart';

final _num = NumberFormat('#,##0.0#', 'es_CO');
final _fechaHora = DateFormat('dd/MM/yyyy HH:mm');

/// Detalle de una alerta: qué pasó, dónde y cuándo, historial del parámetro, posibles causas,
/// norma y seguimiento. Abrirlo la marca como leída, no como resuelta.
class DetalleAlertaScreen extends StatefulWidget {
  final String alertaId;

  const DetalleAlertaScreen({super.key, required this.alertaId});

  @override
  State<DetalleAlertaScreen> createState() => _DetalleAlertaScreenState();
}

class _DetalleAlertaScreenState extends State<DetalleAlertaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AlertasProvider>().marcarLeida(widget.alertaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final alerta = context.watch<AlertasProvider>().buscar(widget.alertaId);
    final fisico = context.watch<FisicoquimicoProvider>();
    final medidores = context.watch<MedidoresProvider>();
    final caudal = context.watch<CaudalProvider>();

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        backgroundColor: AppColors.fondoGeneral,
        elevation: 0,
        title: const Text(
          'Detalle de alerta',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
        ),
      ),
      body: alerta == null
          ? const Center(
              child: Text('La alerta ya no existe.', style: TextStyle(color: AppColors.textoSecundario)),
            )
          : _contenido(context, alerta, fisico, medidores, caudal),
    );
  }

  Widget _contenido(
    BuildContext context,
    AlertaSistema alerta,
    FisicoquimicoProvider fisico,
    MedidoresProvider medidores,
    CaudalProvider caudal,
  ) {
    final parametro = CatalogoParametrosAlerta.buscar(alerta.parametroClave);
    final evaluacion = CatalogoParametrosAlerta.evaluar(alerta);
    final historial = CatalogoParametrosAlerta.historial(
      alerta,
      fisicoquimicos: fisico.registros,
      jornadas: medidores.jornadas,
      aforos: caudal.aforos,
    );
    final registro = _buscarRegistro(alerta, fisico, medidores, caudal);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            alerta.titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
          ),
          const SizedBox(height: 12),
          _SeccionQuePaso(alerta: alerta),
          _SeccionDondeCuando(alerta: alerta, registro: registro),
          if (parametro != null)
            _SeccionHistorial(alerta: alerta, historial: historial, unidad: parametro.unidad),
          _SeccionCausas(alerta: alerta, explicacion: evaluacion?.explicacion, acciones: _acciones(parametro, evaluacion)),
          if (parametro != null) _SeccionNorma(referencia: parametro.referencia),
          _SeccionSeguimiento(alerta: alerta),
          if (!alerta.resuelta) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                key: const Key('marcar_resuelta'),
                onPressed: () => _resolver(context, alerta),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Marcar como resuelta'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _acciones(ParametroAlerta? p, EvaluacionRango? evaluacion) {
    if (p == null || evaluacion == null) return const [];
    return p.acciones(evaluacion);
  }

  /// El registro que originó la alerta, con la ruta de su pantalla de detalle.
  ({String ruta, Object registro, DateTime momento, String? responsable})? _buscarRegistro(
    AlertaSistema alerta,
    FisicoquimicoProvider fisico,
    MedidoresProvider medidores,
    CaudalProvider caudal,
  ) {
    final id = alerta.registroId;
    if (id == null) return null;
    switch (alerta.tipoFormato) {
      case TipoFormatoAlerta.fisicoquimico:
        for (final r in fisico.registros) {
          if (r.id == id) {
            return (
              ruta: AppRoutes.fisicoquimicoDetalle,
              registro: r,
              momento: momentoRegistro(r.fecha, r.hora),
              responsable: r.responsableNombre,
            );
          }
        }
      case TipoFormatoAlerta.medidores:
        for (final j in medidores.jornadas) {
          if (j.id == id) {
            return (
              ruta: AppRoutes.medidoresDetalle,
              registro: j,
              momento: momentoRegistro(j.fecha, j.hora),
              responsable: j.responsableLectura,
            );
          }
        }
      case TipoFormatoAlerta.aforo:
        for (final a in caudal.aforos) {
          if (a.id == id) {
            return (ruta: AppRoutes.caudalDetalle, registro: a, momento: momentoRegistro(a.fecha, a.hora), responsable: null);
          }
        }
      case null:
        break;
    }
    return null;
  }

  Future<void> _resolver(BuildContext context, AlertaSistema alerta) async {
    // Devuelve la nota (puede ser vacía) o null si se cancela.
    final nota = await showDialog<String>(context: context, builder: (_) => const _DialogoResolver());
    if (nota == null || !context.mounted) return;

    context.read<AlertasProvider>().marcarResuelta(
          alerta.id,
          resueltaPor: context.read<SesionUsuarioProvider>().perfil?.nombreCompleto,
          nota: nota,
        );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerta marcada como resuelta')));
  }
}

/// Diálogo para resolver la alerta con una nota opcional. Es dueño de su controlador para
/// liberarlo cuando el diálogo termina de cerrarse.
class _DialogoResolver extends StatefulWidget {
  const _DialogoResolver();

  @override
  State<_DialogoResolver> createState() => _DialogoResolverState();
}

class _DialogoResolverState extends State<_DialogoResolver> {
  final _nota = TextEditingController();

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Marcar como resuelta'),
      content: TextField(
        key: const Key('nota_resolucion'),
        controller: _nota,
        maxLines: 3,
        maxLength: 300,
        decoration: const InputDecoration(
          labelText: 'Nota (opcional)',
          hintText: 'Qué se hizo para resolverla',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(context, _nota.text), child: const Text('Resolver')),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Piezas comunes
// -----------------------------------------------------------------------------
class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;

  const _Seccion({required this.titulo, required this.icono, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Icon(icono, size: 18, color: AppColors.azulPrimario),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? color;

  const _Fila(this.etiqueta, this.valor, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(etiqueta, style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario)),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color ?? AppColors.textoPrincipal),
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorSeveridad(SeveridadAlerta s) => switch (s) {
      SeveridadAlerta.critica => AppColors.critico,
      SeveridadAlerta.advertencia => AppColors.advertencia,
      SeveridadAlerta.informacion => AppColors.informacion,
    };

Color _fondoSeveridad(SeveridadAlerta s) => switch (s) {
      SeveridadAlerta.critica => AppColors.criticoFondo,
      SeveridadAlerta.advertencia => AppColors.advertenciaFondo,
      SeveridadAlerta.informacion => AppColors.informacionFondo,
    };

String _nombreSeveridad(SeveridadAlerta s) => switch (s) {
      SeveridadAlerta.critica => 'Crítica',
      SeveridadAlerta.advertencia => 'Advertencia',
      SeveridadAlerta.informacion => 'Informativa',
    };

String _u(String? unidad) => (unidad == null || unidad.isEmpty || unidad == 'pH') ? '' : ' $unidad';

// -----------------------------------------------------------------------------
// 1. Qué pasó
// -----------------------------------------------------------------------------
class _SeccionQuePaso extends StatelessWidget {
  final AlertaSistema alerta;

  const _SeccionQuePaso({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final v = alerta.valorRegistrado;
    final min = alerta.minimo;
    final max = alerta.maximo;
    final u = _u(alerta.unidad);

    String? diferencia;
    if (v != null) {
      double? dif;
      double? base;
      if (max != null && v > max) {
        dif = v - max;
        base = max;
      } else if (min != null && v < min) {
        dif = min - v;
        base = min;
      }
      if (dif != null) {
        final pct = base == 0 ? null : dif / base!.abs() * 100;
        diferencia = '${_num.format(dif)}$u${pct == null ? '' : ' (${_num.format(pct)} %)'} '
            '${v > (max ?? double.infinity) ? 'por encima del máximo' : 'por debajo del mínimo'}';
      }
    }

    return _Seccion(
      titulo: 'Qué pasó',
      icono: Icons.report_problem_outlined,
      children: [
        Row(
          children: [
            Container(
              key: const Key('chip_severidad'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _fondoSeveridad(alerta.severidad),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _nombreSeveridad(alerta.severidad),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _colorSeveridad(alerta.severidad)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Fila('Parámetro', alerta.parametro ?? 'Sin dato'),
        _Fila('Valor registrado', v == null ? 'Sin dato' : '${_num.format(v)}$u', color: _colorSeveridad(alerta.severidad)),
        _Fila('Rango permitido', alerta.rangoEsperado ?? 'Sin dato'),
        if (diferencia != null) _Fila('Diferencia', diferencia),
        if (v != null && (min != null || max != null)) ...[
          const SizedBox(height: 8),
          _BarraRango(valor: v, minimo: min, maximo: max, color: _colorSeveridad(alerta.severidad)),
        ],
        // La descripción repite valor, rango y causa: solo se muestra si la alerta no los trae por separado.
        if (alerta.descripcion.isNotEmpty && alerta.parametroClave == null) ...[
          const SizedBox(height: 10),
          Text(alerta.descripcion, style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario, height: 1.4)),
        ],
      ],
    );
  }
}

/// Barra horizontal con el rango permitido sombreado y una marca en el valor registrado.
class _BarraRango extends StatelessWidget {
  final double valor;
  final double? minimo;
  final double? maximo;
  final Color color;

  const _BarraRango({required this.valor, required this.minimo, required this.maximo, required this.color});

  @override
  Widget build(BuildContext context) {
    final puntos = [valor, ?minimo, ?maximo];
    var bajo = puntos.reduce(math.min);
    var alto = puntos.reduce(math.max);
    final margen = (alto - bajo) == 0 ? (alto.abs() * 0.2 + 1) : (alto - bajo) * 0.25;
    bajo = (bajo >= 0 && bajo - margen < 0) ? 0 : bajo - margen;
    alto = alto + margen;
    double pos(double x) => ((x - bajo) / (alto - bajo)).clamp(0.0, 1.0);

    final inicioBanda = pos(minimo ?? bajo);
    final finBanda = pos(maximo ?? alto);

    return Column(
      key: const Key('barra_rango'),
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            return SizedBox(
              height: 26,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 9,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(color: AppColors.bordes, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Positioned(
                    left: w * inicioBanda,
                    width: w * (finBanda - inicioBanda),
                    top: 9,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(color: AppColors.exito.withAlpha(110), borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Positioned(
                    left: (w * pos(valor) - 7).clamp(0.0, w - 14),
                    top: 3,
                    child: Container(
                      width: 14,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.blanco, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(minimo == null ? '' : 'mín. ${_num.format(minimo)}', style: const TextStyle(fontSize: 10, color: AppColors.textoSecundario)),
            const Spacer(),
            Text(maximo == null ? '' : 'máx. ${_num.format(maximo)}', style: const TextStyle(fontSize: 10, color: AppColors.textoSecundario)),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 2. Dónde y cuándo
// -----------------------------------------------------------------------------
class _SeccionDondeCuando extends StatelessWidget {
  final AlertaSistema alerta;
  final ({String ruta, Object registro, DateTime momento, String? responsable})? registro;

  const _SeccionDondeCuando({required this.alerta, required this.registro});

  @override
  Widget build(BuildContext context) {
    final r = registro;
    final responsable = alerta.responsable?.isNotEmpty == true ? alerta.responsable! : (r?.responsable ?? 'Sin dato');
    return _Seccion(
      titulo: 'Dónde y cuándo',
      icono: Icons.place_outlined,
      children: [
        _Fila('Formato', alerta.tipoFormato?.nombre ?? 'Sin dato'),
        _Fila('Fecha y hora', _fechaHora.format(r?.momento ?? alerta.fechaHora)),
        _Fila('Responsable', responsable.isEmpty ? 'Sin dato' : responsable),
        if (alerta.puntoControl != null)
          _Fila(alerta.tipoFormato == TipoFormatoAlerta.medidores ? 'Medidor' : 'Punto de control', alerta.puntoControl!),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('ver_registro_completo'),
            onPressed: r == null ? null : () => context.push(r.ruta, extra: r.registro),
            icon: const Icon(Icons.description_outlined, size: 18),
            label: Text(r == null ? 'Registro no disponible' : 'Ver registro completo'),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 3. Historial del parámetro
// -----------------------------------------------------------------------------
class _SeccionHistorial extends StatelessWidget {
  final AlertaSistema alerta;
  final List<ValorHistorico> historial;
  final String unidad;

  const _SeccionHistorial({required this.alerta, required this.historial, required this.unidad});

  @override
  Widget build(BuildContext context) {
    final fuera = historial.where((h) => h.fueraDeRango).length;
    return _Seccion(
      titulo: 'Historial del parámetro',
      icono: Icons.timeline_rounded,
      children: [
        if (historial.isEmpty)
          const Text('Aún no hay registros de este parámetro.', style: TextStyle(fontSize: 12, color: AppColors.textoSecundario))
        else ...[
          Text(
            '$fuera de los últimos ${historial.length} registros ${fuera == 1 ? 'estuvo' : 'estuvieron'} fuera de rango',
            key: const Key('texto_historial'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fuera > 1 ? AppColors.critico : AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            fuera > 1 ? 'Se repite: puede ser una tendencia.' : 'Parece un caso aislado.',
            style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 120, child: _grafica()),
        ],
      ],
    );
  }

  Widget _grafica() {
    final min = alerta.minimo;
    final max = alerta.maximo;
    final valores = historial.map((h) => h.valor).toList();
    final limites = [...valores, ?min, ?max];
    final bajo = limites.reduce(math.min);
    final alto = limites.reduce(math.max);
    final margen = alto == bajo ? (alto.abs() * 0.2 + 1) : (alto - bajo) * 0.15;
    final u = _u(unidad);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, historial.length - 1).toDouble(),
        minY: bajo - margen,
        maxY: alto + margen,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            if (min != null || max != null)
              HorizontalRangeAnnotation(
                y1: min ?? bajo - margen,
                y2: max ?? alto + margen,
                color: AppColors.exito.withAlpha(30),
              ),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
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
                if (v != i.toDouble() || i < 0 || i >= historial.length) return const SizedBox.shrink();
                if (i != historial.length - 1 && i % 3 != 0) return const SizedBox.shrink();
                return Text(
                  DateFormat('dd/MM').format(historial[i].momento),
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
                  '${_fechaHora.format(historial[s.x.toInt()].momento)}\n${_num.format(s.y)}$u',
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < historial.length; i++) FlSpot(i.toDouble(), historial[i].valor)],
            color: AppColors.azulPrimario,
            barWidth: 2,
            dotData: FlDotData(
              getDotPainter: (spot, _, _, index) => FlDotCirclePainter(
                radius: historial[index].fueraDeRango ? 4.5 : 3,
                color: historial[index].fueraDeRango ? AppColors.critico : AppColors.azulPrimario,
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
// 4. Posibles causas y qué revisar
// -----------------------------------------------------------------------------
class _SeccionCausas extends StatelessWidget {
  final AlertaSistema alerta;
  final String? explicacion;
  final List<String> acciones;

  const _SeccionCausas({required this.alerta, required this.explicacion, required this.acciones});

  @override
  Widget build(BuildContext context) {
    final causa = (explicacion != null && explicacion!.isNotEmpty) ? explicacion! : null;
    return _Seccion(
      titulo: 'Posibles causas y qué revisar',
      icono: Icons.fact_check_outlined,
      children: [
        Text(
          causa ?? 'No hay causas registradas para este parámetro.',
          style: const TextStyle(fontSize: 13, color: AppColors.textoPrincipal, height: 1.4),
        ),
        if (acciones.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Acciones sugeridas',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 6),
          for (final a in acciones)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.arrow_right_rounded, size: 16, color: AppColors.azulPrimario),
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: Text(a, style: const TextStyle(fontSize: 12, color: AppColors.textoPrincipal, height: 1.35))),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 5. Norma
// -----------------------------------------------------------------------------
class _SeccionNorma extends StatelessWidget {
  final ReferenciaLimite referencia;

  const _SeccionNorma({required this.referencia});

  @override
  Widget build(BuildContext context) {
    return _Seccion(
      titulo: 'Norma',
      icono: Icons.gavel_outlined,
      children: [
        Text(
          referencia.titulo,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
        ),
        const SizedBox(height: 4),
        Text(referencia.detalle, style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario, height: 1.4)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 6. Seguimiento
// -----------------------------------------------------------------------------
class _SeccionSeguimiento extends StatelessWidget {
  final AlertaSistema alerta;

  const _SeccionSeguimiento({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final (texto, color) = switch (alerta.estado) {
      EstadoAlerta.nueva => ('Nueva', AppColors.informacion),
      EstadoAlerta.leida => ('Leída', AppColors.advertencia),
      EstadoAlerta.resuelta => ('Resuelta', AppColors.exito),
    };
    return _Seccion(
      titulo: 'Seguimiento',
      icono: Icons.assignment_turned_in_outlined,
      children: [
        _Fila('Estado', texto, color: color),
        _Fila('Generada', _fechaHora.format(alerta.fechaHora)),
        if (alerta.resuelta) ...[
          _Fila('Resuelta por', alerta.resueltaPor ?? 'Sin dato'),
          if (alerta.fechaResolucion != null) _Fila('Resuelta el', _fechaHora.format(alerta.fechaResolucion!)),
          _Fila('Nota', alerta.notaResolucion ?? 'Sin nota'),
        ],
      ],
    );
  }
}
