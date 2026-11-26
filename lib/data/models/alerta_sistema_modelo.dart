enum SeveridadAlerta {
  critica,
  advertencia,
  informacion,
}

/// Formato del registro que generó la alerta.
enum TipoFormatoAlerta { fisicoquimico, medidores, aforo }

extension TipoFormatoAlertaTexto on TipoFormatoAlerta {
  String get nombre => switch (this) {
        TipoFormatoAlerta.fisicoquimico => 'DO-F-070 · Análisis fisicoquímico',
        TipoFormatoAlerta.medidores => 'Medidores · Balance de agua',
        TipoFormatoAlerta.aforo => 'Aforo · Quebrada La Seca',
      };
}

/// Seguimiento de la alerta.
enum EstadoAlerta { nueva, leida, resuelta }

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

  // Origen de la alerta: con estos datos el detalle muestra el registro y el historial del parámetro.
  final TipoFormatoAlerta? tipoFormato;
  final String? registroId;
  final String? responsable;
  final String? puntoControl; // punto de muestreo de la red o medidor

  /// Clave del parámetro en el catálogo de alertas (ver CatalogoParametrosAlerta).
  final String? parametroClave;

  /// Rango vigente cuando se registró el valor.
  final double? minimo;
  final double? maximo;
  final String? unidad;

  // Seguimiento
  final String? resueltaPor;
  final DateTime? fechaResolucion;
  final String? notaResolucion;

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
    this.tipoFormato,
    this.registroId,
    this.responsable,
    this.puntoControl,
    this.parametroClave,
    this.minimo,
    this.maximo,
    this.unidad,
    this.resueltaPor,
    this.fechaResolucion,
    this.notaResolucion,
  });

  EstadoAlerta get estado => resuelta
      ? EstadoAlerta.resuelta
      : (leida ? EstadoAlerta.leida : EstadoAlerta.nueva);

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
    TipoFormatoAlerta? tipoFormato,
    String? registroId,
    String? responsable,
    String? puntoControl,
    String? parametroClave,
    double? minimo,
    double? maximo,
    String? unidad,
    String? resueltaPor,
    DateTime? fechaResolucion,
    String? notaResolucion,
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
      tipoFormato: tipoFormato ?? this.tipoFormato,
      registroId: registroId ?? this.registroId,
      responsable: responsable ?? this.responsable,
      puntoControl: puntoControl ?? this.puntoControl,
      parametroClave: parametroClave ?? this.parametroClave,
      minimo: minimo ?? this.minimo,
      maximo: maximo ?? this.maximo,
      unidad: unidad ?? this.unidad,
      resueltaPor: resueltaPor ?? this.resueltaPor,
      fechaResolucion: fechaResolucion ?? this.fechaResolucion,
      notaResolucion: notaResolucion ?? this.notaResolucion,
    );
  }
}
