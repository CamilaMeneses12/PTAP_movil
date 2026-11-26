import 'package:flutter/foundation.dart';
import '../../core/utils/mapa_supabase.dart';
import '../../core/utils/supabase_config.dart';
import '../local/cache_sincronizable.dart';
import '../local/serializacion_local.dart';
import '../models/aforo_caudal_modelo.dart';

/// Repositorio para la gestión de aforos de caudal de la quebrada La Seca
class CaudalRepository {
  final List<AforoCaudal> _aforosMemoria = [];

  CaudalRepository() {
    _cargarSerieHistoricaExcel();
  }

  void _cargarSerieHistoricaExcel() {
    // Serie histórica mensual extraída exactamente de las filas 34 a 59 del Excel:
    // "Tabla de Calculo Caudal Quebrada la seca - V4 (1).xlsx"
    final datosExcel = <Map<String, dynamic>>[
      {'fecha': DateTime(2025, 2, 1), 'caudal': 24.0},
      {'fecha': DateTime(2025, 3, 1), 'caudal': 29.2},
      {'fecha': DateTime(2025, 4, 1), 'caudal': 30.0},
      {'fecha': DateTime(2025, 5, 1), 'caudal': 23.0},
      {'fecha': DateTime(2025, 6, 1), 'caudal': 28.0},
      {'fecha': DateTime(2025, 7, 1), 'caudal': 32.0},
      {'fecha': DateTime(2025, 8, 1), 'caudal': 21.0},
      {'fecha': DateTime(2025, 9, 1), 'caudal': 22.0},
      {'fecha': DateTime(2025, 10, 1), 'caudal': 21.0},
      {'fecha': DateTime(2025, 11, 1), 'caudal': 21.0},
      {'fecha': DateTime(2025, 12, 1), 'caudal': 22.0},
      {'fecha': DateTime(2026, 2, 1), 'caudal': 26.0},
      {'fecha': DateTime(2026, 3, 1), 'caudal': 21.0},
      {'fecha': DateTime(2026, 4, 1), 'caudal': 27.2},
      {'fecha': DateTime(2026, 5, 6), 'caudal': 19.2},
      {'fecha': DateTime(2026, 5, 29), 'caudal': 16.0},
      {'fecha': DateTime(2026, 6, 1), 'caudal': 14.0},
      {'fecha': DateTime(2026, 6, 30), 'caudal': 11.0},
      {'fecha': DateTime(2026, 7, 1), 'caudal': 17.0},
      {'fecha': DateTime(2026, 7, 31), 'caudal': 11.0},
      {'fecha': DateTime(2026, 8, 1), 'caudal': 14.0},
      {'fecha': DateTime(2026, 8, 28), 'caudal': 18.0},
      {'fecha': DateTime(2026, 9, 1), 'caudal': 8.6},
      {'fecha': DateTime(2026, 9, 25), 'caudal': 10.0},
      {'fecha': DateTime(2026, 10, 1), 'caudal': 8.4},
      {
        'fecha': DateTime(2026, 10, 23),
        'caudal': 8.874,
        'ancho': 0.41,
        'p1': 0.09, 'p2': 0.06, 'p3': 0.05, 'p4': 0.06,
        'dist': 3.0,
        't1': 7.55, 't2': 5.66, 't3': 8.59, 't4': 7.03,
        'observacion': 'Aforo detallado quebrada abastecedora La Seca.'
      },
    ];

    for (int i = 0; i < datosExcel.length; i++) {
      final item = datosExcel[i];
      final fecha = item['fecha'] as DateTime;
      final caudalLS = (item['caudal'] as num).toDouble();
      final caudalM3S = caudalLS / 1000.0;
      final caudalM3H = caudalM3S * 3600.0;
      final caudalLH = caudalLS * 3600.0;

      final ancho = (item['ancho'] as num?)?.toDouble() ?? 0.41;
      final p1 = (item['p1'] as num?)?.toDouble() ?? 0.09;
      final p2 = (item['p2'] as num?)?.toDouble() ?? 0.06;
      final p3 = (item['p3'] as num?)?.toDouble() ?? 0.05;
      final p4 = (item['p4'] as num?)?.toDouble() ?? 0.06;
      final dist = (item['dist'] as num?)?.toDouble() ?? 3.0;
      final t1 = (item['t1'] as num?)?.toDouble() ?? 7.55;
      final t2 = (item['t2'] as num?)?.toDouble() ?? 5.66;
      final t3 = (item['t3'] as num?)?.toDouble() ?? 8.59;
      final t4 = (item['t4'] as num?)?.toDouble() ?? 7.03;

      _aforosMemoria.add(
        AforoCaudal(
          id: 'aforo-excel-$i',
          fecha: fecha,
          hora: '10:00',
          anchoCauceM: ancho,
          profundidad1M: p1,
          profundidad2M: p2,
          profundidad3M: p3,
          profundidad4M: p4,
          distanciaFlotadorM: dist,
          tiempo1S: t1,
          tiempo2S: t2,
          tiempo3S: t3,
          tiempo4S: t4,
          factorCorreccion: 0.80,
          profundidadPromedioM: (p1 + p2 + p3 + p4) / 4.0,
          areaSeccionM2: ancho * ((p1 + p2 + p3 + p4) / 4.0),
          tiempoPromedioS: (t1 + t2 + t3 + t4) / 4.0,
          velocidadSuperficialMS: dist / ((t1 + t2 + t3 + t4) / 4.0),
          velocidadCorregidaMS: (dist / ((t1 + t2 + t3 + t4) / 4.0)) * 0.80,
          caudalM3S: caudalM3S,
          caudalM3H: caudalM3H,
          caudalLS: caudalLS,
          caudalLH: caudalLH,
          observaciones: item['observacion'] as String?,
          createdBy: 'operario-1',
          createdAt: fecha,
        ),
      );
    }
  }

