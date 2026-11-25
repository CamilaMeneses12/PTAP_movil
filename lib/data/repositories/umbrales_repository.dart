import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/supabase_config.dart';
import '../../domain/validators/validador_rangos.dart';
import '../models/umbral_alerta_modelo.dart';

/// Lee y guarda los umbrales de alerta en la tabla `rangos_parametros`.
/// Sin conexión usa los valores normativos por defecto (Res. 2115 de 2007 / DO-F-070).
class UmbralesRepository {
  final SupabaseClient? _cliente;

  UmbralesRepository({SupabaseClient? cliente})
      : _cliente = cliente ?? (SupabaseConfig.estaInicializado ? SupabaseConfig.cliente : null);

  static const List<String> _secciones = ['operacion', 'agua_cruda', 'agua_clorada'];

  /// Valores por defecto, en el orden en que se muestran en el Perfil.
  static List<UmbralAlerta> predeterminados() => const [
        UmbralAlerta(seccion: 'operacion', parametro: 'caudal_entrada', nombre: 'Caudal de entrada', unidad: 'L/s', minimo: 110, maximo: 140),
        UmbralAlerta(seccion: 'operacion', parametro: 'nivel_tanque', nombre: 'Nivel mínimo de tanque', unidad: '%', minimo: 40),
        UmbralAlerta(seccion: 'agua_cruda', parametro: 'ph', nombre: 'pH agua cruda', unidad: 'pH', minimo: 5.0, maximo: 9.0),
        UmbralAlerta(seccion: 'agua_cruda', parametro: 'turbidez', nombre: 'Turbidez agua cruda', unidad: 'UJT', minimo: 0, maximo: 10),
        UmbralAlerta(seccion: 'agua_cruda', parametro: 'color', nombre: 'Color agua cruda', unidad: 'UPC', minimo: 0, maximo: 20),
        UmbralAlerta(seccion: 'agua_clorada', parametro: 'ph', nombre: 'pH agua tratada', unidad: 'pH', minimo: 6.5, maximo: 9.0),
        UmbralAlerta(seccion: 'agua_clorada', parametro: 'turbidez', nombre: 'Turbidez agua tratada', unidad: 'NTU', minimo: 0, maximo: 2),
        UmbralAlerta(seccion: 'agua_clorada', parametro: 'color_aparente', nombre: 'Color aparente', unidad: 'UPC', minimo: 0, maximo: 15),
        UmbralAlerta(seccion: 'agua_clorada', parametro: 'cloro_residual', nombre: 'Cloro residual libre', unidad: 'mg/L', minimo: 0.3, maximo: 2.0),
      ];

  static final List<UmbralAlerta> _memoria = predeterminados();

  /// Obtiene los umbrales: los de Supabase reemplazan a los valores por defecto.
  Future<List<UmbralAlerta>> obtener() async {
    if (_cliente != null) {
      try {
        final res = await _cliente
            .from('rangos_parametros')
            .select('seccion, parametro, nombre_visible, unidad, valor_minimo, valor_maximo')
            .inFilter('seccion', _secciones);
        final remotos = {
          for (final m in (res as List)) UmbralAlerta.fromMap(m as Map<String, dynamic>).clave:
              UmbralAlerta.fromMap(m),
        };
        for (var i = 0; i < _memoria.length; i++) {
          final remoto = remotos[_memoria[i].clave];
          if (remoto != null) {
            _memoria[i] = UmbralAlerta(
              seccion: _memoria[i].seccion,
              parametro: _memoria[i].parametro,
              nombre: _memoria[i].nombre,
              unidad: _memoria[i].unidad,
              minimo: remoto.minimo,
              maximo: remoto.maximo,
            );
          }
        }
      } catch (e) {
        debugPrint('No se pudieron leer los umbrales de Supabase, usando valores locales: $e');
      }
    }
    return List.unmodifiable(_memoria);
  }

  /// Guarda un umbral. Lanza excepción si Supabase rechaza el cambio.
  Future<void> actualizar(UmbralAlerta umbral) async {
    if (_cliente != null) {
      await _cliente.from('rangos_parametros').upsert(
            umbral.toMap(),
            onConflict: 'seccion,parametro',
          );
    }
    final idx = _memoria.indexWhere((u) => u.clave == umbral.clave);
    if (idx != -1) _memoria[idx] = umbral;
  }

  /// Aplica los umbrales al validador central para que los formularios usen los valores vigentes.
  static void aplicarAValidador(List<UmbralAlerta> umbrales) {
    for (final u in umbrales) {
      switch (u.clave) {
        case 'operacion.caudal_entrada':
          if (u.minimo != null) ValidadorRangos.caudalEntradaMin = u.minimo!;
          if (u.maximo != null) ValidadorRangos.caudalEntradaMax = u.maximo!;
        case 'operacion.nivel_tanque':
          if (u.minimo != null) ValidadorRangos.nivelTanqueMin = u.minimo!;
        case 'agua_cruda.ph':
          if (u.minimo != null) ValidadorRangos.phCrudaMin = u.minimo!;
          if (u.maximo != null) ValidadorRangos.phCrudaMax = u.maximo!;
        case 'agua_cruda.turbidez':
          if (u.maximo != null) ValidadorRangos.turbidezCrudaMax = u.maximo!;
        case 'agua_cruda.color':
          if (u.maximo != null) ValidadorRangos.colorCrudaMax = u.maximo!;
        case 'agua_clorada.ph':
          if (u.minimo != null) ValidadorRangos.phTratadaMin = u.minimo!;
          if (u.maximo != null) ValidadorRangos.phTratadaMax = u.maximo!;
        case 'agua_clorada.turbidez':
          if (u.maximo != null) ValidadorRangos.turbidezTratadaMax = u.maximo!;
        case 'agua_clorada.color_aparente':
          if (u.maximo != null) ValidadorRangos.colorTratadaMax = u.maximo!;
        case 'agua_clorada.cloro_residual':
          if (u.minimo != null) ValidadorRangos.cloroMin = u.minimo!;
          if (u.maximo != null) ValidadorRangos.cloroMax = u.maximo!;
      }
    }
  }
}
