import 'package:intl/intl.dart';

/// Resultado detallado de validación de un parámetro técnico o normativo
class EvaluacionRango {
  final bool cumple;
  final String? mensajeAlerta;
  final double? minimo;
  final double? maximo;
  final String unidad;
  final double? valor;
  final String tipo; // 'correcto' | 'por_debajo' | 'por_encima' | 'invalido'
  final double? diferencia;
  final double? porcentajeDiferencia;
  final String severidad; // 'ninguna' | 'advertencia' | 'critica'
  final String explicacion;
  final String mensajeCompleto;

  const EvaluacionRango({
    required this.cumple,
    this.mensajeAlerta,
    this.minimo,
    this.maximo,
    required this.unidad,
    this.valor,
    this.tipo = 'correcto',
    this.diferencia,
    this.porcentajeDiferencia,
    this.severidad = 'ninguna',
    this.explicacion = '',
    this.mensajeCompleto = '',
  });

  bool get esValido => cumple;
  bool get esCritico => severidad == 'critica';
  bool get esAdvertencia => severidad == 'advertencia';

  factory EvaluacionRango.correcto(String unidad, {double? valor, double? min, double? max}) {
    return EvaluacionRango(
      cumple: true,
      unidad: unidad,
      valor: valor,
      minimo: min,
      maximo: max,
      tipo: 'correcto',
      severidad: 'ninguna',
      explicacion: 'Valor conforme dentro del rango normativo u operativo.',
      mensajeCompleto: 'Valor conforme ($valor $unidad).',
    );
  }

  factory EvaluacionRango.invalido({
    required String parametro,
    required String motivo,
    String unidad = '',
    double? valor,
  }) {
    return EvaluacionRango(
      cumple: false,
      unidad: unidad,
      valor: valor,
      tipo: 'invalido',
      severidad: 'critica',
      explicacion: motivo,
      mensajeAlerta: 'Valor inválido en $parametro: $motivo',
      mensajeCompleto: 'Valor inválido en $parametro: $motivo',
    );
  }

  factory EvaluacionRango.fueraDeRango({
    required String parametro,
    required double valor,
    required double? minimo,
    required double? maximo,
    required String unidad,
    required String explicacion,
    String severidad = 'advertencia',
  }) {
    final format = NumberFormat('#,##0.0#', 'es_CO');
    final valorTxt = format.format(valor);
    final minTxt = minimo != null ? format.format(minimo) : null;
    final maxTxt = maximo != null ? format.format(maximo) : null;

    String tipo = 'por_encima';
    double dif = 0.0;
    double pct = 0.0;

    if (maximo != null && valor > maximo) {
      tipo = 'por_encima';
      dif = (valor - maximo).abs();
      pct = maximo != 0 ? (dif / maximo) * 100 : 0.0;
    } else if (minimo != null && valor < minimo) {
      tipo = 'por_debajo';
      dif = (minimo - valor).abs();
      pct = minimo != 0 ? (dif / minimo) * 100 : 0.0;
    }

    final difTxt = format.format(dif);
    final pctTxt = format.format(pct);
    final uEspacio = (unidad.trim().isEmpty || unidad == 'pH') ? '' : ' $unidad';

    final limiteTxt = tipo == 'por_encima' ? maxTxt : minTxt;
    final direccionTexto = tipo == 'por_encima'
        ? 'está por encima del máximo permitido de $limiteTxt$uEspacio'
        : 'está por debajo del mínimo permitido de $limiteTxt$uEspacio';

    final rangoTexto = (minimo != null && maximo != null)
        ? '$minTxt–$maxTxt$uEspacio'
        : (maximo != null ? 'máx. $maxTxt$uEspacio' : 'mín. $minTxt$uEspacio');

    final msgCompleto =
        'Aviso: el valor $valorTxt$uEspacio $direccionTexto (diferencia: $difTxt$uEspacio, $pctTxt %; fuera del rango). Rango correcto: $rangoTexto. $explicacion';

    return EvaluacionRango(
      cumple: false,
      minimo: minimo,
      maximo: maximo,
      unidad: unidad,
      valor: valor,
      tipo: tipo,
      diferencia: dif,
      porcentajeDiferencia: pct,
      severidad: severidad,
      explicacion: explicacion,
      mensajeAlerta: msgCompleto,
      mensajeCompleto: msgCompleto,
    );
  }
}

