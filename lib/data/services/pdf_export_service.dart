import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/aforo_caudal_modelo.dart';
import '../models/item_historial_modelo.dart';
import '../models/medidores_modelos.dart';
import '../models/registro_fisicoquimico.dart';

/// Servicio especializado en la generación de documentos PDF oficiales
/// con la estructura y diseño fiel de los formatos de la PTAP SENA.
class PdfExportService {
  static final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');
  static const PdfColor _azulMarino = PdfColor.fromInt(0xFF0B3B7A);
  static const PdfColor _azulPrimario = PdfColor.fromInt(0xFF1565C0);
  static const PdfColor _grisEncabezado = PdfColor.fromInt(0xFFF3F6FA);
  static const PdfColor _alertaRojo = PdfColor.fromInt(0xFFE53935);
  static const PdfColor _verdeSena = _azulPrimario;
  static const PdfColor _verdeOscuro = _azulMarino;

  // ---------------------------------------------------------------------------
  // 1. FORMATO DO-F-070: CALIDAD FISICOQUÍMICA DEL AGUA
  // ---------------------------------------------------------------------------
  static Future<Uint8List> generarPdfFisicoquimico(
    List<RegistroFisicoquimico> registros, {
    String subtitulo = 'Registros Filtrados',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _construirEncabezadoInstitucional(
          titulo: 'REGISTRO DIARIO DE ANÁLISIS FISICOQUÍMICO DEL AGUA EN PLANTA DE TRATAMIENTO',
          codigoFormato: 'DO-F-070',
          subtitulo: subtitulo,
          context: context,
        ),
        footer: (context) => _construirPieDePagina(context),
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [
              'Fecha',
              'Hora',
              'Agua Cruda\npH',
              'Agua Cruda\nColor',
              'Agua Cruda\nTurb (UNT)',
              'Filtrada\nTurb (UNT)',
              'Clorada\npH (6.5-9)',
              'Clorada\nColor (<15)',
              'Clorada\nTurb (<2)',
              'Clorada\nCloro (0.3-2)',
              'Red\nBiocab.',
              'Red\nAgroind.',
              'Red\nGastro.',
              'Red\nENCC',
              'Red\nBienest.',
              'Observaciones',
              'Operario',
            ],
            data: registros.map((r) {
              String getPunto(String nombre) {
                try {
                  final p = r.puntosControl.firstWhere((e) => e.areaNombre.toLowerCase().contains(nombre.toLowerCase()));
                  return p.cloroResidual?.toStringAsFixed(2) ?? '-';
                } catch (_) {
                  return '-';
                }
              }

              return [
                _formatoFecha.format(r.fecha),
                r.hora,
                r.crudaPh?.toStringAsFixed(2) ?? '-',
                r.crudaColor?.toStringAsFixed(1) ?? '-',
                r.crudaTurbidez?.toStringAsFixed(2) ?? '-',
                r.filtradaTurbidez?.toStringAsFixed(2) ?? '-',
                r.cloradaPh?.toStringAsFixed(2) ?? '-',
                r.cloradaColorAparente?.toStringAsFixed(1) ?? '-',
                r.cloradaTurbidez?.toStringAsFixed(2) ?? '-',
                r.cloradaCloroResidual?.toStringAsFixed(2) ?? '-',
                getPunto('Biocabaña'),
                getPunto('Agroindustria'),
                getPunto('Gastronomía'),
                getPunto('ENCC'),
                getPunto('Dispensador'),
                (r.observaciones != null && r.observaciones!.isNotEmpty) ? r.observaciones! : '-',
                r.responsableNombre.isNotEmpty ? r.responsableNombre : 'Operario',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: _verdeOscuro),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          ),
          pw.SizedBox(height: 10),
          _construirNotaNormativa('Límites normativos según Resolución 2115 de 2007: pH (6.5 - 9.0) | Cloro Residual Libre (0.3 - 2.0 mg/L) | Turbidez (<= 2.0 UNT) | Color Aparente (<= 15 UPC).'),
        ],
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // 2. FORMATO BALANCE DE MEDIDORES Y AGUA NO REGISTRADA
  // ---------------------------------------------------------------------------
  static Future<Uint8List> generarPdfMedidores(
    List<JornadaMedidores> jornadas, {
    String subtitulo = 'Lecturas y Balance de Pérdidas',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _construirEncabezadoInstitucional(
          titulo: 'REGISTRO DE MEDIDORES DE AGUA Y BALANCE HÍDRICO (PÉRDIDAS)',
          codigoFormato: 'PTAP-MED-01',
          subtitulo: subtitulo,
          context: context,
        ),
        footer: (context) => _construirPieDePagina(context),
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [
              'Fecha',
              'Hora',
              'ENCC\n(m³)',
              'SENNOVA\n(m³)',
              'LABS\n(m³)',
              'BIOCABAÑA\n(m³)',
              'CAFETERÍA\n(m³)',
              'PECUARIA\n(m³)',
              'AGROIND.\n(m³)',
              'GASTRO.\n(m³)',
              'Total Micros\n(m³)',
              'Macromedidor\n(m³)',
              'Consumo Macro\n(m³)',
              'Agua No Reg.\n(m³)',
              '% Pérdida',
              'Responsable',
            ],
            data: jornadas.map((j) {
              double getConsumo(String nombre) {
                try {
                  final l = j.lecturas.firstWhere((e) => e.medidorNombre.toLowerCase().contains(nombre.toLowerCase()));
                  return l.consumo;
                } catch (_) {
                  return 0.0;
                }
              }

              final macroLectura = j.lecturas.firstWhere(
                (e) => e.tipoMedidor == 'macromedidor',
                orElse: () => const LecturaMedidor(
                  medidorId: 0,
                  medidorNombre: 'Macro',
                  tipoMedidor: 'macromedidor',
                  lecturaActual: 0.0,
                  lecturaAnterior: 0.0,
                  consumo: 0.0,
                ),
              ).lecturaActual;

              final pctPerdida = j.consumoMacromedidor > 0
                  ? (j.aguaNoRegistrada / j.consumoMacromedidor) * 100
                  : 0.0;

              return [
                _formatoFecha.format(j.fecha),
                j.hora,
                getConsumo('ENCC').toStringAsFixed(2),
                getConsumo('SENNOVA').toStringAsFixed(2),
                getConsumo('LABORATORIOS').toStringAsFixed(2),
                getConsumo('BIOCABAÑA').toStringAsFixed(2),
                getConsumo('CAFETERIA').toStringAsFixed(2),
                getConsumo('PECUARIA').toStringAsFixed(2),
                getConsumo('AGROINDUSTRIA').toStringAsFixed(2),
                getConsumo('GASTRONOMIA').toStringAsFixed(2),
                j.consumoTotalMicros.toStringAsFixed(2),
                macroLectura.toStringAsFixed(2),
                j.consumoMacromedidor.toStringAsFixed(2),
                j.aguaNoRegistrada.toStringAsFixed(2),
                '${pctPerdida.toStringAsFixed(1)}%',
                j.responsableLectura.isNotEmpty ? j.responsableLectura : 'Lector PTAP',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: _verdeOscuro),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          ),
          pw.SizedBox(height: 10),
          _construirNotaNormativa('Fórmula oficial: Agua No Registrada = Consumo Macromedidor - Total Consumo Micromedidores. Porcentaje de Pérdida = (Agua No Registrada / Consumo Macromedidor) * 100.'),
        ],
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // 3. FORMATO AFORO CAUDAL QUEBRADA LA SECA (MÉTODO DEL FLOTADOR)
  // ---------------------------------------------------------------------------
  static Future<Uint8List> generarPdfCaudal(
    List<AforoCaudal> aforos, {
    String subtitulo = 'Aforos Históricos Quebrada La Seca',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _construirEncabezadoInstitucional(
          titulo: 'TABLA PARA CÁLCULO DE CAUDAL - QUEBRADA LA SECA (MÉTODO DEL FLOTADOR)',
          codigoFormato: 'AFORO-CAUDAL-V4',
          subtitulo: subtitulo,
          context: context,
        ),
        footer: (context) => _construirPieDePagina(context),
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [
              'Fecha',
              'Hora',
              'Dist.\n(m)',
              'T. Prom.\n(s)',
              'Vel. Sup.\n(m/s)',
              'Factor\nK',
              'Vel. Med.\n(m/s)',
              'Ancho\n(m)',
              'Prof. Prom.\n(m)',
              'Área Sec.\n(m²)',
              'Q (m³/s)',
              'Q (m³/h)',
              'Q (L/s)',
              'Q (L/h)',
              'Observaciones',
              'Operario',
            ],
            data: aforos.map((a) {
              return [
                _formatoFecha.format(a.fecha),
                a.hora,
                a.distanciaFlotadorM.toStringAsFixed(1),
                a.tiempoPromedioS.toStringAsFixed(2),
                a.velocidadSuperficialMS.toStringAsFixed(3),
                a.factorCorreccion.toStringAsFixed(2),
                a.velocidadCorregidaMS.toStringAsFixed(3),
                a.anchoCauceM.toStringAsFixed(2),
                a.profundidadPromedioM.toStringAsFixed(3),
                a.areaSeccionM2.toStringAsFixed(4),
                a.caudalM3S.toStringAsFixed(5),
                a.caudalM3H.toStringAsFixed(2),
                a.caudalLS.toStringAsFixed(2),
                a.caudalLH.toStringAsFixed(1),
                (a.observaciones != null && a.observaciones!.isNotEmpty) ? a.observaciones! : '-',
                a.createdBy.isNotEmpty ? a.createdBy : 'Operario PTAP',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: _verdeOscuro),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          ),
          pw.SizedBox(height: 10),
          _construirNotaNormativa('Fórmula del flotador: V_media = (Distancia / T_promedio) * K (donde K = 0.80 - 0.85). Área = Ancho * Prof_promedio. Caudal Q = Área * V_media.'),
        ],
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // 4. FORMATO REPORTE UNIFICADO DE HISTORIAL FILTRADO
  // ---------------------------------------------------------------------------
  static Future<Uint8List> generarPdfHistorial(
    List<ItemHistorial> items, {
    String subtitulo = 'Registros Consolidados de la Planta',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _construirEncabezadoInstitucional(
          titulo: 'INFORME CONSOLIDADO DE REGISTROS DE PLANTA',
          codigoFormato: 'INF-HISTORIAL-PTAP',
          subtitulo: subtitulo,
          context: context,
        ),
        footer: (context) => _construirPieDePagina(context),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: [
              'Fecha y Hora',
              'Módulo / Tipo',
              'Resumen de Parámetros',
              'Estado / Alerta',
              'Operario',
            ],
            data: items.map((i) {
              return [
                '${_formatoFecha.format(i.fecha)}\n${i.hora}',
                i.tipoTexto,
                i.subtitulo,
                i.tieneAlerta ? (i.mensajeAlerta ?? 'ALERTA') : 'CONFORME',
                i.responsable,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: _verdeOscuro),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total de registros: ${items.length}',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('Total de alertas: ${items.where((e) => e.tieneAlerta).length}',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _alertaRojo)),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // UTILIDADES DE DISEÑO INSTITUCIONAL
  // ---------------------------------------------------------------------------
  static pw.Widget _construirEncabezadoInstitucional({
    required String titulo,
    required String codigoFormato,
    required String subtitulo,
    required pw.Context context,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _verdeSena, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SERVICIO NACIONAL DE APRENDIZAJE - SENA',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _verdeOscuro,
                  ),
                ),
                pw.Text(
                  'CENTRO DE LOS RECURSOS NATURALES RENOVABLES LA SALADA - REGIONAL ANTIOQUIA',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  titulo,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.Text(
                  subtitulo,
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: _grisEncabezado,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('CÓDIGO SIGA', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
                pw.Text(codigoFormato, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _verdeOscuro)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _construirPieDePagina(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Planta de Tratamiento de Agua Potable - La Salada, Caldas (Ant.) | Exportado el: ${_formatoFecha.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _construirNotaNormativa(String texto) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        color: _grisEncabezado,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'Nota técnica: $texto',
        style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey800),
      ),
    );
  }
}
