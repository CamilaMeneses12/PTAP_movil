enum TipoRegistroHistorial {
  todos,
  fisicoquimico,
  medidores,
  caudal,
}

/// Representación unificada de cualquier registro del sistema para el historial
class ItemHistorial {
  final String id;
  final TipoRegistroHistorial tipo;
  final DateTime fecha;
  final String hora;
  final String titulo;
  final String subtitulo;
  final String responsable;
  /// UUID del usuario que creó el registro (created_by), si se conoce
  final String? creadoPorId;
  final bool tieneAlerta;
  final String? mensajeAlerta;
  final dynamic objetoOriginal;

  const ItemHistorial({
    required this.id,
    required this.tipo,
    required this.fecha,
    required this.hora,
    required this.titulo,
    required this.subtitulo,
    required this.responsable,
    this.creadoPorId,
    this.tieneAlerta = false,
    this.mensajeAlerta,
    required this.objetoOriginal,
  });

  String get tipoTexto {
    switch (tipo) {
      case TipoRegistroHistorial.fisicoquimico:
        return 'Fisicoquímico (DO-F-070)';
      case TipoRegistroHistorial.medidores:
        return 'Lectura de Medidores';
      case TipoRegistroHistorial.caudal:
        return 'Aforo Caudal La Seca';
      case TipoRegistroHistorial.todos:
        return 'Todos';
    }
  }
}
