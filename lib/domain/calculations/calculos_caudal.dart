/// Resultado completo del cálculo de aforo por el método del flotador.
class ResultadoCaudal {
  final double profundidadPromedioM;
  final double areaSeccionM2;
  final double tiempoPromedioS;
  final double velocidadSuperficialMS;
  final double velocidadCorregidaMS;
  final double caudalM3S;
  final double caudalM3H;
  final double caudalLS;
  final double caudalLH;

  const ResultadoCaudal({
    required this.profundidadPromedioM,
    required this.areaSeccionM2,
    required this.tiempoPromedioS,
    required this.velocidadSuperficialMS,
    required this.velocidadCorregidaMS,
    required this.caudalM3S,
    required this.caudalM3H,
    required this.caudalLS,
    required this.caudalLH,
  });
}

/// Lógica de cálculo de caudal según el formato:
/// "Tabla de Calculo Caudal Quebrada la seca - V4 (1).xlsx"
class CalculosCaudal {
  static const double factorCorreccionDefecto = 0.80;

  /// Rango válido del factor de corrección K del flotador. Depende del canal:
  /// más liso → K más alto (≈0,85); arenoso o con piedras → K más bajo (≈0,70–0,80).
  static const double factorCorreccionMin = 0.60;
  static const double factorCorreccionMax = 0.95;

  /// Devuelve el mensaje de error si K no es válido, o null si está dentro del rango.
  static String? validarFactorCorreccion(double? k) {
    if (k == null) return 'Ingrese el factor de corrección K';
    if (k < factorCorreccionMin || k > factorCorreccionMax) {
      return 'K debe estar entre 0,60 y 0,95';
    }
    return null;
  }

  /// Realiza los cálculos automáticos del aforo por método del flotador.
  ///
  /// Fórmulas del Excel:
  /// - Profundidad promedio = AVERAGE(prof1, prof2, prof3, prof4)
  /// - Área sección = ancho * profundidad_promedio
  /// - Tiempo promedio = AVERAGE(t1, t2, t3, t4)
  /// - Velocidad superficial = distancia / tiempo_promedio
  /// - Velocidad corregida = velocidad_superficial * factor_correccion K (0,80 por defecto)
  /// - Caudal (m³/s) = área * velocidad_corregida
  /// - Caudal (m³/h) = caudal_m3_s * 3600
  /// - Caudal (L/s) = caudal_m3_s * 1000
  /// - Caudal (L/h) = caudal_l_s * 3600
  static ResultadoCaudal calcular({
    required double anchoCauceM,
    required double profundidad1M,
    required double profundidad2M,
    required double profundidad3M,
    required double profundidad4M,
    required double distanciaFlotadorM,
    required double tiempo1S,
    required double tiempo2S,
    required double tiempo3S,
    required double tiempo4S,
    double factorCorreccion = factorCorreccionDefecto,
  }) {
    if (anchoCauceM <= 0 || distanciaFlotadorM <= 0) {
      throw ArgumentError('El ancho del cauce y la distancia deben ser mayores a cero.');
    }

    final profPromedio = (profundidad1M + profundidad2M + profundidad3M + profundidad4M) / 4.0;
    final areaSeccion = anchoCauceM * profPromedio;

    final tiempoPromedio = (tiempo1S + tiempo2S + tiempo3S + tiempo4S) / 4.0;
    if (tiempoPromedio <= 0) {
      throw ArgumentError('El tiempo promedio debe ser mayor a cero.');
    }

    final velSuperficial = distanciaFlotadorM / tiempoPromedio;
    final velCorregida = velSuperficial * factorCorreccion;

    final caudalM3S = areaSeccion * velCorregida;
    final caudalM3H = caudalM3S * 3600.0;
    final caudalLS = caudalM3S * 1000.0;
    final caudalLH = caudalLS * 3600.0;

    return ResultadoCaudal(
      profundidadPromedioM: profPromedio,
      areaSeccionM2: areaSeccion,
      tiempoPromedioS: tiempoPromedio,
      velocidadSuperficialMS: velSuperficial,
      velocidadCorregidaMS: velCorregida,
      caudalM3S: caudalM3S,
      caudalM3H: caudalM3H,
      caudalLS: caudalLS,
      caudalLH: caudalLH,
    );
  }
}
