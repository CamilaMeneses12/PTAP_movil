import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/data/services/dataset_medidores_service.dart';
import 'package:planta_agua/data/services/lector_medidor_ia_service.dart';
import 'package:planta_agua/domain/ocr/interprete_lectura_medidor.dart';

ResultadoLecturaOcr _l(double v, ConfianzaOcr c) => ResultadoLecturaOcr(valor: v, digitos: '', confianza: c);

List<List<double>> _salida(String digitos, {double prob = 0.97}) => [
      for (final c in digitos.split(''))
        [for (var d = 0; d < 10; d++) d == int.parse(c) ? prob : (1 - prob) / 9],
    ];

void main() {
  group('Salida del modelo propio', () {
    test('Convierte [8][10] probabilidades en la lectura 0813,6267', () {
      final r = LectorMedidorIaService.interpretarSalida(_salida('08136267'), digitosEnteros: 4);
      expect(r.valor, closeTo(813.6267, 1e-9));
      expect(r.digitos, '08136267');
      expect(r.confianza, ConfianzaOcr.alta);
    });

    test('La confianza es la del rodillo más dudoso', () {
      final salida = _salida('08136267');
      salida[7] = [0, 0, 0, 0, 0, 0, 0, 0.55, 0.45, 0];
      expect(LectorMedidorIaService.interpretarSalida(salida, digitosEnteros: 4).confianza, ConfianzaOcr.baja);
    });
  });

  group('Elegir entre modelo propio y ML Kit', () {
    test('Gana la lectura creíble frente a la anterior aunque tenga menos confianza', () {
      final opciones = [_l(2309.3377, ConfianzaOcr.alta), _l(813.6267, ConfianzaOcr.media)];
      expect(InterpreteLecturaMedidor.elegirMejor(opciones, lecturaAnterior: 813.6), 1);
    });

    test('En empate gana la primera (modelo propio)', () {
      final opciones = [_l(813.6267, ConfianzaOcr.media), _l(813.6268, ConfianzaOcr.media)];
      expect(InterpreteLecturaMedidor.elegirMejor(opciones, lecturaAnterior: 813.6), 0);
    });

    test('Si el modelo y ML Kit leen lo mismo, la confianza sube a alta', () {
      final r = InterpreteLecturaMedidor.mejorLectura(
        [_l(813.6267, ConfianzaOcr.media), null, _l(813.6267, ConfianzaOcr.baja)],
        lecturaAnterior: 813.6,
      )!;
      expect(r.confianza, ConfianzaOcr.alta);
    });

    test('Sin opciones devuelve null', () {
      expect(InterpreteLecturaMedidor.mejorLectura([null, null]), isNull);
    });
  });

  test('Nombre del ejemplo para el dataset: 813,6267 → 08136267', () {
    expect(DatasetMedidoresService.digitosDeLectura(813.6267, digitosEnteros: 4, digitosDecimales: 4), '08136267');
    expect(DatasetMedidoresService.digitosDeLectura(5.1, digitosEnteros: 4, digitosDecimales: 4), '00051000');
  });
}
