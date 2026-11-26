import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/normatividad/normas_agua.dart';
import '../../../domain/validators/validador_rangos.dart';

/// Normativa colombiana de agua para consumo humano, con lo que aplica en la PTAP.
/// Si llega [normaId] (desde un "Ver norma"), esa tarjeta se resalta y se muestra primero en pantalla.
class NormatividadScreen extends StatefulWidget {
  final String? normaId;

  const NormatividadScreen({super.key, this.normaId});

  @override
  State<NormatividadScreen> createState() => _NormatividadScreenState();
}

class _NormatividadScreenState extends State<NormatividadScreen> {
  final _claves = {for (final n in NormasAgua.todas) n.id: GlobalKey()};

  @override
  void initState() {
    super.initState();
    final destino = _claves[widget.normaId];
    if (destino != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = destino.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(title: const Text('Normatividad')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Normas colombianas sobre la calidad del agua para consumo humano que aplican en la planta.',
              style: TextStyle(fontSize: 13, color: AppColors.textoSecundario, height: 1.4),
            ),
            const SizedBox(height: 14),
            for (final n in NormasAgua.todas)
              _TarjetaNorma(
                key: _claves[n.id],
                norma: n,
                resaltada: n.id == widget.normaId,
                extra: n.id == NormasAgua.res2115 ? const _RangosDeLaApp() : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaNorma extends StatelessWidget {
  final NormaAgua norma;
  final bool resaltada;
  final Widget? extra;

  const _TarjetaNorma({super.key, required this.norma, required this.resaltada, this.extra});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: resaltada ? AppColors.azulPrimario : AppColors.bordes, width: resaltada ? 2 : 1),
        boxShadow: AppColors.sombraSuave,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.azulClaro, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${norma.anio}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.azulMarino),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  norma.nombreCorto,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            norma.titulo,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.azulMarino),
          ),
          const SizedBox(height: 4),
          Text(norma.entidad, style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
          const SizedBox(height: 10),
          const _Subtitulo('De qué trata'),
          Text(norma.deQueTrata, style: const TextStyle(fontSize: 12, color: AppColors.textoPrincipal, height: 1.4)),
          const SizedBox(height: 10),
          const _Subtitulo('Qué aplica en la PTAP'),
          for (final a in norma.aplicaEnPtap)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(fontSize: 12, color: AppColors.azulPrimario)),
                  Expanded(child: Text(a, style: const TextStyle(fontSize: 12, color: AppColors.textoPrincipal, height: 1.35))),
                ],
              ),
            ),
          ?extra,
          if (norma.nota != null) ...[
            const SizedBox(height: 8),
            Text(
              norma.nota!,
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textoSecundario),
            ),
          ],
        ],
      ),
    );
  }
}

class _Subtitulo extends StatelessWidget {
  final String texto;
  const _Subtitulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textoSecundario),
      ),
    );
  }
}

/// Rangos del agua tratada que la app usa hoy (ValidadorRangos; el administrador puede ajustarlos).
class _RangosDeLaApp extends StatelessWidget {
  const _RangosDeLaApp();

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,##0.0#', 'es_CO');
    final filas = [
      ('pH agua tratada', '${f.format(ValidadorRangos.phTratadaMin)}–${f.format(ValidadorRangos.phTratadaMax)}'),
      ('Turbidez agua tratada', 'máx. ${f.format(ValidadorRangos.turbidezTratadaMax)} NTU'),
      ('Color aparente', 'máx. ${f.format(ValidadorRangos.colorTratadaMax)} UPC'),
      ('Cloro residual libre', '${f.format(ValidadorRangos.cloroMin)}–${f.format(ValidadorRangos.cloroMax)} mg/L'),
    ];
    return Container(
      key: const Key('rangos_de_la_app'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.fondoGeneral, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rangos que valida la app',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
          ),
          const SizedBox(height: 6),
          for (final (nombre, rango) in filas)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Expanded(child: Text(nombre, style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario))),
                  Text(rango, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal)),
                ],
              ),
            ),
          const SizedBox(height: 4),
          const Text(
            'Son los mismos valores con los que se validan los registros y se generan las alertas.',
            style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }
}
