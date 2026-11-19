/// Nivel de confianza de una lectura obtenida por OCR.
enum ConfianzaOcr { alta, media, baja }

/// Resultado de interpretar el texto que el OCR leyó en el contador de un medidor.
class ResultadoLecturaOcr {
  /// Valor en m³ (enteros de los rodillos negros + decimales de los rojos).
  final double valor;

  /// Dígitos usados para construir el valor (sin separadores).
  final String digitos;
  final ConfianzaOcr confianza;

  const ResultadoLecturaOcr({required this.valor, required this.digitos, required this.confianza});
}

/// Convierte el texto reconocido por el OCR en una lectura numérica del medidor.
///
/// Los contadores de los micromedidores muestran rodillos negros (m³ enteros) seguidos de
/// rodillos rojos (decimales), sin coma visible. Por eso el valor se arma con la cantidad de
/// dígitos enteros y decimales configurada para cada medidor (por defecto 5 + 3).
class InterpreteLecturaMedidor {
  /// Caracteres que el OCR suele confundir con dígitos en los rodillos.
  static const Map<String, String> _confusiones = {
    'O': '0', 'o': '0', 'Q': '0', 'D': '0', 'U': '0',
    'I': '1', 'l': '1', 'i': '1', '|': '1', '!': '1', 'L': '1',
    'Z': '2', 'z': '2',
    'S': '5', 's': '5',
    'G': '6', 'b': '6',
    'T': '7',
    'B': '8',
    'g': '9', 'q': '9',
  };

  /// Corrige confusiones solo en fragmentos que ya son mayoritariamente numéricos,
  /// para no convertir palabras impresas en la carátula ("LITROS", "m³") en números.
  static String _corregirFragmento(String fragmento) {
    final digitos = fragmento.split('').where((c) => _esDigito(c)).length;
    if (digitos == 0 || digitos * 2 < fragmento.length) return fragmento;
    return fragmento.split('').map((c) => _confusiones[c] ?? c).join();
  }

