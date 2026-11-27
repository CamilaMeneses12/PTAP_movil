import '../../data/models/registro_fisicoquimico.dart';

/// Punto de control de la red de distribución (sección "Red" del DO-F-070).
class PuntoControlRed {
  /// Nombre tal como se guarda en el registro y en `puntos_muestreo`.
  final String nombre;

  /// Encabezado corto para las columnas del PDF.
  final String corto;

  const PuntoControlRed(this.nombre, this.corto);
}

/// Lista única de puntos de control en red: la usan el formulario, el Excel y el PDF.
/// Son las mismas 8 áreas de los micromedidores más el dispensador de Bienestar.
class PuntosControlRed {
  static const List<PuntoControlRed> todos = [
    PuntoControlRed('ENCC', 'ENCC'),
    PuntoControlRed('SENNOVA', 'SENNOVA'),
    PuntoControlRed('Laboratorios', 'Labs.'),
    PuntoControlRed('Biocabaña', 'Biocab.'),
    PuntoControlRed('Cafetería', 'Cafet.'),
    PuntoControlRed('Pecuaria', 'Pecuar.'),
    PuntoControlRed('Agroindustria', 'Agroind.'),
    // Sin tilde: así quedó en los registros y en la tabla puntos_muestreo.
    PuntoControlRed('Gastronomia', 'Gastro.'),
    PuntoControlRed('Dispensador Bienestar', 'Bienest.'),
  ];

  static List<String> get nombres => [for (final p in todos) p.nombre];

  /// Minúsculas y sin tildes, para que "Gastronomía" y "Gastronomia" sean el mismo punto.
  static String normalizar(String texto) {
    const conTilde = 'áéíóúüñ';
    const sinTilde = 'aeiouun';
    final buffer = StringBuffer();
    for (final c in texto.trim().toLowerCase().split('')) {
      final i = conTilde.indexOf(c);
      buffer.write(i == -1 ? c : sinTilde[i]);
    }
    return buffer.toString();
  }

  /// Medición del punto [nombre] dentro de un registro; null si no se tomó.
  static MedicionPuntoControl? buscar(List<MedicionPuntoControl> puntos, String nombre) {
    final clave = normalizar(nombre);
    for (final p in puntos) {
      if (normalizar(p.areaNombre) == clave) return p;
    }
    return null;
  }
}
