import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/aforo_caudal_modelo.dart';
import '../models/item_historial_modelo.dart';
import '../models/medidores_modelos.dart';
import '../models/registro_fisicoquimico.dart';

/// Servicio especializado en generar libros de cálculo Excel (.xlsx)
/// respetando los encabezados, unidades, orden de columnas y fórmulas de los formatos originales.
class ExcelExportService {
  static final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  // ---------------------------------------------------------------------------
  // 1. FORMATO DO-F-070: CALIDAD FISICOQUÍMICA DEL AGUA
  // ---------------------------------------------------------------------------
  static Future<Uint8List> generarExcelFisicoquimico(
    List<RegistroFisicoquimico> registros,
  ) async {
    final excel = Excel.createExcel();
    const nombreHoja = 'DO-F-070 Calidad';
    final sheet = excel[nombreHoja];
    excel.setDefaultSheet(nombreHoja);

    // Título institucional
    sheet.appendRow([
      TextCellValue('SERVICIO NACIONAL DE APRENDIZAJE SENA - REGIONAL ANTIOQUIA'),
    ]);
    sheet.appendRow([
      TextCellValue('FORMATO DO-F-070: REGISTRO DIARIO DE ANÁLISIS FISICOQUÍMICO DEL AGUA EN PLANTA DE TRATAMIENTO'),
    ]);
    sheet.appendRow([
      TextCellValue('Fecha de exportación: ${_formatoFecha.format(DateTime.now())} | Total registros: ${registros.length}'),
    ]);
    sheet.appendRow([TextCellValue('')]); // Fila en blanco

    // Encabezados de columnas según DO-F-070
    sheet.appendRow([
      TextCellValue('FECHA'),
      TextCellValue('HORA'),
      TextCellValue('AGUA CRUDA pH'),
      TextCellValue('AGUA CRUDA Color (UPC)'),
      TextCellValue('AGUA CRUDA Turbidez (UNT)'),
      TextCellValue('AGUA FILTRADA Turbidez (UNT)'),
      TextCellValue('AGUA CLORADA pH'),
      TextCellValue('AGUA CLORADA Color (UPC)'),
      TextCellValue('AGUA CLORADA Turbidez (UNT)'),
      TextCellValue('AGUA CLORADA Cloro Residual (mg/L)'),
      TextCellValue('RED Biocabaña (mg/L)'),
      TextCellValue('RED Agroindustria (mg/L)'),
      TextCellValue('RED Gastronomía (mg/L)'),
      TextCellValue('RED ENCC (mg/L)'),
      TextCellValue('RED Dispensador (mg/L)'),
      TextCellValue('OBSERVACIONES'),
      TextCellValue('RESPONSABLE'),
    ]);

    // Filas de datos
    for (final r in registros) {
      String getPunto(String nombre) {
        try {
          final p = r.puntosControl.firstWhere((e) => e.areaNombre.toLowerCase().contains(nombre.toLowerCase()));
          return p.cloroResidual?.toStringAsFixed(2) ?? '';
        } catch (_) {
          return '';
        }
      }

      sheet.appendRow([
        TextCellValue(_formatoFecha.format(r.fecha)),
        TextCellValue(r.hora),
        r.crudaPh != null ? DoubleCellValue(r.crudaPh!) : TextCellValue(''),
        r.crudaColor != null ? DoubleCellValue(r.crudaColor!) : TextCellValue(''),
        r.crudaTurbidez != null ? DoubleCellValue(r.crudaTurbidez!) : TextCellValue(''),
        r.filtradaTurbidez != null ? DoubleCellValue(r.filtradaTurbidez!) : TextCellValue(''),
        r.cloradaPh != null ? DoubleCellValue(r.cloradaPh!) : TextCellValue(''),
        r.cloradaColorAparente != null ? DoubleCellValue(r.cloradaColorAparente!) : TextCellValue(''),
        r.cloradaTurbidez != null ? DoubleCellValue(r.cloradaTurbidez!) : TextCellValue(''),
        r.cloradaCloroResidual != null ? DoubleCellValue(r.cloradaCloroResidual!) : TextCellValue(''),
        TextCellValue(getPunto('Biocabaña')),
        TextCellValue(getPunto('Agroindustria')),
        TextCellValue(getPunto('Gastronomía')),
        TextCellValue(getPunto('ENCC')),
        TextCellValue(getPunto('Dispensador')),
        TextCellValue(r.observaciones ?? ''),
        TextCellValue(r.responsableNombre),
      ]);
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? []);
  }

