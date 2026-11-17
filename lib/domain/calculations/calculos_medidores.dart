/// Resultado del balance diario de medidores
class BalanceMedidores {
  final double consumoTotalMicros;
  final double consumoMacromedidor;
  final double aguaNoRegistrada;

  const BalanceMedidores({
    required this.consumoTotalMicros,
    required this.consumoMacromedidor,
    required this.aguaNoRegistrada,
  });
}

/// Fórmulas de cálculo del formato "Registro de medidores de Agua":
/// - Consumo por medidor: diferencia entre lecturas (m³)
/// - Consumo Total Micros: suma de consumos de todos los micromedidores
/// - Agua no registrada o en pérdida: consumo macro - suma de micros
class CalculosMedidores {
  /// Calcula el consumo individual de un medidor dado la lectura actual y la anterior.
  /// Si la lectura actual es menor (por ejemplo por reinicio de dial), maneja el valor.
  static double calcularConsumo({
    required double lecturaActual,
    required double lecturaAnterior,
  }) {
    final diferencia = lecturaActual - lecturaAnterior;
    return diferencia >= 0 ? diferencia : diferencia.abs();
  }

  /// Calcula el balance general entre el macromedidor de la planta y los micromedidores de las áreas.
  static BalanceMedidores calcularBalance({
    required List<double> consumosMicros,
    required double consumoMacro,
  }) {
    final totalMicros = consumosMicros.fold<double>(
      0.0,
      (acumulado, consumo) => acumulado + (consumo > 0 ? consumo : 0.0),
    );

    // Agua no registrada = Consumo Macromedidor - Total de Micromedidores
    final aguaEnPerdida = consumoMacro - totalMicros;

    return BalanceMedidores(
      consumoTotalMicros: totalMicros,
      consumoMacromedidor: consumoMacro,
      aguaNoRegistrada: aguaEnPerdida,
    );
  }
}
