import 'package:flutter_test/flutter_test.dart';
import 'package:planta_agua/data/models/registro_fisicoquimico.dart';
import 'package:planta_agua/domain/catalogos/puntos_control_red.dart';

void main() {
  test('El DO-F-070 trae las 8 áreas de los micromedidores más el dispensador', () {
    expect(PuntosControlRed.nombres, [
      'ENCC',
      'SENNOVA',
      'Laboratorios',
      'Biocabaña',
      'Cafetería',
      'Pecuaria',
      'Agroindustria',
      'Gastronomia',
      'Dispensador Bienestar',
    ]);
  });

  test('Busca el punto sin importar tildes ni mayúsculas', () {
    const puntos = [
      MedicionPuntoControl(areaNombre: 'Gastronomia', cloroResidual: 1.5),
      MedicionPuntoControl(areaNombre: 'cafeteria', cloroResidual: 0.8),
    ];
    expect(PuntosControlRed.buscar(puntos, 'Gastronomía')?.cloroResidual, 1.5);
    expect(PuntosControlRed.buscar(puntos, 'Cafetería')?.cloroResidual, 0.8);
    expect(PuntosControlRed.buscar(puntos, 'Pecuaria'), isNull);
  });
}