/// Validador central de límites normativos y técnicos (Res. 2115 de 2007, DO-F-070 y operación PTAP)
class ValidadorRangos {
  // 1. Agua Cruda (Valores dinámicos configurables por Administrador)
  static double phCrudaMin = 5.0;
  static double phCrudaMax = 9.0;
  static double turbidezCrudaMax = 10.0; // UJT
  static double colorCrudaMax = 20.0;     // UPC

  // 2. Agua Tratada (Res. 2115 de 2007)
  static double phTratadaMin = 6.5;
  static double phTratadaMax = 9.0;
  static double turbidezTratadaMax = 2.0; // UNT / NTU
  static double colorTratadaMax = 15.0;   // UPC
  static double cloroMin = 0.3;           // mg/L
  static double cloroMax = 2.0;           // mg/L

  // 3. Hidráulica y Red (Operación de Planta PTAP SENA)
  static double caudalEntradaMin = 110.0; // L/s
  static double caudalEntradaMax = 140.0; // L/s
  static double nivelTanqueMin = 40.0;    // %
  static const double nivelTanqueCritico = 20.0;// %

  /// Valida pH en agua cruda (5.0 a 9.0)
  static EvaluacionRango validarPhCruda(double? valor) {
    if (valor == null) return EvaluacionRango.correcto('pH');
    if (valor < 0 || valor > 14) {
      return EvaluacionRango.invalido(
        parametro: 'pH Agua Cruda',
        motivo: 'La escala de pH comprende valores físicos entre 0 y 14.',
        unidad: 'pH',
        valor: valor,
      );
    }
    if (valor < phCrudaMin || valor > phCrudaMax) {
      return EvaluacionRango.fueraDeRango(
        parametro: 'pH Agua Cruda',
        valor: valor,
        minimo: phCrudaMin,
        maximo: phCrudaMax,
        unidad: 'pH',
        severidad: 'advertencia',
        explicacion: valor < phCrudaMin
            ? 'pH excesivamente ácido en la fuente; revisar neutralización previa.'
            : 'pH alcalino en captación; puede requerir ajuste de coagulante.',
      );
    }
    return EvaluacionRango.correcto('pH', valor: valor, min: phCrudaMin, max: phCrudaMax);
  }

  /// Valida Turbidez en agua cruda (máximo 10 UJT)
  static EvaluacionRango validarTurbidezCruda(double? valor) {
    if (valor == null) return EvaluacionRango.correcto('UJT');
    if (valor < 0) {
      return EvaluacionRango.invalido(
        parametro: 'Turbidez Entrada',
        motivo: 'La turbidez no puede ser negativa.',
        unidad: 'UJT',
        valor: valor,
      );
    }
    if (valor > turbidezCrudaMax) {
      return EvaluacionRango.fueraDeRango(
        parametro: 'Turbidez Entrada',
        valor: valor,
        minimo: 0.0,
        maximo: turbidezCrudaMax,
        unidad: 'UJT',
        severidad: 'advertencia',
        explicacion: 'Turbidez alta en captación por lluvias o crecientes en la fuente.',
      );
    }
    return EvaluacionRango.correcto('UJT', valor: valor, min: 0.0, max: turbidezCrudaMax);
  }

  /// Valida Color en agua cruda (máximo 20 UPC)
  static EvaluacionRango validarColorCruda(double? valor) {
    if (valor == null) return EvaluacionRango.correcto('UPC');
    if (valor < 0) {
      return EvaluacionRango.invalido(
        parametro: 'Color Agua Cruda',
        motivo: 'El color aparente no puede ser negativo.',
        unidad: 'UPC',
        valor: valor,
      );
    }
    if (valor > colorCrudaMax) {
      return EvaluacionRango.fueraDeRango(
        parametro: 'Color Agua Cruda',
        valor: valor,
        minimo: 0.0,
        maximo: colorCrudaMax,
        unidad: 'UPC',
        severidad: 'advertencia',
        explicacion: 'Color elevado en la fuente por alta carga vegetal u orgánica.',
      );
    }
    return EvaluacionRango.correcto('UPC', valor: valor, min: 0.0, max: colorCrudaMax);
  }