  // ---------------------------------------------------------------------------
  // 2. FORMATO BALANCE DE MEDIDORES Y AGUA NO REGISTRADA
  // ---------------------------------------------------------------------------
  static Future<Uint8List> generarExcelMedidores(
    List<JornadaMedidores> jornadas,
  ) async {
    final excel = Excel.createExcel();
    const nombreHoja = 'Medidores y Pérdidas';
    final sheet = excel[nombreHoja];
    excel.setDefaultSheet(nombreHoja);

    sheet.appendRow([
      TextCellValue('SENA - PLANTA DE TRATAMIENTO DE AGUA POTABLE LA SALADA'),
    ]);
    sheet.appendRow([
      TextCellValue('REGISTRO DE MEDIDORES DE AGUA Y BALANCE HÍDRICO (CONSUMO Y AGUA NO REGISTRADA)'),
    ]);
    sheet.appendRow([TextCellValue('')]);

    sheet.appendRow([
      TextCellValue('FECHA'),
      TextCellValue('HORA'),
      TextCellValue('ENCC (m³)'),
      TextCellValue('SENNOVA (m³)'),
      TextCellValue('LABORATORIOS (m³)'),
      TextCellValue('BIOCABAÑA (m³)'),
      TextCellValue('CAFETERÍA (m³)'),
      TextCellValue('PECUARIA (m³)'),
      TextCellValue('AGROINDUSTRIA (m³)'),
      TextCellValue('GASTRONOMÍA (m³)'),
      TextCellValue('TOTAL MICROMEDIDORES (m³)'),
      TextCellValue('LECTURA MACROMEDIDOR (m³)'),
      TextCellValue('CONSUMO MACROMEDIDOR (m³)'),
      TextCellValue('AGUA NO REGISTRADA (m³)'),
      TextCellValue('% PÉRDIDAS'),
      TextCellValue('OBSERVACIONES'),
      TextCellValue('RESPONSABLE'),
    ]);

    for (final j in jornadas) {
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

      sheet.appendRow([
        TextCellValue(_formatoFecha.format(j.fecha)),
        TextCellValue(j.hora),
        DoubleCellValue(getConsumo('ENCC')),
        DoubleCellValue(getConsumo('SENNOVA')),
        DoubleCellValue(getConsumo('LABORATORIOS')),
        DoubleCellValue(getConsumo('BIOCABAÑA')),
        DoubleCellValue(getConsumo('CAFETERIA')),
        DoubleCellValue(getConsumo('PECUARIA')),
        DoubleCellValue(getConsumo('AGROINDUSTRIA')),
        DoubleCellValue(getConsumo('GASTRONOMIA')),
        DoubleCellValue(j.consumoTotalMicros),
        DoubleCellValue(macroLectura),
        DoubleCellValue(j.consumoMacromedidor),
        DoubleCellValue(j.aguaNoRegistrada),
        DoubleCellValue(pctPerdida),
        TextCellValue(j.observaciones ?? ''),
        TextCellValue(j.responsableLectura),
      ]);
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? []);
  }

