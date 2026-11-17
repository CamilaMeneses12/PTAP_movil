import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/services/excel_export_service.dart';
import '../../../data/services/export_share_service.dart';
import '../../../data/services/pdf_export_service.dart';
import '../../common/widgets/app_drawer.dart';
import '../../flow/providers/caudal_provider.dart';
import '../../history/providers/historial_provider.dart';
import '../../meters/providers/medidores_provider.dart';
import '../../physicochemical/providers/fisicoquimico_provider.dart';

enum TipoFormatoExportar {
  fisicoquimico,
  medidores,
  caudal,
  historial,
}

enum FormatoArchivo {
  pdf,
  excel,
}

/// Pantalla principal para generar y compartir reportes oficiales en PDF y Excel
class ExportarReportesScreen extends StatefulWidget {
  final TipoFormatoExportar? tipoInicial;

  const ExportarReportesScreen({super.key, this.tipoInicial});

  @override
  State<ExportarReportesScreen> createState() => _ExportarReportesScreenState();
}

class _ExportarReportesScreenState extends State<ExportarReportesScreen> {
  late TipoFormatoExportar _tipoSeleccionado;
  FormatoArchivo _formatoArchivo = FormatoArchivo.pdf;
  bool _procesando = false;
  String? _mensajeExito;

  final DateFormat _formatoFecha = DateFormat('yyyyMMdd');

  @override
  void initState() {
    super.initState();
    _tipoSeleccionado = widget.tipoInicial ?? TipoFormatoExportar.fisicoquimico;
  }

  String _obtenerNombreArchivo(String extension) {
    final timestamp = _formatoFecha.format(DateTime.now());
    switch (_tipoSeleccionado) {
      case TipoFormatoExportar.fisicoquimico:
        return 'DO-F-070_Calidad_Agua_$timestamp.$extension';
      case TipoFormatoExportar.medidores:
        return 'Balance_Medidores_PTAP_$timestamp.$extension';
      case TipoFormatoExportar.caudal:
        return 'Aforo_Caudal_La_Seca_$timestamp.$extension';
      case TipoFormatoExportar.historial:
        return 'Historial_PTAP_Consolidado_$timestamp.$extension';
    }
  }

  Future<Uint8List> _generarBytesPdf() async {
    switch (_tipoSeleccionado) {
      case TipoFormatoExportar.fisicoquimico:
        final p = context.read<FisicoquimicoProvider>();
        return await PdfExportService.generarPdfFisicoquimico(p.registros);
      case TipoFormatoExportar.medidores:
        final p = context.read<MedidoresProvider>();
        return await PdfExportService.generarPdfMedidores(p.jornadas);
      case TipoFormatoExportar.caudal:
        final p = context.read<CaudalProvider>();
        return await PdfExportService.generarPdfCaudal(p.aforos);
      case TipoFormatoExportar.historial:
        final p = context.read<HistorialProvider>();
        return await PdfExportService.generarPdfHistorial(p.items);
    }
  }

  Future<Uint8List> _generarBytesExcel() async {
    switch (_tipoSeleccionado) {
      case TipoFormatoExportar.fisicoquimico:
        final p = context.read<FisicoquimicoProvider>();
        return await ExcelExportService.generarExcelFisicoquimico(p.registros);
      case TipoFormatoExportar.medidores:
        final p = context.read<MedidoresProvider>();
        return await ExcelExportService.generarExcelMedidores(p.jornadas);
      case TipoFormatoExportar.caudal:
        final p = context.read<CaudalProvider>();
        return await ExcelExportService.generarExcelCaudal(p.aforos);
      case TipoFormatoExportar.historial:
        final p = context.read<HistorialProvider>();
        return await ExcelExportService.generarExcelHistorial(p.items);
    }
  }

