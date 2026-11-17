import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/data/models/medidores_modelos.dart';
import 'package:planta_agua/data/repositories/medidores_repository.dart';
import 'package:planta_agua/domain/calculations/calculos_medidores.dart';

void main() {
  group('Módulo de Medidores y Balance Hídrico (Formato Excel)', () {
    test('Catálogo oficial contiene exactamente los 9 medidores en orden', () {
      final repo = MedidoresRepository();
      final medidores = repo.obtenerMedidores();

      expect(medidores.length, 9);
      expect(medidores[0].nombre, 'ENCC');
      expect(medidores[1].nombre, 'SENNOVA');
      expect(medidores[2].nombre, 'LABORATORIOS');
      expect(medidores[3].nombre, 'BIOCABAÑA');
      expect(medidores[4].nombre, 'CAFETERIA');
      expect(medidores[5].nombre, 'PECUARIA');
      expect(medidores[6].nombre, 'AGROINDUSTRIA');
      expect(medidores[7].nombre, 'GASTRONOMIA');
      expect(medidores[8].nombre, 'MACRO MEDIDOR');
      expect(medidores[8].esMacro, isTrue);
    });

    test('Cálculo de balance hídrico con valores exactos del Excel (17-feb-2025)', () {
      // Valores de consumos calculados del Excel:
      // ENCC: 0.3605, SENNOVA: 2.6096, LAB: 0.2183, BIOCABAÑA: 0.7880,
      // CAFETERIA: 0.0000, PECUARIA: 3.2240, AGRO: 0.6308, GASTRO: 2.7057
      // MACRO: 16.3900
      final consumosMicros = [
        0.3605,
        2.6096,
        0.2183,
        0.7880,
        0.0000,
        3.2240,
        0.6308,
        2.7057,
      ];
      const consumoMacro = 16.3900;

      final balance = CalculosMedidores.calcularBalance(
        consumosMicros: consumosMicros,
        consumoMacro: consumoMacro,
      );

      expect(balance.consumoTotalMicros, closeTo(10.5369, 0.0001));
      expect(balance.consumoMacromedidor, closeTo(16.3900, 0.0001));
      expect(balance.aguaNoRegistrada, closeTo(5.8531, 0.0001));
    });

    test('Modelo JornadaMedidores serializa y deserializa correctamente', () {
      final ahora = DateTime(2025, 2, 17);
      final jornada = JornadaMedidores(
        id: 'test-jornada-01',
        fecha: ahora,
        hora: '09:40',
        responsableLectura: 'Operario PTAP',
        consumoTotalMicros: 10.5369,
        consumoMacromedidor: 16.3900,
        aguaNoRegistrada: 5.8531,
        createdBy: 'user-op',
        createdAt: ahora,
        lecturas: const [
          LecturaMedidor(
            medidorId: 1,
            medidorNombre: 'ENCC',
            tipoMedidor: 'micromedidor',
            lecturaActual: 829.1496,
            lecturaAnterior: 828.7891,
            consumo: 0.3605,
          ),
        ],
      );

      final mapa = jornada.toMap();
      expect(mapa['id'], 'test-jornada-01');
      expect(mapa['consumo_total_micros'], 10.5369);
      expect(mapa['agua_no_registrada'], 5.8531);

      final deserializada = JornadaMedidores.fromMap(
        mapa,
        lecturas: jornada.lecturas,
      );
      expect(deserializada.id, jornada.id);
      expect(deserializada.consumoTotalMicros, 10.5369);
      expect(deserializada.lecturas.first.medidorNombre, 'ENCC');
    });

    test('Repositorio MedidoresRepository guarda jornada y actualiza últimas lecturas', () async {
      final repo = MedidoresRepository();
      final jornadasIniciales = await repo.obtenerJornadas();

      expect(jornadasIniciales.isNotEmpty, isTrue);

      final nuevaJornada = JornadaMedidores(
        id: 'jornada-nueva-test',
        fecha: DateTime.now(),
        hora: '10:00',
        responsableLectura: 'Lector Turno',
        consumoTotalMicros: 8.5,
        consumoMacromedidor: 12.0,
        aguaNoRegistrada: 3.5,
        createdBy: 'op-01',
        createdAt: DateTime.now(),
        lecturas: const [
          LecturaMedidor(
            medidorId: 1,
            medidorNombre: 'ENCC',
            tipoMedidor: 'micromedidor',
            lecturaActual: 850.0,
            lecturaAnterior: 829.1496,
            consumo: 20.8504,
          ),
        ],
      );

      final exito = await repo.guardarJornada(nuevaJornada);
      expect(exito, isTrue);

      final ultimas = repo.obtenerUltimasLecturas();
      expect(ultimas[1], 850.0);
    });
  });
}
