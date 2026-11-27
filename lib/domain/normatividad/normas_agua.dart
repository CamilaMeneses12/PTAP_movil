/// Normativa colombiana de agua para consumo humano que aplica en la PTAP.
///
/// Solo describe cada norma y qué parte aplica en la planta. Los valores límite NO se escriben
/// aquí: la pantalla los toma de ValidadorRangos, que es donde la app ya los usa.
class NormaAgua {
  final String id;
  final String tipo; // 'Decreto' | 'Resolución'
  final String numero;
  final int anio;
  final String entidad;
  final String titulo;
  final String deQueTrata;
  final List<String> aplicaEnPtap;
  final String? nota;

  const NormaAgua({
    required this.id,
    required this.tipo,
    required this.numero,
    required this.anio,
    required this.entidad,
    required this.titulo,
    required this.deQueTrata,
    required this.aplicaEnPtap,
    this.nota,
  });

  String get nombreCorto => '$tipo $numero de $anio';
}

class NormasAgua {
  static const String decreto1575 = 'decreto_1575_2007';
  static const String res2115 = 'res_2115_2007';
  static const String res811 = 'res_811_2008';
  static const String res082 = 'res_082_2009';
  static const String res4716 = 'res_4716_2010';
  static const String decreto1076 = 'decreto_1076_2015';
  static const String res0330 = 'res_0330_2017';

  // TODO: verificar con la norma las entidades firmantes y los apartes que aplican en la PTAP.
  static const List<NormaAgua> todas = [
    NormaAgua(
      id: decreto1575,
      tipo: 'Decreto',
      numero: '1575',
      anio: 2007,
      entidad: 'Ministerio de la Protección Social (hoy Ministerio de Salud y Protección Social)',
      titulo: 'Sistema para la Protección y Control de la Calidad del Agua para Consumo Humano',
      deQueTrata:
          'Crea el sistema de protección y control de la calidad del agua para consumo humano y define '
          'las responsabilidades de quien la suministra y de las autoridades sanitarias.',
      aplicaEnPtap: [
        'La planta, como prestadora, debe controlar la calidad del agua que entrega.',
        'Los registros diarios del formato DO-F-070 son la evidencia de ese control.',
      ],
      nota: 'Está compilado en el Decreto 780 de 2016 (Decreto Único Reglamentario del Sector Salud).',
    ),
    NormaAgua(
      id: res2115,
      tipo: 'Resolución',
      numero: '2115',
      anio: 2007,
      entidad: 'Ministerio de la Protección Social y Ministerio de Ambiente, Vivienda y Desarrollo Territorial',
      titulo: 'Características, instrumentos básicos y frecuencias del sistema de control y vigilancia',
      deQueTrata:
          'Fija las características físicas, químicas y microbiológicas que debe cumplir el agua para '
          'consumo humano y las frecuencias de control.',
      aplicaEnPtap: [
        'Los rangos de pH, turbidez, color aparente y cloro residual libre del agua tratada que valida la app.',
        'Las alertas del DO-F-070 se generan cuando un valor queda fuera de esos rangos.',
      ],
    ),
    NormaAgua(
      id: res811,
      tipo: 'Resolución',
      numero: '811',
      anio: 2008,
      entidad: 'Ministerio de la Protección Social y Ministerio de Ambiente, Vivienda y Desarrollo Territorial',
      titulo: 'Puntos de muestreo en la red de distribución',
      deQueTrata:
          'Define cómo se establecen y concertan los lugares y puntos de muestreo para el control y la '
          'vigilancia de la calidad del agua en la red de distribución.',
      aplicaEnPtap: [
        'Los puntos de control de la red que se registran en el formato DO-F-070.',
      ],
    ),
    NormaAgua(
      id: res082,
      tipo: 'Resolución',
      numero: '082',
      anio: 2009,
      entidad: 'Ministerio de la Protección Social',
      titulo: 'Buenas prácticas sanitarias e inspección',
      deQueTrata:
          'Adopta los formularios para las visitas de inspección sanitaria a los sistemas de suministro '
          'de agua para consumo humano.',
      aplicaEnPtap: [
        'Las visitas de inspección sanitaria a la planta revisan sus prácticas y sus registros.',
      ],
    ),
    NormaAgua(
      id: res4716,
      tipo: 'Resolución',
      numero: '4716',
      anio: 2010,
      entidad: 'Ministerio de la Protección Social y Ministerio de Ambiente, Vivienda y Desarrollo Territorial',
      titulo: 'Mapas de riesgo de la calidad del agua',
      deQueTrata:
          'Reglamenta la elaboración de los mapas de riesgo de la calidad del agua para consumo humano.',
      aplicaEnPtap: [
        'El mapa de riesgo de la fuente que abastece la planta (Quebrada La Seca).',
        'Los registros de agua cruda del DO-F-070 ayudan a conocer el comportamiento de la fuente.',
      ],
    ),
    NormaAgua(
      id: decreto1076,
      tipo: 'Decreto',
      numero: '1076',
      anio: 2015,
      entidad: 'Ministerio de Ambiente y Desarrollo Sostenible',
      titulo: 'Decreto Único Reglamentario del Sector Ambiente: concesión de aguas',
      deQueTrata:
          'Reúne las normas ambientales, entre ellas las que regulan la concesión para usar aguas '
          'superficiales.',
      aplicaEnPtap: [
        'La concesión de aguas que permite captar de la Quebrada La Seca.',
        'Los aforos de caudal registran cuánta agua lleva la fuente.',
      ],
      // TODO: verificar con la norma el caudal concedido y la autoridad ambiental que otorgó la concesión.
      nota: 'El caudal concedido y la autoridad ambiental están pendientes de confirmar.',
    ),
    NormaAgua(
      id: res0330,
      tipo: 'Resolución',
      numero: '0330',
      anio: 2017,
      entidad: 'Ministerio de Vivienda, Ciudad y Territorio',
      titulo: 'Reglamento Técnico del Sector de Agua Potable y Saneamiento Básico (RAS)',
      deQueTrata:
          'Fija los requisitos técnicos para el diseño, la construcción, la puesta en marcha, la operación, '
          'el mantenimiento y la rehabilitación de los sistemas de agua potable y saneamiento básico.',
      aplicaEnPtap: [
        'La operación y el mantenimiento de los procesos de potabilización de la planta.',
        'El control diario de los procesos (agua cruda, filtrada y clorada) que se registra en el DO-F-070.',
        'La medición de caudales y volúmenes con aforos y medidores.',
      ],
      nota: 'Fue modificada por la Resolución 0799 de 2021.',
    ),
  ];

  static NormaAgua? buscar(String? id) {
    for (final n in todas) {
      if (n.id == id) return n;
    }
    return null;
  }
}
