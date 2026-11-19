import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/domain/calculations/calculos_caudal.dart';
import 'package:planta_agua/domain/calculations/calculos_medidores.dart';
import 'package:planta_agua/domain/validators/validador_rangos.dart';

void main() {
  group('Cálculos de Caudal (Método del Flotador)', () {
    test('Calcula correctamente con los valores del formato Excel', () {
      // Valores extraídos de "Tabla de Calculo Caudal Quebrada la seca - V4 (1).xlsx"
      // Ancho = 0.41 m
      // Profundidades = 0.09, 0.06, 0.05, 0.06 m -> Promedio = 0.065 m
      // Distancia = 3.0 m
      // Tiempos = 7.55, 5.66, 8.59, 7.03 s -> Promedio = 7.2075 s
      final resultado = CalculosCaudal.calcular(
        anchoCauceM: 0.41,
        profundidad1M: 0.09,
        profundidad2M: 0.06,
        profundidad3M: 0.05,
        profundidad4M: 0.06,
        distanciaFlotadorM: 3.0,
        tiempo1S: 7.55,
        tiempo2S: 5.66,
        tiempo3S: 8.59,
        tiempo4S: 7.03,
      );

      expect(resultado.profundidadPromedioM, closeTo(0.065, 0.0001));
      expect(resultado.areaSeccionM2, closeTo(0.02665, 0.0001));
      expect(resultado.tiempoPromedioS, closeTo(7.2075, 0.0001));
      expect(resultado.velocidadSuperficialMS, closeTo(0.4162, 0.001));
      expect(resultado.velocidadCorregidaMS, closeTo(0.3330, 0.001));
      expect(resultado.caudalM3S, closeTo(0.00887, 0.0001));
      expect(resultado.caudalLS, closeTo(8.874, 0.01));
    });
  });

  group('Cálculos de Medidores y Pérdidas', () {
    test('Calcula consumo individual y balance de pérdidas', () {
      // Diferencia de lectura
      final consumo = CalculosMedidores.calcularConsumo(
        lecturaActual: 2810.29,
        lecturaAnterior: 2807.68,
      );
      expect(consumo, closeTo(2.61, 0.01));

      // Balance macro vs micros
      final balance = CalculosMedidores.calcularBalance(
        consumosMicros: [0.36, 2.61, 0.22, 0.79, 0.0, 3.22, 0.63, 2.71],
        consumoMacro: 16.39,
      );

      expect(balance.consumoTotalMicros, closeTo(10.54, 0.05));
      expect(balance.aguaNoRegistrada, closeTo(5.85, 0.05));
    });
  });

  group('Validador de Rangos Normativos (Res. 2115 / DO-F-070)', () {
    test('Valida límites normales y fuera de rango', () {
      // pH en agua tratada (6.5 a 9.0)
      expect(ValidadorRangos.validarPhTratada(7.5).cumple, isTrue);
      expect(ValidadorRangos.validarPhTratada(6.2).cumple, isFalse);
      expect(ValidadorRangos.validarPhTratada(9.5).cumple, isFalse);

      // Turbidez tratada (máx 2.0 NTU)
      expect(ValidadorRangos.validarTurbidezTratada(0.8).cumple, isTrue);
      expect(ValidadorRangos.validarTurbidezTratada(2.5).cumple, isFalse);

      // Cloro residual libre (0.3 a 2.0 mg/L)
      expect(ValidadorRangos.validarCloroResidual(1.2).cumple, isTrue);
      expect(ValidadorRangos.validarCloroResidual(0.1).cumple, isFalse);
      expect(ValidadorRangos.validarCloroResidual(2.8).cumple, isFalse);
    });

    test('Validador no bloquea: lectura de medidor menor que anterior emite aviso', () {
      final valMedidor = ValidadorRangos.validarLecturaMedidor(
        inicial: 100.0,
        finalLectura: 95.0,
        nombreMedidor: 'ENCC',
      );

      expect(valMedidor.cumple, isFalse);
      expect(valMedidor.severidad, 'advertencia');
      expect(valMedidor.explicacion,
          'La lectura actual es menor que la anterior; verifique el valor o si el medidor fue cambiado o reiniciado.');
    });

    test('Validador de rangos genera formato de aviso con diferencia y porcentaje', () {
      final eval = ValidadorRangos.validarPhTratada(9.6);
      expect(eval.cumple, isFalse);
      expect(eval.mensajeCompleto, startsWith('Aviso: el valor 9,6'));
      expect(eval.mensajeCompleto, contains('está por encima del máximo permitido de 9,0'));
      expect(eval.mensajeCompleto, contains('diferencia: 0,6'));
      expect(eval.mensajeCompleto, contains('6,5–9,0'));
      expect(eval.mensajeCompleto, contains('El agua es alcalina; reduce la eficacia del cloro'));
    });
  });
}
