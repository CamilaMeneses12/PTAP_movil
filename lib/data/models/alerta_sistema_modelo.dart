enum SeveridadAlerta {
  critica,
  advertencia,
  informacion,
}

class AlertaSistema {
  final String id;
  final String titulo;
  final String descripcion;
  final SeveridadAlerta severidad;
  final DateTime fechaHora;
  final String hora;
  final bool leida;
  final bool resuelta;
  final String? parametro;
  final double? valorRegistrado;
  final String? rangoEsperado;
  final String grupoFecha; // 'HOY' | 'AYER' | 'ANTERIORES'

  const AlertaSistema({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.severidad,
    required this.fechaHora,
    required this.hora,
    this.leida = false,
    this.resuelta = false,
    this.parametro,
    this.valorRegistrado,
    this.rangoEsperado,
    this.grupoFecha = 'HOY',
  });

  AlertaSistema copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    SeveridadAlerta? severidad,
    DateTime? fechaHora,
    String? hora,
    bool? leida,
    bool? resuelta,
    String? parametro,
    double? valorRegistrado,
    String? rangoEsperado,
    String? grupoFecha,
  }) {
    return AlertaSistema(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      severidad: severidad ?? this.severidad,
      fechaHora: fechaHora ?? this.fechaHora,
      hora: hora ?? this.hora,
      leida: leida ?? this.leida,
      resuelta: resuelta ?? this.resuelta,
      parametro: parametro ?? this.parametro,
      valorRegistrado: valorRegistrado ?? this.valorRegistrado,
      rangoEsperado: rangoEsperado ?? this.rangoEsperado,
      grupoFecha: grupoFecha ?? this.grupoFecha,
    );
  }
}
