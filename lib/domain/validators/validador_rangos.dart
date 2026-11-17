/// Estado de validación de un parámetro fisicoquímico
class EvaluacionRango {
  final bool cumple;
  final String? mensajeAlerta;
  final double? minimo;
  final double? maximo;
  final String unidad;

  const EvaluacionRango({
    required this.cumple,
    this.mensajeAlerta,
    this.minimo,
    this.maximo,
    required this.unidad,
  });

  factory EvaluacionRango.correcto(String unidad) {
    return EvaluacionRango(cumple: true, unidad: unidad);
  }

  factory EvaluacionRango.fueraDeRango({
    required String parametro,
    required double valor,
    required double? minimo,
    required double? maximo,
    required String unidad,
  }) {
    String rangoTexto = '';
    if (minimo != null && maximo != null) {
      rangoTexto = '$minimo a $maximo $unidad';
    } else if (maximo != null) {
      rangoTexto = 'máximo $maximo $unidad';
    } else if (minimo != null) {
      rangoTexto = 'mínimo $minimo $unidad';
    }

    return EvaluacionRango(
      cumple: false,
      minimo: minimo,
      maximo: maximo,
      unidad: unidad,
      mensajeAlerta:
          '¡Alerta! $parametro ($valor $unidad) está fuera del rango permitido ($rangoTexto). Requiere observación.',
    );
  }
}

/// Validador de límites normativos según el formato DO-F-070 y la Resolución 2115 de 2007.
class ValidadorRangos {
  // Agua Cruda
  static const double phCrudaMin = 5.0;
  static const double phCrudaMax = 9.0;
  static const double turbidezCrudaMax = 10.0; // UJT
  static const double colorCrudaMax = 20.0;     // UPC

  // Agua Tratada (Filtrada, Clorada y Puntos de Red)
  static const double phTratadaMin = 6.5;
  static const double phTratadaMax = 9.0;
  static const double turbidezTratadaMax = 2.0; // NTU
  static const double colorTratadaMax = 15.0;   // UPC
  static const double cloroMin = 0.3;           // mg/L
  static const double cloroMax = 2.0;           // mg/L

  /// Valida pH en agua cruda (5.0 a 9.0)
  static EvaluacionRango validarPhCruda(double? valor) {
    if (valor == null) return EvaluacionRango.correcto('pH');
    if (valor < phCrudaMin || valor > phCrudaMax) {
      return EvaluacionRango.fueraDeRango(
        parametro: 'pH Agua Cruda',
        valor: valor,
        minimo: phCrudaMin,
        maximo: phCrudaMax,
        unidad: 'pH',
      );
    }
    return EvaluacionRango.correcto('pH');
  }

  /// Valida Turbidez en agua cruda (máximo 10 UJT)
  static EvaluacionRango validarTurbidezCruda(double? valor) {
    if (valor == null) return EvaluacionRango.correcto('UJT');
    if (valor < 0 || valor > turbidezCrudaMax) {
      return EvaluacionRango.fueraDeRango(
        parametro: 'Turbidez Entrada',
        valor: valor,
        minimo: 0.0,
        maximo: turbidezCrudaMax,
        unidad: 'UJT',
      );
    }
    return EvaluacionRango.correcto('UJT');
  }

  /// Valida Color en agua cruda (máximo 20 UPC)
  static EvaluacionRango validarColorCruda(double? valor) {
    if (valor == null) return EvaluacionRango.correcto('UPC');
    if (valor < 0 || valor > colorCrudaMax) {
      return EvaluacionRango.fueraDeRango(
        parametro: 'Color Agua Cruda',
        valor: valor,
        minimo: 0.0,
        maximo: colorCrudaMax,
        unidad: 'UPC',
      );
    }
    return EvaluacionRango.correcto('UPC');
  }

  /// Valida pH en agua filtrada, clorada o puntos de control (6.5 a 9.0)
  static EvaluacionRango validarPhTratada(double? valor, {String nombre = 'pH'}) {
    if (valor == null) return EvaluacionRango.correcto('pH');
    if (valor < phTratadaMin || valor > phTratadaMax) {
      return EvaluacionRango.fueraDeRango(
        parametro: nombre,
        valor: valor,
        minimo: phTratadaMin,
        maximo: phTratadaMax,
        unidad: 'pH',
      );
    }
    return EvaluacionRango.correcto('pH');
  }

  /// Valida Turbidez en agua tratada (0.0 a 2.0 NTU)
  static EvaluacionRango validarTurbidezTratada(double? valor, {String nombre = 'Turbidez'}) {
    if (valor == null) return EvaluacionRango.correcto('NTU');
    if (valor < 0 || valor > turbidezTratadaMax) {
      return EvaluacionRango.fueraDeRango(
        parametro: nombre,
        valor: valor,
        minimo: 0.0,
        maximo: turbidezTratadaMax,
        unidad: 'NTU',
      );
    }
    return EvaluacionRango.correcto('NTU');
  }

  /// Valida Color Aparente en agua clorada o puntos de control (máximo 15 UPC)
  static EvaluacionRango validarColorAparente(double? valor, {String nombre = 'Color Aparente'}) {
    if (valor == null) return EvaluacionRango.correcto('UPC');
    if (valor < 0 || valor > colorTratadaMax) {
      return EvaluacionRango.fueraDeRango(
        parametro: nombre,
        valor: valor,
        minimo: 0.0,
        maximo: colorTratadaMax,
        unidad: 'UPC',
      );
    }
    return EvaluacionRango.correcto('UPC');
  }

  /// Valida Cloro Residual Libre (0.3 a 2.0 mg/L)
  static EvaluacionRango validarCloroResidual(double? valor, {String nombre = 'Cloro Residual'}) {
    if (valor == null) return EvaluacionRango.correcto('mg/L');
    if (valor < cloroMin || valor > cloroMax) {
      return EvaluacionRango.fueraDeRango(
        parametro: nombre,
        valor: valor,
        minimo: cloroMin,
        maximo: cloroMax,
        unidad: 'mg/L',
      );
    }
    return EvaluacionRango.correcto('mg/L');
  }
}
