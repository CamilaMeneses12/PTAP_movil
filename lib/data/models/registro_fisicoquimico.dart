/// Medición individual en un punto de control de la red de distribución
class MedicionPuntoControl {
  final String? id;
  final String? registroFisicoquimicoId;
  final int? puntoMuestreoId;
  final String areaNombre;
  final double? turbidez;       // 0.0 - 2.0 NTU
  final double? ph;             // 6.5 - 9.0
  final double? colorAparente;  // Máx 15 UPC
  final double? cloroResidual;  // 0.3 - 2.0 mg/L
  final bool fueraDeRango;
  final String? observacion;

  const MedicionPuntoControl({
    this.id,
    this.registroFisicoquimicoId,
    this.puntoMuestreoId,
    required this.areaNombre,
    this.turbidez,
    this.ph,
    this.colorAparente,
    this.cloroResidual,
    this.fueraDeRango = false,
    this.observacion,
  });

  Map<String, dynamic> toMap({String? fkRegistroId}) {
    return {
      if (id != null) 'id': id,
      'registro_fisicoquimico_id': fkRegistroId ?? registroFisicoquimicoId,
      if (puntoMuestreoId != null) 'punto_muestreo_id': puntoMuestreoId,
      'area_nombre': areaNombre,
      'turbidez': turbidez,
      'ph': ph,
      'color_aparente': colorAparente,
      'cloro_residual': cloroResidual,
      'fuera_de_rango': fueraDeRango,
      'observacion': observacion,
    };
  }

  factory MedicionPuntoControl.fromMap(Map<String, dynamic> map) {
    return MedicionPuntoControl(
      id: map['id']?.toString(),
      registroFisicoquimicoId: map['registro_fisicoquimico_id']?.toString(),
      puntoMuestreoId: map['punto_muestreo_id'] != null
          ? int.tryParse(map['punto_muestreo_id'].toString())
          : null,
      areaNombre: map['area_nombre'] as String? ?? 'Área de Control',
      turbidez: (map['turbidez'] as num?)?.toDouble(),
      ph: (map['ph'] as num?)?.toDouble(),
      colorAparente: (map['color_aparente'] as num?)?.toDouble(),
      cloroResidual: (map['cloro_residual'] as num?)?.toDouble(),
      fueraDeRango: map['fuera_de_rango'] as bool? ?? false,
      observacion: map['observacion'] as String?,
    );
  }

  MedicionPuntoControl copyWith({
    String? id,
    String? registroFisicoquimicoId,
    int? puntoMuestreoId,
    String? areaNombre,
    double? turbidez,
    double? ph,
    double? colorAparente,
    double? cloroResidual,
    bool? fueraDeRango,
    String? observacion,
  }) {
    return MedicionPuntoControl(
      id: id ?? this.id,
      registroFisicoquimicoId: registroFisicoquimicoId ?? this.registroFisicoquimicoId,
      puntoMuestreoId: puntoMuestreoId ?? this.puntoMuestreoId,
      areaNombre: areaNombre ?? this.areaNombre,
      turbidez: turbidez ?? this.turbidez,
      ph: ph ?? this.ph,
      colorAparente: colorAparente ?? this.colorAparente,
      cloroResidual: cloroResidual ?? this.cloroResidual,
      fueraDeRango: fueraDeRango ?? this.fueraDeRango,
      observacion: observacion ?? this.observacion,
    );
  }
}

/// Modelo del registro completo de seguimiento de calidad del agua (Formato DO-F-070)
class RegistroFisicoquimico {
  final String id;
  final DateTime fecha;
  final String hora; // "HH:mm"
  final String regional;
  final String centroFormacion;
  final String sede;

  // Agua Cruda
  final double? crudaCaudalEntrada; // L/S
  final double? crudaPh;            // 5.0 - 9.0
  final double? crudaTurbidez;      // Máx 10 UJT
  final double? crudaColor;         // Máx 20 UPC
  final double? crudaDureza;        // mg/L CaCO3
  final String? crudaDosisCoagulante; // mg/L o texto (ej: "mínima")

  // Agua Filtrada
  final double? filtradaTurbidez;   // 0.0 - 2.0 NTU
  final double? filtradaPh;          // 6.5 - 9.0

