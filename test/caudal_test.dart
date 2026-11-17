import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/data/models/aforo_caudal_modelo.dart';
import 'package:planta_agua/data/repositories/caudal_repository.dart';
import 'package:planta_agua/presentation/flow/providers/caudal_provider.dart';

void main() {
  group('Módulo de Caudal Quebrada La Seca (Formato Excel)', () {
    test('AforoCaudal serializa y deserializa fielmente', () {
      final ahora = DateTime(2026, 10, 23);
      final aforo = AforoCaudal(
        id: 'test-aforo-1',
        fecha: ahora,
        hora: '10:00',
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
        profundidadPromedioM: 0.065,
        areaSeccionM2: 0.02665,
        tiempoPromedioS: 7.2075,
        velocidadSuperficialMS: 0.4162,
        velocidadCorregidaMS: 0.3330,
        caudalM3S: 0.00887,
        caudalM3H: 31.94,
        caudalLS: 8.87,
        caudalLH: 31946.7,
        createdBy: 'user-01',
        createdAt: ahora,
      );

      final mapa = aforo.toMap();
      expect(mapa['id'], 'test-aforo-1');
      expect(mapa['caudal_l_s'], 8.87);

      final deserializado = AforoCaudal.fromMap(mapa);
      expect(deserializado.id, aforo.id);
      expect(deserializado.anchoCauceM, 0.41);
      expect(deserializado.caudalLS, 8.87);
    });

    test('CaudalRepository contiene la serie histórica mensual del Excel', () async {
      final repo = CaudalRepository();
      final aforos = await repo.obtenerAforos();

      expect(aforos.length, greaterThanOrEqualTo(25));
      expect(aforos.first.caudalLS, 24.0); // Febrero 2025
    });

    test('CaudalProvider calcula estadísticas y spots para gráfica fl_chart', () async {
      final provider = CaudalProvider();
      await provider.cargarAforos();

      expect(provider.aforos.isNotEmpty, isTrue);
      // El promedio en el Excel es 19.36 L/s
      expect(provider.caudalPromedioLS, closeTo(19.36, 1.0));
      expect(provider.caudalMaximoLS, closeTo(32.0, 0.5));
      expect(provider.caudalMinimoLS, closeTo(8.4, 0.5));

      final spots = provider.spotsGrafica;
      expect(spots.length, provider.aforos.length);
      expect(spots.first.y, 24.0);
    });
  });
}
