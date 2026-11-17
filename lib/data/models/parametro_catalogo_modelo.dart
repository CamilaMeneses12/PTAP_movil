/// Modelo que representa un parámetro fisicoquímico normativo y sus rangos configurables
class ParametroCatalogo {
  final String id;
  final String codigo;
  final String nombre;
  final String unidad;
  final double valorMin;
  final double valorMax;
  final String puntoEtapa; // 'agua_cruda', 'agua_filtrada', 'agua_clorada', 'red'
  final String normaReferencia; // 'Resolución 2115 de 2007 / DO-F-070'
  final bool activo;

  const ParametroCatalogo({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.unidad,
    required this.valorMin,
    required this.valorMax,
    required this.puntoEtapa,
    this.normaReferencia = 'Resolución 2115 de 2007 (DO-F-070)',
    this.activo = true,
  });

  ParametroCatalogo copyWith({
    String? id,
    String? codigo,
    String? nombre,
    String? unidad,
    double? valorMin,
    double? valorMax,
    String? puntoEtapa,
    String? normaReferencia,
    bool? activo,
  }) {
    return ParametroCatalogo(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      unidad: unidad ?? this.unidad,
      valorMin: valorMin ?? this.valorMin,
      valorMax: valorMax ?? this.valorMax,
      puntoEtapa: puntoEtapa ?? this.puntoEtapa,
      normaReferencia: normaReferencia ?? this.normaReferencia,
      activo: activo ?? this.activo,
    );
  }

  factory ParametroCatalogo.fromMap(Map<String, dynamic> map) {
    return ParametroCatalogo(
      id: map['id']?.toString() ?? '',
      codigo: map['codigo'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      unidad: map['unidad'] as String? ?? '',
      valorMin: (map['valor_min'] as num?)?.toDouble() ?? 0.0,
      valorMax: (map['valor_max'] as num?)?.toDouble() ?? 0.0,
      puntoEtapa: map['punto_etapa'] as String? ?? 'agua_clorada',
      normaReferencia: map['norma_referencia'] as String? ?? 'Resolución 2115 de 2007 (DO-F-070)',
      activo: map['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'unidad': unidad,
      'valor_min': valorMin,
      'valor_max': valorMax,
      'punto_etapa': puntoEtapa,
      'norma_referencia': normaReferencia,
      'activo': activo,
    };
  }
}
