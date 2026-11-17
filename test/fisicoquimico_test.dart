import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/data/models/registro_fisicoquimico.dart';
import 'package:planta_agua/data/repositories/fisicoquimico_repository.dart';
import 'package:planta_agua/domain/validators/validador_rangos.dart';

void main() {
  group('Modelo RegistroFisicoquimico y Puntos de Control (DO-F-070)', () {
    test('Crea y serializa correctamente un registro con puntos de red', () {
      final ahora = DateTime(2026, 11, 12);
      final punto = MedicionPuntoControl(
        areaNombre: 'Biocabaña',
        turbidez: 1.5,
        ph: 7.2,
        colorAparente: 10.0,
        cloroResidual: 1.2,
      );

      final registro = RegistroFisicoquimico(
        id: 'test-fis-01',
        fecha: ahora,
        hora: '08:30',
        crudaPh: 7.8,
        filtradaPh: 7.4,
        cloradaPh: 7.3,
        cloradaCloroResidual: 1.5,
        puntosControl: [punto],
        responsableNombre: 'Diego Calderón',
        createdBy: 'user-01',
        createdAt: ahora,
      );

      expect(registro.id, 'test-fis-01');
      expect(registro.crudaPh, 7.8);
      expect(registro.puntosControl.length, 1);
      expect(registro.puntosControl.first.areaNombre, 'Biocabaña');

      final mapa = registro.toMap();
      expect(mapa['cruda_ph'], 7.8);
      expect(mapa['responsable_nombre'], 'Diego Calderón');

      final deserializado = RegistroFisicoquimico.fromMap(
        mapa,
        puntos: [punto],
      );
      expect(deserializado.id, registro.id);
      expect(deserializado.cloradaCloroResidual, 1.5);
      expect(deserializado.puntosControl.length, 1);
    });

    test('Validación de rangos alerta si el cloro residual supera 2.0 mg/L', () {
      final valCloroAlto = ValidadorRangos.validarCloroResidual(2.8);
      expect(valCloroAlto.cumple, isFalse);
      expect(valCloroAlto.mensajeAlerta, contains('fuera del rango'));

      final valCloroNormal = ValidadorRangos.validarCloroResidual(1.2);
      expect(valCloroNormal.cumple, isTrue);
    });

    test('Validación de turbidez en agua filtrada (0.0 a 2.0 NTU)', () {
      final valTurbNormal = ValidadorRangos.validarTurbidezTratada(1.1);
      expect(valTurbNormal.cumple, isTrue);

      final valTurbAlta = ValidadorRangos.validarTurbidezTratada(3.5);
      expect(valTurbAlta.cumple, isFalse);
    });
  });

  group('FisicoquimicoRepository (Persistencia y Semilla)', () {
    test('Obtiene registros iniciales y permite guardar un nuevo registro', () async {
      final repo = FisicoquimicoRepository();
      final iniciales = await repo.obtenerRegistros();

      expect(iniciales.isNotEmpty, isTrue);

      final nuevo = RegistroFisicoquimico(
        id: 'nuevo-01',
        fecha: DateTime.now(),
        hora: '10:00',
        crudaPh: 7.5,
        cloradaCloroResidual: 1.1,
        responsableNombre: 'Operario Turno',
        createdBy: 'op-01',
        createdAt: DateTime.now(),
      );

      final exito = await repo.guardarRegistro(nuevo);
      expect(exito, isTrue);

      final actualizados = await repo.obtenerRegistros();
      expect(actualizados.any((r) => r.id == 'nuevo-01'), isTrue);
    });
  });
}