  /// Valida pH en agua filtrada, clorada o puntos de control (6.5 a 9.0)
  static EvaluacionRango validarPhTratada(double? valor, {String nombre = 'pH'}) {
    if (valor == null) return EvaluacionRango.correcto('pH');
    if (valor < 0 || valor > 14) {
      return EvaluacionRango.invalido(
        parametro: nombre,
        motivo: 'La escala de pH comprende valores físicos entre 0 y 14.',
        unidad: 'pH',
        valor: valor,
      );
    }
    if (valor < phTratadaMin || valor > phTratadaMax) {
      final esBajo = valor < phTratadaMin;
      return EvaluacionRango.fueraDeRango(
        parametro: nombre,
        valor: valor,
        minimo: phTratadaMin,
        maximo: phTratadaMax,
        unidad: 'pH',
        severidad: 'critica',
        explicacion: esBajo
            ? 'El agua es ácida; puede corroer tuberías y afectar la desinfección.'
            : 'El agua es alcalina; reduce la eficacia del cloro y puede generar incrustaciones.',
      );
    }
    return EvaluacionRango.correcto('pH', valor: valor, min: phTratadaMin, max: phTratadaMax);
  }

  /// Valida Turbidez en agua tratada (0.0 a 2.0 UNT/NTU)
  static EvaluacionRango validarTurbidezTratada(double? valor, {String nombre = 'Turbidez'}) {
    if (valor == null) return EvaluacionRango.correcto('UNT');
    if (valor < 0) {
      return EvaluacionRango.invalido(
        parametro: nombre,
        motivo: 'La turbidez no puede ser un valor negativo.',
        unidad: 'UNT',
        valor: valor,
      );
    }
    if (valor > turbidezTratadaMax) {
      return EvaluacionRango.fueraDeRango(
        parametro: nombre,
        valor: valor,
        minimo: 0.0,
        maximo: turbidezTratadaMax,
        unidad: 'UNT',
        severidad: 'critica',
        explicacion: 'Indica partículas en suspensión; revisar coagulación, sedimentación o filtros.',
      );
    }
    return EvaluacionRango.correcto('UNT', valor: valor, min: 0.0, max: turbidezTratadaMax);
  }

  /// Valida Color Aparente en agua clorada o puntos de control (máximo 15 UPC)
  static EvaluacionRango validarColorAparente(double? valor, {String nombre = 'Color Aparente'}) {
    if (valor == null) return EvaluacionRango.correcto('UPC');
    if (valor < 0) {
      return EvaluacionRango.invalido(
        parametro: nombre,
        motivo: 'El color aparente no puede ser negativo.',
        unidad: 'UPC',
        valor: valor,
      );
    }
    if (valor > colorTratadaMax) {
      return EvaluacionRango.fueraDeRango(
        parametro: nombre,
        valor: valor,
        minimo: 0.0,
        maximo: colorTratadaMax,
        unidad: 'UPC',
        severidad: 'advertencia',
        explicacion: 'Indica materia orgánica o metales disueltos; revisar dosis de coagulante.',
      );
    }
    return EvaluacionRango.correcto('UPC', valor: valor, min: 0.0, max: colorTratadaMax);
  }

  /// Valida Cloro Residual Libre (0.3 a 2.0 mg/L)
  static EvaluacionRango validarCloroResidual(double? valor, {String nombre = 'Cloro Residual'}) {
    if (valor == null) return EvaluacionRango.correcto('mg/L');
    if (valor < 0) {
      return EvaluacionRango.invalido(
        parametro: nombre,
        motivo: 'La concentración de cloro no puede ser negativa.',
        unidad: 'mg/L',
        valor: valor,
      );
    }
    if (valor < cloroMin || valor > cloroMax) {
      final esBajo = valor < cloroMin;
      return EvaluacionRango.fueraDeRango(
        parametro: nombre,
        valor: valor,
        minimo: cloroMin,
        maximo: cloroMax,
        unidad: 'mg/L',
        severidad: 'critica',
        explicacion: esBajo
            ? 'Desinfección insuficiente; riesgo microbiológico para el consumo.'
            : 'Exceso de cloro; puede generar olor/sabor y subproductos de desinfección.',
      );
    }
    return EvaluacionRango.correcto('mg/L', valor: valor, min: cloroMin, max: cloroMax);
  }