  static bool _esDigito(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

  /// Extrae de cada línea la secuencia numérica más larga, uniendo grupos separados por espacios
  /// (el OCR suele separar los rodillos: "00 123 45").
  static List<String> _candidatos(String texto) {
    final candidatos = <String>[];
    for (final linea in texto.split(RegExp(r'[\r\n]+'))) {
      final corregida = linea
          .split(RegExp(r'\s+'))
          .where((f) => f.isNotEmpty)
          .map(_corregirFragmento)
          .join(' ');
      final grupos = RegExp(r'\d+(?:[ ]\d+)*(?:[.,]\d+)?').allMatches(corregida);
      for (final g in grupos) {
        candidatos.add(g.group(0)!.replaceAll(' ', ''));
      }
    }
    return candidatos;
  }

  /// Elige la mejor entre varias lecturas candidatas (modelo propio, ML Kit, recorte girado...).
  /// Gana la creíble frente a la lectura anterior y, entre ellas, la de mayor confianza.
  /// En empate gana la primera (por eso el modelo propio se pasa primero).
  /// Si dos fuentes leen el mismo valor, la confianza sube a alta.
  /// Devuelve el índice elegido, o -1 si todas son null.
  static int elegirMejor(List<ResultadoLecturaOcr?> opciones, {double? lecturaAnterior}) {
    bool creible(ResultadoLecturaOcr l) =>
        lecturaAnterior == null ||
        lecturaAnterior <= 0 ||
        (l.valor >= lecturaAnterior - 0.01 && l.valor - lecturaAnterior <= consumoMaximoCreible);
    var mejor = -1;
    for (var i = 0; i < opciones.length; i++) {
      final l = opciones[i];
      if (l == null) continue;
      if (mejor == -1) {
        mejor = i;
        continue;
      }
      final m = opciones[mejor]!;
      final lc = creible(l), mc = creible(m);
      if (lc != mc) {
        if (lc) mejor = i;
      } else if (l.confianza.index < m.confianza.index) {
        mejor = i;
      }
    }
    return mejor;
  }

  /// La lectura elegida, con confianza alta si otra fuente leyó exactamente lo mismo.
  static ResultadoLecturaOcr? mejorLectura(List<ResultadoLecturaOcr?> opciones, {double? lecturaAnterior}) {
    final i = elegirMejor(opciones, lecturaAnterior: lecturaAnterior);
    if (i < 0) return null;
    final elegida = opciones[i]!;
    final coincide = [
      for (var j = 0; j < opciones.length; j++)
        if (j != i && opciones[j] != null && (opciones[j]!.valor - elegida.valor).abs() < 1e-9) j,
    ].isNotEmpty;
    return coincide
        ? ResultadoLecturaOcr(valor: elegida.valor, digitos: elegida.digitos, confianza: ConfianzaOcr.alta)
        : elegida;
  }

  /// Consumo máximo creíble entre dos lecturas de un micromedidor (m³).
  static const double consumoMaximoCreible = 100;

  /// Convierte un candidato (solo dígitos, o con separador explícito) en una lectura.
  static ResultadoLecturaOcr? _aLectura(String candidato, int digitosEnteros, int digitosDecimales) {
    final total = digitosEnteros + digitosDecimales;

    // Si el OCR leyó un separador decimal explícito, respetarlo.
    if (RegExp(r'[.,]').hasMatch(candidato)) {
      final valor = double.tryParse(candidato.replaceAll(',', '.'));
      if (valor == null) return null;
      return ResultadoLecturaOcr(
        valor: valor,
        digitos: candidato.replaceAll(RegExp(r'[.,]'), ''),
        confianza: ConfianzaOcr.media,
      );
    }

    var digitos = candidato;
    if (digitos.length > total) digitos = digitos.substring(0, total);

    final double valor;
    if (digitos.length <= digitosEnteros) {
      valor = double.parse(digitos);
    } else {
      valor = double.parse('${digitos.substring(0, digitosEnteros)}.${digitos.substring(digitosEnteros)}');
    }

    final ConfianzaOcr confianza;
    if (candidato.length == total) {
      confianza = ConfianzaOcr.alta;
    } else if (candidato.length >= digitosEnteros) {
      confianza = ConfianzaOcr.media;
    } else {
      confianza = ConfianzaOcr.baja;
    }
    return ResultadoLecturaOcr(valor: valor, digitos: digitos, confianza: confianza);
  }

  /// Devuelve null si no encontró ningún número en el texto.
  ///
  /// Con [lecturaAnterior] elige el número más cercano por encima de la lectura anterior:
  /// así descarta el número de serie grabado en la carcasa (ej. "23 093377"), que también
  /// tiene 8 dígitos pero no es una lectura posible.
  static ResultadoLecturaOcr? interpretar(
    String texto, {
    int digitosEnteros = 4,
    int digitosDecimales = 4,
    double? lecturaAnterior,
  }) {
    final total = digitosEnteros + digitosDecimales;
    int largo(String c) => c.replaceAll(RegExp(r'[.,]'), '').length;
    // Menos de 3 dígitos suele ser texto de la carátula ("m3", "Qn 1,5"), no la lectura:
    // los rodillos siempre muestran todas sus cifras, con ceros a la izquierda.
    final candidatos = _candidatos(texto).where((c) => largo(c) >= 3).toList();
    if (candidatos.isEmpty) return null;

    final lecturas = [
      for (final c in candidatos) ?_aLectura(c, digitosEnteros, digitosDecimales),
    ];
    if (lecturas.isEmpty) return null;

    if (lecturaAnterior != null && lecturaAnterior > 0) {
      // Tolerancia pequeña hacia atrás: el último rodillo puede estar a medio girar.
      final creibles = lecturas
          .where((l) => l.valor >= lecturaAnterior - 0.01 && l.valor - lecturaAnterior <= consumoMaximoCreible)
          .toList()
        ..sort((a, b) {
          final porDigitos = (a.digitos.length - total).abs().compareTo((b.digitos.length - total).abs());
          if (porDigitos != 0) return porDigitos;
          return (a.valor - lecturaAnterior).abs().compareTo((b.valor - lecturaAnterior).abs());
        });
      if (creibles.isNotEmpty) return creibles.first;
    }

    // Sin lectura anterior (o ningún candidato creíble): el de la cantidad de dígitos esperada.
    lecturas.sort((a, b) {
      final da = (a.digitos.length - total).abs();
      final db = (b.digitos.length - total).abs();
      if (da != db) return da.compareTo(db);
      return b.digitos.length.compareTo(a.digitos.length);
    });
    final elegida = lecturas.first;
    final sinPista = lecturaAnterior == null || lecturaAnterior <= 0;
    return ResultadoLecturaOcr(
      valor: elegida.valor,
      digitos: elegida.digitos,
      // Si había lectura anterior y ningún número es creíble, avisar al operario.
      confianza: sinPista ? elegida.confianza : ConfianzaOcr.baja,
    );
  }
}
