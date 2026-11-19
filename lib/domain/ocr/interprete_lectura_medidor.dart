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

  /// Devuelve null si no encontró ningún número en el texto.
  static ResultadoLecturaOcr? interpretar(
    String texto, {
    int digitosEnteros = 5,
    int digitosDecimales = 3,
  }) {
    final total = digitosEnteros + digitosDecimales;
    int largo(String c) => c.replaceAll(RegExp(r'[.,]'), '').length;
    // Menos de 3 dígitos suele ser texto de la carátula ("m3", "Qn 1,5"), no la lectura:
    // los rodillos siempre muestran todas sus cifras, con ceros a la izquierda.
    final candidatos = _candidatos(texto).where((c) => largo(c) >= 3).toList();
    if (candidatos.isEmpty) return null;

    // Preferir el candidato con la cantidad de dígitos esperada; si no, el más largo.
    candidatos.sort((a, b) {
      final da = (largo(a) - total).abs();
      final db = (largo(b) - total).abs();
      if (da != db) return da.compareTo(db);
      return largo(b).compareTo(largo(a));
    });
    final elegido = candidatos.first;

    // Si el OCR leyó un separador decimal explícito, respetarlo.
    if (RegExp(r'[.,]').hasMatch(elegido)) {
      final valor = double.tryParse(elegido.replaceAll(',', '.'));
      if (valor == null) return null;
      return ResultadoLecturaOcr(
        valor: valor,
        digitos: elegido.replaceAll(RegExp(r'[.,]'), ''),
        confianza: ConfianzaOcr.media,
      );
    }

    var digitos = elegido;
    if (digitos.length > total) digitos = digitos.substring(0, total);

    final double valor;
    if (digitos.length <= digitosEnteros) {
      valor = double.parse(digitos);
    } else {
      final enteros = digitos.substring(0, digitosEnteros);
      final decimales = digitos.substring(digitosEnteros);
      valor = double.parse('$enteros.$decimales');
    }

    final ConfianzaOcr confianza;
    if (elegido.length == total) {
      confianza = ConfianzaOcr.alta;
    } else if (elegido.length >= digitosEnteros) {
      confianza = ConfianzaOcr.media;
    } else {
      confianza = ConfianzaOcr.baja;
    }

    return ResultadoLecturaOcr(valor: valor, digitos: digitos, confianza: confianza);
  }
}