  // Agua Clorada
  final double? cloradaTurbidez;     // 0.0 - 2.0 NTU
  final double? cloradaPh;           // 6.5 - 9.0
  final double? cloradaColorAparente;// Máx 15 UPC
  final double? cloradaCloroResidual;// 0.3 - 2.0 mg/L

  // Mediciones en Puntos de Control (Red)
  final List<MedicionPuntoControl> puntosControl;

  // Cierre y trazabilidad
  final String? observaciones;
  final String responsableNombre;
  final bool fueraDeRango;
  final String createdBy;
  final DateTime createdAt;

  const RegistroFisicoquimico({
    required this.id,
    required this.fecha,
    required this.hora,
    this.regional = 'Distrito Capital',
    this.centroFormacion = 'Centro de Tecnologías Agroindustriales',
    this.sede = 'Sede Principal',
    this.crudaCaudalEntrada,
    this.crudaPh,
    this.crudaTurbidez,
    this.crudaColor,
    this.crudaDureza,
    this.crudaDosisCoagulante,
    this.filtradaTurbidez,
    this.filtradaPh,
    this.cloradaTurbidez,
    this.cloradaPh,
    this.cloradaColorAparente,
    this.cloradaCloroResidual,
    this.puntosControl = const [],
    this.observaciones,
    required this.responsableNombre,
    this.fueraDeRango = false,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String().split('T').first,
      'hora': hora,
      'regional': regional,
      'centro_formacion': centroFormacion,
      'sede': sede,
      'cruda_caudal_entrada': crudaCaudalEntrada,
      'cruda_ph': crudaPh,
      'cruda_turbidez': crudaTurbidez,
      'cruda_color': crudaColor,
      'cruda_dureza': crudaDureza,
      'cruda_dosis_coagulante': crudaDosisCoagulante,
      'filtrada_turbidez': filtradaTurbidez,
      'filtrada_ph': filtradaPh,
      'clorada_turbidez': cloradaTurbidez,
      'clorada_ph': cloradaPh,
      'clorada_color_aparente': cloradaColorAparente,
      'clorada_cloro_residual': cloradaCloroResidual,
      'observaciones': observaciones,
      'responsable_nombre': responsableNombre,
      'fuera_de_rango': fueraDeRango,
      'created_by': createdBy,
    };
  }

  factory RegistroFisicoquimico.fromMap(
    Map<String, dynamic> map, {
    List<MedicionPuntoControl> puntos = const [],
  }) {
    DateTime parseFecha(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return RegistroFisicoquimico(
      id: map['id']?.toString() ?? '',
      fecha: parseFecha(map['fecha']),
      hora: map['hora']?.toString() ?? '08:00',
      regional: map['regional'] as String? ?? 'Distrito Capital',
      centroFormacion: map['centro_formacion'] as String? ?? 'Centro de Tecnologías Agroindustriales',
      sede: map['sede'] as String? ?? 'Sede Principal',
      crudaCaudalEntrada: (map['cruda_caudal_entrada'] as num?)?.toDouble(),
      crudaPh: (map['cruda_ph'] as num?)?.toDouble(),
      crudaTurbidez: (map['cruda_turbidez'] as num?)?.toDouble(),
      crudaColor: (map['cruda_color'] as num?)?.toDouble(),
      crudaDureza: (map['cruda_dureza'] as num?)?.toDouble(),
      crudaDosisCoagulante: map['cruda_dosis_coagulante']?.toString(),
      filtradaTurbidez: (map['filtrada_turbidez'] as num?)?.toDouble(),
      filtradaPh: (map['filtrada_ph'] as num?)?.toDouble(),
      cloradaTurbidez: (map['clorada_turbidez'] as num?)?.toDouble(),
      cloradaPh: (map['clorada_ph'] as num?)?.toDouble(),
      cloradaColorAparente: (map['clorada_color_aparente'] as num?)?.toDouble(),
      cloradaCloroResidual: (map['clorada_cloro_residual'] as num?)?.toDouble(),
      puntosControl: puntos,
      observaciones: map['observaciones'] as String?,
      responsableNombre: map['responsable_nombre'] as String? ?? '',
      fueraDeRango: map['fuera_de_rango'] as bool? ?? false,
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: map['created_at'] != null ? parseFecha(map['created_at']) : DateTime.now(),
    );
  }
}
