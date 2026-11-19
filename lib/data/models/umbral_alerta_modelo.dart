import 'package:intl/intl.dart';

/// Umbral de alerta configurable (tabla `rangos_parametros` en Supabase).
///
/// `seccion` + `parametro` identifican el umbral de forma única
/// (ej. 'agua_clorada' + 'cloro_residual', 'operacion' + 'caudal_entrada').
class UmbralAlerta {
  final String seccion;
  final String parametro;
  final String nombre;
  final String unidad;
  final double? minimo;
  final double? maximo;

  const UmbralAlerta({
    required this.seccion,
    required this.parametro,
    required this.nombre,
    required this.unidad,
    this.minimo,
    this.maximo,
  });

  String get clave => '$seccion.$parametro';

  /// true cuando el límite inferior no aplica (turbidez, color: solo máximo)
  bool get soloMaximo => maximo != null && (minimo == null || minimo == 0);

  /// true cuando solo existe límite inferior (nivel mínimo de tanque)
  bool get soloMinimo => minimo != null && maximo == null;

  /// Texto legible del rango, con coma decimal (es_CO): "110–140 L/s", "máx. 2 NTU", "mín. 40 %"
  String get rangoTexto {
    final f = NumberFormat('#,##0.##', 'es_CO');
    final u = (unidad.isEmpty || unidad == 'pH') ? '' : ' $unidad';
    if (soloMinimo) return 'mín. ${f.format(minimo)}$u';
    if (soloMaximo) return 'máx. ${f.format(maximo)}$u';
    if (minimo != null && maximo != null) {
      return '${f.format(minimo)}–${f.format(maximo)}$u';
    }
    return 'Sin límite';
  }

  UmbralAlerta copyWith({double? minimo, double? maximo, bool limpiarMaximo = false}) {
    return UmbralAlerta(
      seccion: seccion,
      parametro: parametro,
      nombre: nombre,
      unidad: unidad,
      minimo: minimo ?? this.minimo,
      maximo: limpiarMaximo ? null : (maximo ?? this.maximo),
    );
  }

  factory UmbralAlerta.fromMap(Map<String, dynamic> map) {
    return UmbralAlerta(
      seccion: map['seccion'] as String,
      parametro: map['parametro'] as String,
      nombre: (map['nombre_visible'] as String?) ?? map['parametro'] as String,
      unidad: (map['unidad'] as String?) ?? '',
      minimo: (map['valor_minimo'] as num?)?.toDouble(),
      maximo: (map['valor_maximo'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'seccion': seccion,
        'parametro': parametro,
        'nombre_visible': nombre,
        'unidad': unidad,
        'valor_minimo': minimo,
        'valor_maximo': maximo,
      };
}