  // ---------------------------------------------------------------------------
  // 3. FORMATO AFORO CAUDAL QUEBRADA LA SECA (MÉTODO DEL FLOTADOR)
  // ---------------------------------------------------------------------------
  static Future<Uint8List> generarExcelCaudal(
    List<AforoCaudal> aforos,
  ) async {
    final excel = Excel.createExcel();
    const nombreHoja = 'Caudal La Seca';
    final sheet = excel[nombreHoja];
    excel.setDefaultSheet(nombreHoja);

    sheet.appendRow([
      TextCellValue('CENTRO DE LOS RECURSOS NATURALES RENOVABLES LA SALADA'),
    ]);
    sheet.appendRow([
      TextCellValue('TABLA PARA CÁLCULO DE CAUDAL - QUEBRADA LA SECA (MÉTODO DEL FLOTADOR)'),
    ]);
    sheet.appendRow([TextCellValue('')]);

    sheet.appendRow([
      TextCellValue('FECHA'),
      TextCellValue('HORA'),
      TextCellValue('DISTANCIA L (m)'),
      TextCellValue('TIEMPO 1 (s)'),
      TextCellValue('TIEMPO 2 (s)'),
      TextCellValue('TIEMPO 3 (s)'),
      TextCellValue('TIEMPO PROM. (s)'),
      TextCellValue('VEL. SUPERFICIAL (m/s)'),
      TextCellValue('FACTOR CORRECCIÓN K'),
      TextCellValue('VEL. MEDIA (m/s)'),
      TextCellValue('ANCHO W (m)'),
      TextCellValue('PROFUNDIDAD 1 (m)'),
      TextCellValue('PROFUNDIDAD 2 (m)'),
      TextCellValue('PROFUNDIDAD 3 (m)'),
      TextCellValue('PROF. PROMEDIO (m)'),
      TextCellValue('ÁREA SECCIÓN (m²)'),
      TextCellValue('CAUDAL (m³/s)'),
      TextCellValue('CAUDAL (m³/h)'),
      TextCellValue('CAUDAL (L/s)'),
      TextCellValue('CAUDAL (L/h)'),
      TextCellValue('OBSERVACIONES'),
      TextCellValue('RESPONSABLE'),
    ]);

    for (final a in aforos) {
      sheet.appendRow([
        TextCellValue(_formatoFecha.format(a.fecha)),
        TextCellValue(a.hora),
        DoubleCellValue(a.distanciaFlotadorM),
        DoubleCellValue(a.tiempo1S),
        DoubleCellValue(a.tiempo2S),
        DoubleCellValue(a.tiempo3S),
        DoubleCellValue(a.tiempoPromedioS),
        DoubleCellValue(a.velocidadSuperficialMS),
        DoubleCellValue(a.factorCorreccion),
        DoubleCellValue(a.velocidadCorregidaMS),
        DoubleCellValue(a.anchoCauceM),
        DoubleCellValue(a.profundidad1M),
        DoubleCellValue(a.profundidad2M),
        DoubleCellValue(a.profundidad3M),
        DoubleCellValue(a.profundidadPromedioM),
        DoubleCellValue(a.areaSeccionM2),
        DoubleCellValue(a.caudalM3S),
        DoubleCellValue(a.caudalM3H),
        DoubleCellValue(a.caudalLS),
        DoubleCellValue(a.caudalLH),
        TextCellValue(a.observaciones ?? ''),
        TextCellValue(a.createdBy),
      ]);
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? []);
  }

  // ---------------------------------------------------------------------------
  // 4. FORMATO HISTORIAL UNIFICADO
  // ---------------------------------------------------------------------------
  static Future<Uint8List> generarExcelHistorial(
    List<ItemHistorial> items,
  ) async {
    final excel = Excel.createExcel();
    const nombreHoja = 'Historial Consolidado';
    final sheet = excel[nombreHoja];
    excel.setDefaultSheet(nombreHoja);

    sheet.appendRow([
      TextCellValue('PLANTA DE TRATAMIENTO DE AGUA POTABLE - SENA LA SALADA'),
    ]);
    sheet.appendRow([
      TextCellValue('REPORTE CONSOLIDADO DE REGISTROS DE OPERACIÓN Y CALIDAD'),
    ]);
    sheet.appendRow([TextCellValue('')]);

    sheet.appendRow([
      TextCellValue('FECHA'),
      TextCellValue('HORA'),
      TextCellValue('TIPO DE REGISTRO'),
      TextCellValue('TÍTULO'),
      TextCellValue('DETALLES / PARÁMETROS'),
      TextCellValue('ESTADO'),
      TextCellValue('ALERTA'),
      TextCellValue('OPERARIO / RESPONSABLE'),
    ]);

    for (final i in items) {
      sheet.appendRow([
        TextCellValue(_formatoFecha.format(i.fecha)),
        TextCellValue(i.hora),
        TextCellValue(i.tipoTexto),
        TextCellValue(i.titulo),
        TextCellValue(i.subtitulo),
        TextCellValue(i.tieneAlerta ? 'ALERTA' : 'CONFORME'),
        TextCellValue(i.mensajeAlerta ?? ''),
        TextCellValue(i.responsable),
      ]);
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? []);
  }
}
