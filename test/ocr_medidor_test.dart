import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/core/utils/mapa_supabase.dart';
import 'package:planta_agua/domain/ocr/interprete_lectura_medidor.dart';

void main() {
  group('Intérprete de lectura OCR de micromedidores', () {
    test('Arma 5 enteros + 3 decimales a partir de 8 dígitos', () {
      final r = InterpreteLecturaMedidor.interpretar('00829149', digitosEnteros: 5, digitosDecimales: 3)!;
      expect(r.valor, closeTo(829.149, 1e-9));
      expect(r.confianza, ConfianzaOcr.alta);
    });

    test('Corrige letras confundidas y une rodillos separados por espacios', () {
      final r = InterpreteLecturaMedidor.interpretar('0O123 45O', digitosEnteros: 5, digitosDecimales: 3)!;
      expect(r.valor, closeTo(123.450, 1e-9));
      expect(r.digitos, '00123450');
    });

    test('Ignora el texto impreso en la carátula del medidor', () {
      const texto = 'LITROS\nm3\n02810 290\nClase B  Qn 1,5';
      final r = InterpreteLecturaMedidor.interpretar(texto, digitosEnteros: 5, digitosDecimales: 3)!;
      expect(r.valor, closeTo(2810.290, 1e-9));
    });

    test('Respeta la configuración de dígitos de cada medidor', () {
      final r = InterpreteLecturaMedidor.interpretar('1234567', digitosEnteros: 4, digitosDecimales: 3)!;
      expect(r.valor, closeTo(1234.567, 1e-9));
    });

    test('Con menos dígitos de los esperados baja la confianza', () {
      final r = InterpreteLecturaMedidor.interpretar('00829', digitosEnteros: 5, digitosDecimales: 3)!;
      expect(r.valor, 829);
      expect(r.confianza, ConfianzaOcr.media);
      expect(InterpreteLecturaMedidor.interpretar('829', digitosEnteros: 5, digitosDecimales: 3)!.confianza, ConfianzaOcr.baja);
      expect(InterpreteLecturaMedidor.interpretar('82', digitosEnteros: 5, digitosDecimales: 3), isNull);
    });

    test('Respeta un separador decimal leído explícitamente', () {
      final r = InterpreteLecturaMedidor.interpretar('829,1496', digitosEnteros: 5, digitosDecimales: 3)!;
      expect(r.valor, closeTo(829.1496, 1e-9));
    });

    test('Recorta dígitos sobrantes y devuelve null si no hay números', () {
      expect(InterpreteLecturaMedidor.interpretar('0082914966', digitosEnteros: 5, digitosDecimales: 3)!.valor, closeTo(829.149, 1e-9));
      expect(InterpreteLecturaMedidor.interpretar('LITROS m3', digitosEnteros: 5, digitosDecimales: 3), isNull);
      expect(InterpreteLecturaMedidor.interpretar('', digitosEnteros: 5, digitosDecimales: 3), isNull);
    });
  });

  group('Micromedidor real (4 rodillos blancos + 4 rojos)', () {
    test('Por defecto arma 4 enteros + 4 decimales: 0813 6267 → 813,6267', () {
      final r = InterpreteLecturaMedidor.interpretar('0813 6267')!;
      expect(r.valor, closeTo(813.6267, 1e-9));
      expect(r.confianza, ConfianzaOcr.alta);
    });

    test('Con la lectura anterior descarta el número de serie grabado en la carcasa', () {
      const texto = '23 093377m3\n0813 6267';
      // Sin pista, el número de serie también tiene 8 dígitos y podría confundirse
      final conPista = InterpreteLecturaMedidor.interpretar(texto, lecturaAnterior: 813.60)!;
      expect(conPista.valor, closeTo(813.6267, 1e-9));
    });

    test('Si ningún número es creíble frente a la lectura anterior, la confianza es baja', () {
      final r = InterpreteLecturaMedidor.interpretar('23 093377', lecturaAnterior: 813.60)!;
      expect(r.confianza, ConfianzaOcr.baja);
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