  Future<void> _compartirReporte() async {
    setState(() {
      _procesando = true;
      _mensajeExito = null;
    });

    try {
      if (_formatoArchivo == FormatoArchivo.pdf) {
        final bytes = await _generarBytesPdf();
        final nombre = _obtenerNombreArchivo('pdf');
        await ExportShareService.compartirArchivo(
          bytes: bytes,
          nombreArchivo: nombre,
          mimeType: 'application/pdf',
          texto: 'Reporte oficial PTAP SENA La Salada: $nombre',
        );
      } else {
        final bytes = await _generarBytesExcel();
        final nombre = _obtenerNombreArchivo('xlsx');
        await ExportShareService.compartirArchivo(
          bytes: bytes,
          nombreArchivo: nombre,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          texto: 'Formato Excel PTAP SENA La Salada: $nombre',
        );
      }
      setState(() {
        _mensajeExito = 'Reporte compartido correctamente';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Future<void> _guardarEnDispositivo() async {
    setState(() {
      _procesando = true;
      _mensajeExito = null;
    });

    try {
      final esPdf = _formatoArchivo == FormatoArchivo.pdf;
      final bytes = esPdf ? await _generarBytesPdf() : await _generarBytesExcel();
      final nombre = _obtenerNombreArchivo(esPdf ? 'pdf' : 'xlsx');
      final ruta = await ExportShareService.guardarArchivoLocal(bytes: bytes, nombreArchivo: nombre);

      if (!mounted) return;
      setState(() {
        _mensajeExito = 'Guardado en:\n$ruta';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Archivo guardado exitosamente:\n$nombre'),
          backgroundColor: AppColors.senaVerde,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  void _abrirVistaPreviaPdf() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(_obtenerTituloModulo()),
          ),
          body: PdfPreview(
            build: (format) => _generarBytesPdf(),
            pdfFileName: _obtenerNombreArchivo('pdf'),
            canChangeOrientation: false,
            canChangePageFormat: false,
          ),
        ),
      ),
    );
  }

  String _obtenerTituloModulo() {
    switch (_tipoSeleccionado) {
      case TipoFormatoExportar.fisicoquimico:
        return 'Formato Calidad del Agua (DO-F-070)';
      case TipoFormatoExportar.medidores:
        return 'Balance de Medidores y Pérdidas';
      case TipoFormatoExportar.caudal:
        return 'Aforo Caudal Quebrada La Seca';
      case TipoFormatoExportar.historial:
        return 'Historial Consolidado Filtrado';
    }
  }

  int _obtenerTotalRegistros() {
    switch (_tipoSeleccionado) {
      case TipoFormatoExportar.fisicoquimico:
        return context.watch<FisicoquimicoProvider>().registros.length;
      case TipoFormatoExportar.medidores:
        return context.watch<MedidoresProvider>().jornadas.length;
      case TipoFormatoExportar.caudal:
        return context.watch<CaudalProvider>().aforos.length;
      case TipoFormatoExportar.historial:
        return context.watch<HistorialProvider>().items.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRegistros = _obtenerTotalRegistros();

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      drawer: const AppDrawer(rutaActual: AppRoutes.exportar),
      appBar: AppBar(
        title: const Text('Exportar Reportes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Selector de Formato Oficial
            const Text(
              '1. Selecciona el Formato a Exportar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textoPrincipal,
              ),
            ),
            const SizedBox(height: 10),

            _OpcionFormato(
              titulo: 'DO-F-070: Calidad Fisicoquímica',
              subtitulo: 'pH, Cloro libre, Turbidez, Color y Puntos de Red',
              icono: Icons.science_outlined,
              color: AppColors.turquesa,
              seleccionado: _tipoSeleccionado == TipoFormatoExportar.fisicoquimico,
              onTap: () => setState(() => _tipoSeleccionado = TipoFormatoExportar.fisicoquimico),
            ),
            _OpcionFormato(
              titulo: 'Medidores y Pérdidas de Agua',
              subtitulo: '8 micromedidores, macromedidor y balance hídrico',
              icono: Icons.speed_outlined,
              color: AppColors.azulInstitucional,
              seleccionado: _tipoSeleccionado == TipoFormatoExportar.medidores,
              onTap: () => setState(() => _tipoSeleccionado = TipoFormatoExportar.medidores),
            ),
            _OpcionFormato(
              titulo: 'Aforo Caudal Quebrada La Seca',
              subtitulo: 'Método del flotador, velocidad, área y caudales',
              icono: Icons.water_outlined,
              color: AppColors.azulTecnologico,
              seleccionado: _tipoSeleccionado == TipoFormatoExportar.caudal,
              onTap: () => setState(() => _tipoSeleccionado = TipoFormatoExportar.caudal),
            ),
            _OpcionFormato(
              titulo: 'Historial Consolidado Filtrado',
              subtitulo: 'Registros actuales con los filtros del módulo Historial',
              icono: Icons.history_outlined,
              color: AppColors.azulMarino,
              seleccionado: _tipoSeleccionado == TipoFormatoExportar.historial,
              onTap: () => setState(() => _tipoSeleccionado = TipoFormatoExportar.historial),
            ),
            const SizedBox(height: 20),

            // 2. Tipo de archivo de salida
            const Text(
              '2. Formato del Archivo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textoPrincipal,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _formatoArchivo = FormatoArchivo.pdf),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _formatoArchivo == FormatoArchivo.pdf
                            ? AppColors.error.withAlpha(20)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _formatoArchivo == FormatoArchivo.pdf
                              ? AppColors.error
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 32,
                            color: _formatoArchivo == FormatoArchivo.pdf
                                ? AppColors.error
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Documento PDF',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _formatoArchivo == FormatoArchivo.pdf
                                  ? AppColors.error
                                  : AppColors.textoPrincipal,
                            ),
                          ),
                          const Text(
                            'Listo para imprimir',
                            style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _formatoArchivo = FormatoArchivo.excel),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _formatoArchivo == FormatoArchivo.excel
                            ? AppColors.senaVerde.withAlpha(20)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _formatoArchivo == FormatoArchivo.excel
                              ? AppColors.senaVerde
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.table_chart_outlined,
                            size: 32,
                            color: _formatoArchivo == FormatoArchivo.excel
                                ? AppColors.senaVerde
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hoja Excel (.xlsx)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _formatoArchivo == FormatoArchivo.excel
                                  ? AppColors.senaVerde
                                  : AppColors.textoPrincipal,
                            ),
                          ),
                          const Text(
                            'Formato oficial editable',
                            style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Resumen de lo que se va a exportar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.senaAzul),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Archivo: ${_obtenerNombreArchivo(_formatoArchivo == FormatoArchivo.pdf ? "pdf" : "xlsx")}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Incluye $totalRegistros registros almacenados.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botones de acción principales
            if (_procesando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Generando archivo con formato oficial...'),
                    ],
                  ),
                ),
              )
            else ...[
              // Botón Compartir (WhatsApp / Correo)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.senaVerde,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.share_outlined),
                label: Text(
                  'Compartir por WhatsApp o Correo (${_formatoArchivo == FormatoArchivo.pdf ? "PDF" : "Excel"})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: totalRegistros > 0 ? _compartirReporte : null,
              ),
              const SizedBox(height: 10),

              // Botón Vista previa (solo PDF)
              if (_formatoArchivo == FormatoArchivo.pdf)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Vista Previa e Imprimir PDF'),
                  onPressed: totalRegistros > 0 ? _abrirVistaPreviaPdf : null,
                ),

              // Botón Guardar local
              if (_formatoArchivo == FormatoArchivo.excel)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.save_alt_outlined),
                  label: const Text('Guardar Excel en este Teléfono'),
                  onPressed: totalRegistros > 0 ? _guardarEnDispositivo : null,
                ),
            ],

            if (_mensajeExito != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.senaVerde.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.senaVerde),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.senaVerde),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _mensajeExito!,
                        style: const TextStyle(
                          color: AppColors.senaVerdeOscuro,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpcionFormato extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionFormato({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: seleccionado ? 2 : 0.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: seleccionado ? color : Colors.grey.shade300,
          width: seleccionado ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: color, size: 24),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: seleccionado ? color : AppColors.textoPrincipal,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
        ),
        trailing: Icon(
          seleccionado ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: seleccionado ? color : Colors.grey,
        ),
      ),
    );
  }
}
