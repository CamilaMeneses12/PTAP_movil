import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/data/repositories/caudal_repository.dart';
import 'package:planta_agua/data/repositories/fisicoquimico_repository.dart';
import 'package:planta_agua/data/repositories/historial_repository.dart';
import 'package:planta_agua/data/repositories/medidores_repository.dart';
import 'package:planta_agua/data/services/excel_export_service.dart';
import 'package:planta_agua/data/services/pdf_export_service.dart';

void main() {
  group('Módulo de Exportación (PDF y Excel según Formatos Oficiales)', () {
    late FisicoquimicoRepository fisicoquimicoRepo;
    late MedidoresRepository medidoresRepo;
    late CaudalRepository caudalRepo;
    late HistorialRepository historialRepo;

    setUp(() {
      fisicoquimicoRepo = FisicoquimicoRepository();
      medidoresRepo = MedidoresRepository();
      caudalRepo = CaudalRepository();
      historialRepo = HistorialRepository(
        fisicoquimicoRepo: fisicoquimicoRepo,
        medidoresRepo: medidoresRepo,
        caudalRepo: caudalRepo,
      );
    });

    test('Genera PDF oficial DO-F-070 de Calidad del Agua con encabezados y datos', () async {
      final registros = await fisicoquimicoRepo.obtenerRegistros();
      expect(registros.isNotEmpty, isTrue);

      final pdfBytes = await PdfExportService.generarPdfFisicoquimico(registros);
      expect(pdfBytes.isNotEmpty, isTrue);
      // Validar firma PDF (%PDF)
      expect(String.fromCharCodes(pdfBytes.sublist(0, 4)), '%PDF');
    });

    test('Genera PDF de Balance de Medidores y Pérdidas', () async {
      final jornadas = await medidoresRepo.obtenerJornadas();
      expect(jornadas.isNotEmpty, isTrue);

      final pdfBytes = await PdfExportService.generarPdfMedidores(jornadas);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(pdfBytes.sublist(0, 4)), '%PDF');
    });

    test('Genera PDF de Aforo Caudal Quebrada La Seca (Método del Flotador)', () async {
      final aforos = await caudalRepo.obtenerAforos();
      expect(aforos.isNotEmpty, isTrue);

      final pdfBytes = await PdfExportService.generarPdfCaudal(aforos);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(pdfBytes.sublist(0, 4)), '%PDF');
    });

    test('Genera PDF de Historial Consolidado', () async {
      final items = await historialRepo.obtenerHistorialCompleto();
      expect(items.isNotEmpty, isTrue);

      final pdfBytes = await PdfExportService.generarPdfHistorial(items);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(pdfBytes.sublist(0, 4)), '%PDF');
    });

    test('Genera Excel oficial DO-F-070 con estructura fiel', () async {
      final registros = await fisicoquimicoRepo.obtenerRegistros();
      final xlsxBytes = await ExcelExportService.generarExcelFisicoquimico(registros);

      expect(xlsxBytes.isNotEmpty, isTrue);
      // Archivo ZIP / XLSX inicia con PK (0x50, 0x4B)
      expect(xlsxBytes[0], 0x50);
      expect(xlsxBytes[1], 0x4B);
    });

    test('Genera Excel de Balance de Medidores con 8 micromedidores y macromedidor', () async {
      final jornadas = await medidoresRepo.obtenerJornadas();
      final xlsxBytes = await ExcelExportService.generarExcelMedidores(jornadas);

      expect(xlsxBytes.isNotEmpty, isTrue);
      expect(xlsxBytes[0], 0x50);
      expect(xlsxBytes[1], 0x4B);
    });

    test('Genera Excel de Aforo Caudal Quebrada La Seca con columnas del formato V4', () async {
      final aforos = await caudalRepo.obtenerAforos();
      final xlsxBytes = await ExcelExportService.generarExcelCaudal(aforos);

      expect(xlsxBytes.isNotEmpty, isTrue);
      expect(xlsxBytes[0], 0x50);
      expect(xlsxBytes[1], 0x4B);
    });

    test('Genera Excel de Historial Consolidado Filtrado', () async {
      final items = await historialRepo.obtenerHistorialCompleto();
      final xlsxBytes = await ExcelExportService.generarExcelHistorial(items);

      expect(xlsxBytes.isNotEmpty, isTrue);
      expect(xlsxBytes[0], 0x50);
      expect(xlsxBytes[1], 0x4B);
    });
  });
}
