/// Modelo que representa un medidor físico del catálogo oficial
class Medidor {
  final int id;
  final String codigo;
  final String nombre;
  final String tipo; // 'micromedidor' o 'macromedidor'
  final int orden;
  final bool activo;
  final int digitosEnteros; // rodillos negros (m³ enteros), defecto 5
  final int digitosDecimales; // rodillos o agujas rojas (decimales), defecto 3

  const Medidor({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    required this.orden,
    this.activo = true,
    this.digitosEnteros = 5,
    this.digitosDecimales = 3,
  });

  bool get esMacro => tipo == 'macromedidor';
  bool get esMicro => tipo == 'micromedidor';

  factory Medidor.fromMap(Map<String, dynamic> map) {
    return Medidor(
      id: int.tryParse(map['id'].toString()) ?? 0,
      codigo: map['codigo'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      tipo: map['tipo'] as String? ?? 'micromedidor',
      orden: int.tryParse(map['orden']?.toString() ?? '0') ?? 0,
      activo: map['activo'] as bool? ?? true,
      digitosEnteros: int.tryParse(map['digitos_enteros']?.toString() ?? '5') ?? 5,
      digitosDecimales: int.tryParse(map['digitos_decimales']?.toString() ?? '3') ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'tipo': tipo,
      'orden': orden,
      'activo': activo,
      'digitos_enteros': digitosEnteros,
      'digitos_decimales': digitosDecimales,
    };
  }

  Medidor copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? tipo,
    int? orden,
    bool? activo,
    int? digitosEnteros,
    int? digitosDecimales,
  }) {
    return Medidor(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      orden: orden ?? this.orden,
      activo: activo ?? this.activo,
      digitosEnteros: digitosEnteros ?? this.digitosEnteros,
      digitosDecimales: digitosDecimales ?? this.digitosDecimales,
    );
  }
}

/// Lectura individual de un medidor en una fecha y hora específica
class LecturaMedidor {
  final String? id;
  final String? jornadaId;
  final int medidorId;
  final String medidorNombre;
  final String tipoMedidor;
  final double lecturaActual;   // en m³
  final double lecturaAnterior; // en m³
  final double consumo;         // en m³ (lecturaActual - lecturaAnterior)
  final String? fotoUrl;
  final String metodoLectura;   // 'manual' | 'camara_ocr' | 'ocr_editado'
  final bool fueraDeRango;

  const LecturaMedidor({
    this.id,
    this.jornadaId,
    required this.medidorId,
    required this.medidorNombre,
    required this.tipoMedidor,
    required this.lecturaActual,
    required this.lecturaAnterior,
    required this.consumo,
    this.fotoUrl,
    this.metodoLectura = 'manual',
    this.fueraDeRango = false,
  });

  Map<String, dynamic> toMap({String? fkJornadaId}) {
    return {
      if (id != null) 'id': id,
      'jornada_id': fkJornadaId ?? jornadaId,
      'medidor_id': medidorId,
      'lectura_actual': lecturaActual,
      'lectura_anterior': lecturaAnterior,
      'consumo': consumo,
      'foto_url': fotoUrl,
      'metodo_lectura': metodoLectura,
      'fuera_de_rango': fueraDeRango,
    };
  }

  factory LecturaMedidor.fromMap(Map<String, dynamic> map) {
    return LecturaMedidor(
      id: map['id']?.toString(),
      jornadaId: map['jornada_id']?.toString(),
      medidorId: int.tryParse(map['medidor_id']?.toString() ?? '0') ?? 0,
      medidorNombre: map['medidor_nombre'] as String? ?? '',
      tipoMedidor: map['tipo_medidor'] as String? ?? 'micromedidor',
      lecturaActual: (map['lectura_actual'] as num?)?.toDouble() ?? 0.0,
      lecturaAnterior: (map['lectura_anterior'] as num?)?.toDouble() ?? 0.0,
      consumo: (map['consumo'] as num?)?.toDouble() ?? 0.0,
      fotoUrl: map['foto_url'] as String?,
      metodoLectura: map['metodo_lectura'] as String? ?? 'manual',
      fueraDeRango: map['fuera_de_rango'] as bool? ?? false,
    );
  }

  LecturaMedidor copyWith({
    String? id,
    String? jornadaId,
    int? medidorId,
    String? medidorNombre,
    String? tipoMedidor,
    double? lecturaActual,
    double? lecturaAnterior,
    double? consumo,
    String? fotoUrl,
    String? metodoLectura,
    bool? fueraDeRango,
  }) {
    return LecturaMedidor(
      id: id ?? this.id,
      jornadaId: jornadaId ?? this.jornadaId,
      medidorId: medidorId ?? this.medidorId,
      medidorNombre: medidorNombre ?? this.medidorNombre,
      tipoMedidor: tipoMedidor ?? this.tipoMedidor,
      lecturaActual: lecturaActual ?? this.lecturaActual,
      lecturaAnterior: lecturaAnterior ?? this.lecturaAnterior,
      consumo: consumo ?? this.consumo,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      metodoLectura: metodoLectura ?? this.metodoLectura,
      fueraDeRango: fueraDeRango ?? this.fueraDeRango,
    );
  }
}

/// Registro diario de toma de medidores (Formato "Registro de medidores de Agua")
class JornadaMedidores {
  final String id;
  final DateTime fecha;
  final String hora;
  final String responsableLectura;
  final String? observaciones;

  // Celdas calculadas automáticamente
  final double consumoTotalMicros;  // Suma de consumos de los 8 micromedidores (m³)
  final double consumoMacromedidor; // Consumo del macromedidor (m³)
  final double aguaNoRegistrada;    // Consumo Macro - Consumo Total Micros (m³)
  final bool fueraDeRango;

  final List<LecturaMedidor> lecturas;
  final String createdBy;
  final DateTime createdAt;

  const JornadaMedidores({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.responsableLectura,
    this.observaciones,
    required this.consumoTotalMicros,
    required this.consumoMacromedidor,
    required this.aguaNoRegistrada,
    this.fueraDeRango = false,
    this.lecturas = const [],
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String().split('T').first,
      'hora': hora,
      'responsable_lectura': responsableLectura,
      'observaciones': observaciones,
      'consumo_total_micros': consumoTotalMicros,
      'consumo_macromedidor': consumoMacromedidor,
      'agua_no_registrada': aguaNoRegistrada,
      'fuera_de_rango': fueraDeRango,
      'created_by': createdBy,
    };
  }

  factory JornadaMedidores.fromMap(
    Map<String, dynamic> map, {
    List<LecturaMedidor> lecturas = const [],
  }) {
    DateTime parseFecha(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return JornadaMedidores(
      id: map['id']?.toString() ?? '',
      fecha: parseFecha(map['fecha']),
      hora: map['hora']?.toString() ?? '09:00',
      responsableLectura: map['responsable_lectura'] as String? ?? '',
      observaciones: map['observaciones'] as String?,
      consumoTotalMicros: (map['consumo_total_micros'] as num?)?.toDouble() ?? 0.0,
      consumoMacromedidor: (map['consumo_macromedidor'] as num?)?.toDouble() ?? 0.0,
      aguaNoRegistrada: (map['agua_no_registrada'] as num?)?.toDouble() ?? 0.0,
      fueraDeRango: map['fuera_de_rango'] as bool? ?? false,
      lecturas: lecturas,
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: map['created_at'] != null ? parseFecha(map['created_at']) : DateTime.now(),
    );
  }

  double get porcentajePerdida {
    if (consumoMacromedidor == 0) return 0.0;
    return (aguaNoRegistrada / consumoMacromedidor) * 100;
  }
}
