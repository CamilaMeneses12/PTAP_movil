import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/core/utils/mapa_supabase.dart';
import 'package:planta_agua/domain/ocr/interprete_lectura_medidor.dart';

void main() {
  group('Intérprete de lectura OCR de micromedidores', () {
    test('Arma 5 enteros + 3 decimales a partir de 8 dígitos', () {
      final r = InterpreteLecturaMedidor.interpretar('00829149')!;
      expect(r.valor, closeTo(829.149, 1e-9));
      expect(r.confianza, ConfianzaOcr.alta);
    });

    test('Corrige letras confundidas y une rodillos separados por espacios', () {
      final r = InterpreteLecturaMedidor.interpretar('0O123 45O')!;
      expect(r.valor, closeTo(123.450, 1e-9));
      expect(r.digitos, '00123450');
    });

    test('Ignora el texto impreso en la carátula del medidor', () {
      const texto = 'LITROS\nm3\n02810 290\nClase B  Qn 1,5';
      final r = InterpreteLecturaMedidor.interpretar(texto)!;
      expect(r.valor, closeTo(2810.290, 1e-9));
    });

    test('Respeta la configuración de dígitos de cada medidor', () {
      final r = InterpreteLecturaMedidor.interpretar('1234567', digitosEnteros: 4, digitosDecimales: 3)!;
      expect(r.valor, closeTo(1234.567, 1e-9));
    });

    test('Con menos dígitos de los esperados baja la confianza', () {
      final r = InterpreteLecturaMedidor.interpretar('00829')!;
      expect(r.valor, 829);
      expect(r.confianza, ConfianzaOcr.media);
      expect(InterpreteLecturaMedidor.interpretar('829')!.confianza, ConfianzaOcr.baja);
      expect(InterpreteLecturaMedidor.interpretar('82'), isNull);
    });

    test('Respeta un separador decimal leído explícitamente', () {
      final r = InterpreteLecturaMedidor.interpretar('829,1496')!;
      expect(r.valor, closeTo(829.1496, 1e-9));
    });

    test('Recorta dígitos sobrantes y devuelve null si no hay números', () {
      expect(InterpreteLecturaMedidor.interpretar('0082914966')!.valor, closeTo(829.149, 1e-9));
      expect(InterpreteLecturaMedidor.interpretar('LITROS m3'), isNull);
      expect(InterpreteLecturaMedidor.interpretar(''), isNull);
    });
  });

  group('Inserción en Supabase', () {
    test('Quita id y created_by locales que no son UUID', () {
      final m = paraInsertarEnSupabase({'id': 'jornada-1700000000', 'created_by': 'operario', 'fecha': '2026-11-19'});
      expect(m.containsKey('id'), isFalse);
      expect(m.containsKey('created_by'), isFalse);
      expect(m['fecha'], '2026-11-19');
    });

    test('Conserva los UUID válidos', () {
      const uuid = '3f2b8c1e-9a4d-4e6f-8b2a-1c3d5e7f9a0b';
      final m = paraInsertarEnSupabase({'id': uuid, 'created_by': uuid});
      expect(m['id'], uuid);
      expect(m['created_by'], uuid);
    });
  });
}