  CacheSincronizable<AforoCaudal> get _cache => CacheSincronizable.de<AforoCaudal>(
        'aforos_caudal',
        aMapa: SerializacionLocal.aforoAMapa,
        deMapa: SerializacionLocal.aforoDeMapa,
        idDe: (a) => a.id,
      );

  /// true si el último aforo guardado quedó en el celular esperando conexión.
  bool ultimoGuardadoPendiente = false;

  static List<AforoCaudal> _cronologico(Iterable<AforoCaudal> lista) => lista.toList()
    ..sort((a, b) {
      final f = a.fecha.compareTo(b.fecha);
      return f != 0 ? f : a.hora.compareTo(b.hora);
    });

  /// Obtiene los aforos ordenados cronológicamente.
  /// Sin conexión devuelve la última copia guardada en el celular más lo pendiente de subir.
  Future<List<AforoCaudal>> obtenerAforos() async {
    if (!SupabaseConfig.estaInicializado) {
      return _cronologico([..._aforosMemoria, ...await _cache.todos()]);
    }

    try {
      final res = await SupabaseConfig.cliente
          .from('aforos_caudal')
          .select()
          .order('fecha', ascending: true);

      final lista = (res as List)
          .map((m) => AforoCaudal.fromMap(m as Map<String, dynamic>))
          .toList();
      await _cache.reemplazarSincronizados(lista);
    } catch (e) {
      debugPrint('Sin conexión con Supabase, se muestran los aforos guardados en el celular: $e');
    }
    final locales = await _cache.todos();
    // Base de datos aún vacía: se muestra la serie histórica del Excel.
    if (locales.isEmpty) return List.unmodifiable(_aforosMemoria);
    return _cronologico(locales);
  }

  /// Guarda primero en el celular y luego intenta subirlo. Sin conexión queda pendiente.
  Future<bool> guardarAforo(AforoCaudal aforo) async {
    await _cache.agregarPendiente(aforo);
    ultimoGuardadoPendiente = true;
    if (!SupabaseConfig.estaInicializado) return true;

    try {
      await _subir(aforo);
      await _cache.marcarSincronizado(aforo.id);
      ultimoGuardadoPendiente = false;
    } catch (e) {
      debugPrint('Aforo guardado en el celular; se subirá cuando haya conexión: $e');
    }
    return true;
  }

  Future<void> _subir(AforoCaudal aforo) async {
    final mapa = paraInsertarEnSupabase(aforo.toMap());
    final tabla = SupabaseConfig.cliente.from('aforos_caudal');
    if (mapa.containsKey('id')) {
      await tabla.upsert(mapa, onConflict: 'id', ignoreDuplicates: true);
    } else {
      await tabla.insert(mapa);
    }
  }

  Future<int> contarPendientes() async =>
      SupabaseConfig.estaInicializado ? await _cache.contarPendientes() : 0;

  /// Sube lo que quedó guardado sin conexión. Devuelve el error del primer aforo que falle.
  Future<String?> subirPendientes() async {
    if (!SupabaseConfig.estaInicializado) return null;
    String? error;
    for (final a in await _cache.pendientes()) {
      try {
        await _subir(a);
        await _cache.marcarSincronizado(a.id);
      } catch (e) {
        error ??= '$e';
      }
    }
    return error;
  }
}
