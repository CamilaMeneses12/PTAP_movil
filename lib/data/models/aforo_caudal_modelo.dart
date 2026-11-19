/// Modelo de datos para un aforo de caudal en la quebrada La Seca
/// según el formato: "Tabla de Calculo Caudal Quebrada la seca - V4 (1).xlsx"
class AforoCaudal {
  final String id;
  final DateTime fecha;
  final String hora;

  // Parámetros medidos en campo
  final double anchoCauceM;
  final double profundidad1M;
  final double profundidad2M;
  final double profundidad3M;
  final double profundidad4M;
  final double distanciaFlotadorM;
  final double tiempo1S;
  final double tiempo2S;
  final double tiempo3S;
  final double tiempo4S;
  final double factorCorreccion; // 0.80 por defecto

  // Resultados calculados automáticamente
  final double profundidadPromedioM;
  final double areaSeccionM2;
  final double tiempoPromedioS;
  final double velocidadSuperficialMS;
  final double velocidadCorregidaMS;
  final double caudalM3S;
  final double caudalM3H;
  final double caudalLS;
  final double caudalLH;
  final bool fueraDeRango;

  final String? observaciones;
  final String createdBy;
  final DateTime createdAt;

  const AforoCaudal({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.anchoCauceM,
    required this.profundidad1M,
    required this.profundidad2M,
    required this.profundidad3M,
    required this.profundidad4M,
    required this.distanciaFlotadorM,
    required this.tiempo1S,
    required this.tiempo2S,
    required this.tiempo3S,
    required this.tiempo4S,
    this.factorCorreccion = 0.80,
    required this.profundidadPromedioM,
    required this.areaSeccionM2,
    required this.tiempoPromedioS,
    required this.velocidadSuperficialMS,
    required this.velocidadCorregidaMS,
    required this.caudalM3S,
    required this.caudalM3H,
    required this.caudalLS,
    required this.caudalLH,
    this.fueraDeRango = false,
    this.observaciones,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String().split('T').first,
      'hora': hora,
      'ancho_cauce_m': anchoCauceM,
      'profundidad_1_m': profundidad1M,
      'profundidad_2_m': profundidad2M,
      'profundidad_3_m': profundidad3M,
      'profundidad_4_m': profundidad4M,
      'distancia_flotador_m': distanciaFlotadorM,
      'tiempo_1_s': tiempo1S,
      'tiempo_2_s': tiempo2S,
      'tiempo_3_s': tiempo3S,
      'tiempo_4_s': tiempo4S,
      'factor_correccion': factorCorreccion,
      'profundidad_promedio_m': profundidadPromedioM,
      'area_seccion_m2': areaSeccionM2,
      'tiempo_promedio_s': tiempoPromedioS,
      'velocidad_superficial_m_s': velocidadSuperficialMS,
      'velocidad_corregida_m_s': velocidadCorregidaMS,
      'caudal_m3_s': caudalM3S,
      'caudal_m3_h': caudalM3H,
      'caudal_l_s': caudalLS,
      'caudal_l_h': caudalLH,
      'fuera_de_rango': fueraDeRango,
      'observaciones': observaciones,
      'created_by': createdBy,
    };
  }

  factory AforoCaudal.fromMap(Map<String, dynamic> map) {
    DateTime parseFecha(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return AforoCaudal(
      id: map['id']?.toString() ?? '',
      fecha: parseFecha(map['fecha']),
      hora: map['hora']?.toString() ?? '09:00',
      anchoCauceM: (map['ancho_cauce_m'] as num?)?.toDouble() ?? 0.0,
      profundidad1M: (map['profundidad_1_m'] as num?)?.toDouble() ?? 0.0,
      profundidad2M: (map['profundidad_2_m'] as num?)?.toDouble() ?? 0.0,
      profundidad3M: (map['profundidad_3_m'] as num?)?.toDouble() ?? 0.0,
      profundidad4M: (map['profundidad_4_m'] as num?)?.toDouble() ?? 0.0,
      distanciaFlotadorM: (map['distancia_flotador_m'] as num?)?.toDouble() ?? 3.0,
      tiempo1S: (map['tiempo_1_s'] as num?)?.toDouble() ?? 0.0,
      tiempo2S: (map['tiempo_2_s'] as num?)?.toDouble() ?? 0.0,
      tiempo3S: (map['tiempo_3_s'] as num?)?.toDouble() ?? 0.0,
      tiempo4S: (map['tiempo_4_s'] as num?)?.toDouble() ?? 0.0,
      factorCorreccion: (map['factor_correccion'] as num?)?.toDouble() ?? 0.80,
      profundidadPromedioM: (map['profundidad_promedio_m'] as num?)?.toDouble() ?? 0.0,
      areaSeccionM2: (map['area_seccion_m2'] as num?)?.toDouble() ?? 0.0,
      tiempoPromedioS: (map['tiempo_promedio_s'] as num?)?.toDouble() ?? 0.0,
      velocidadSuperficialMS: (map['velocidad_superficial_m_s'] as num?)?.toDouble() ?? 0.0,
      velocidadCorregidaMS: (map['velocidad_corregida_m_s'] as num?)?.toDouble() ?? 0.0,
      caudalM3S: (map['caudal_m3_s'] as num?)?.toDouble() ?? 0.0,
      caudalM3H: (map['caudal_m3_h'] as num?)?.toDouble() ?? 0.0,
      caudalLS: (map['caudal_l_s'] as num?)?.toDouble() ?? 0.0,
      caudalLH: (map['caudal_l_h'] as num?)?.toDouble() ?? 0.0,
      fueraDeRango: map['fuera_de_rango'] as bool? ?? false,
      observaciones: map['observaciones'] as String?,
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: map['created_at'] != null ? parseFecha(map['created_at']) : DateTime.now(),
    );
  }
}