  /// Valida Caudal de Entrada a Planta (110 - 140 L/s)
  static EvaluacionRango validarCaudalEntrada(double? valor) {
    if (valor == null) return EvaluacionRango.correcto('L/s');
    if (valor <= 0) {
      return EvaluacionRango.invalido(
        parametro: 'Caudal de Entrada',
        motivo: 'El caudal debe ser estrictamente mayor a 0 L/s.',
        unidad: 'L/s',
        valor: valor,
      );
    }
    if (valor < caudalEntradaMin || valor > caudalEntradaMax) {
      final esMayor = valor > caudalEntradaMax;
      return EvaluacionRango.fueraDeRango(
        parametro: 'Caudal de entrada',
        valor: valor,
        minimo: caudalEntradaMin,
        maximo: caudalEntradaMax,
        unidad: 'L/s',
        severidad: esMayor ? 'critica' : 'advertencia',
        explicacion:
            'Puede superar la capacidad de tratamiento / indicar falla en la captación.',
      );
    }
    return EvaluacionRango.correcto('L/s', valor: valor, min: caudalEntradaMin, max: caudalEntradaMax);
  }

  /// Valida Nivel de Almacenamiento en Tanque (Mínimo 40%)
  static EvaluacionRango validarNivelTanque(double? valor) {
    if (valor == null) return EvaluacionRango.correcto('%');
    if (valor < 0 || valor > 100) {
      return EvaluacionRango.invalido(
        parametro: 'Nivel de tanque',
        motivo: 'El nivel de llenado debe estar entre 0% y 100%.',
        unidad: '%',
        valor: valor,
      );
    }
    if (valor < nivelTanqueMin) {
      final esCritico = valor < nivelTanqueCritico;
      return EvaluacionRango.fueraDeRango(
        parametro: 'Nivel de tanque',
        valor: valor,
        minimo: nivelTanqueMin,
        maximo: 100.0,
        unidad: '%',
        severidad: esCritico ? 'critica' : 'advertencia',
        explicacion: 'Reserva por debajo del mínimo operativo; riesgo de desabastecimiento.',
      );
    }
    return EvaluacionRango.correcto('%', valor: valor, min: nivelTanqueMin, max: 100.0);
  }

  /// Valida coherencia de lecturas de medidor (Final >= Inicial)
  static EvaluacionRango validarLecturaMedidor({
    required double? inicial,
    required double? finalLectura,
    String nombreMedidor = 'Medidor',
  }) {
    if (inicial == null || finalLectura == null) {
      return EvaluacionRango.correcto('m³');
    }
    if (inicial < 0 || finalLectura < 0) {
      return EvaluacionRango.invalido(
        parametro: nombreMedidor,
        motivo: 'Las lecturas acumuladas no pueden ser números negativos.',
        unidad: 'm³',
      );
    }
    if (finalLectura < inicial) {
      return EvaluacionRango(
        cumple: false,
        unidad: 'm³',
        valor: finalLectura,
        tipo: 'por_debajo',
        severidad: 'advertencia',
        explicacion:
            'La lectura actual es menor que la anterior; verifique el valor o si el medidor fue cambiado o reiniciado.',
        mensajeAlerta:
            'Aviso en $nombreMedidor: La lectura actual es menor que la anterior; verifique el valor o si el medidor fue cambiado o reiniciado.',
        mensajeCompleto:
            'Aviso: en $nombreMedidor la lectura actual ($finalLectura m³) es menor que la anterior ($inicial m³); verifique el valor o si el medidor fue cambiado o reiniciado.',
      );
    }
    return EvaluacionRango.correcto('m³', valor: finalLectura - inicial);
  }
}
