import 'dart:io';

import 'package:flutter/foundation.dart';
import '../../core/utils/mapa_supabase.dart';
import '../../core/utils/identificador.dart';
import '../../core/utils/supabase_config.dart';
import '../local/cache_sincronizable.dart';
import '../local/serializacion_local.dart';
import '../services/foto_lectura_service.dart';
import '../models/medidores_modelos.dart';

/// Repositorio para la gestión de lecturas de medidores y balance hídrico
class MedidoresRepository {
  // Catálogo oficial de medidores del formato Excel "Registro de medidores de Agua"
  static final List<Medidor> medidoresOficiales = [
    const Medidor(id: 1, codigo: 'MIC-01', nombre: 'ENCC', tipo: 'micromedidor', orden: 1),
    const Medidor(id: 2, codigo: 'MIC-02', nombre: 'SENNOVA', tipo: 'micromedidor', orden: 2),
    const Medidor(id: 3, codigo: 'MIC-03', nombre: 'LABORATORIOS', tipo: 'micromedidor', orden: 3),
    const Medidor(id: 4, codigo: 'MIC-04', nombre: 'BIOCABAÑA', tipo: 'micromedidor', orden: 4),
    const Medidor(id: 5, codigo: 'MIC-05', nombre: 'CAFETERIA', tipo: 'micromedidor', orden: 5),
    const Medidor(id: 6, codigo: 'MIC-06', nombre: 'PECUARIA', tipo: 'micromedidor', orden: 6),
    const Medidor(id: 7, codigo: 'MIC-07', nombre: 'AGROINDUSTRIA', tipo: 'micromedidor', orden: 7),
    const Medidor(id: 8, codigo: 'MIC-08', nombre: 'GASTRONOMIA', tipo: 'micromedidor', orden: 8),
    const Medidor(id: 9, codigo: 'MAC-01', nombre: 'MACRO MEDIDOR', tipo: 'macromedidor', orden: 9),
  ];

  final List<JornadaMedidores> _jornadasMemoria = [];

  MedidoresRepository() {
    _cargarDatosSemillaExcel();
  }

  void _cargarDatosSemillaExcel() {
    // Fila 19 del Excel (17 de Febrero de 2025)
    // Lecturas base y consumos calculados
    final jornada17Feb = JornadaMedidores(
      id: 'jornada-excel-17feb',
      fecha: DateTime(2025, 2, 17),
      hora: '09:40',
      responsableLectura: 'Operario PTAP',
      observaciones: 'Lectura inicial del ciclo de operación.',
      consumoTotalMicros: 10.5369,
      consumoMacromedidor: 16.3900,
      aguaNoRegistrada: 5.8531,
      createdBy: 'operario-1',
      createdAt: DateTime(2025, 2, 17, 9, 40),
      lecturas: const [
        LecturaMedidor(
          medidorId: 1,
          medidorNombre: 'ENCC',
          tipoMedidor: 'micromedidor',
          lecturaActual: 829.1496,
          lecturaAnterior: 828.7891,
          consumo: 0.3605,
        ),
        LecturaMedidor(
          medidorId: 2,
          medidorNombre: 'SENNOVA',
          tipoMedidor: 'micromedidor',
          lecturaActual: 2810.2901,
          lecturaAnterior: 2807.6805,
          consumo: 2.6096,
        ),
        LecturaMedidor(
          medidorId: 3,
          medidorNombre: 'LABORATORIOS',
          tipoMedidor: 'micromedidor',
          lecturaActual: 346.2334,
          lecturaAnterior: 346.0151,
          consumo: 0.2183,
        ),
        LecturaMedidor(
          medidorId: 4,
          medidorNombre: 'BIOCABAÑA',
          tipoMedidor: 'micromedidor',
          lecturaActual: 757.0477,
          lecturaAnterior: 756.2597,
          consumo: 0.7880,
        ),
        LecturaMedidor(
          medidorId: 5,
          medidorNombre: 'CAFETERIA',
          tipoMedidor: 'micromedidor',
          lecturaActual: 39.5338,
          lecturaAnterior: 39.5338,
          consumo: 0.0000,
        ),
        LecturaMedidor(
          medidorId: 6,
          medidorNombre: 'PECUARIA',
          tipoMedidor: 'micromedidor',
          lecturaActual: 605.2280,
          lecturaAnterior: 602.0040,
          consumo: 3.2240,
        ),
        LecturaMedidor(
          medidorId: 7,
          medidorNombre: 'AGROINDUSTRIA',
          tipoMedidor: 'micromedidor',
          lecturaActual: 92.4428,
          lecturaAnterior: 91.8120,
          consumo: 0.6308,
        ),
        LecturaMedidor(
          medidorId: 8,
          medidorNombre: 'GASTRONOMIA',
          tipoMedidor: 'micromedidor',
          lecturaActual: 2479.5432,
          lecturaAnterior: 2476.8375,
          consumo: 2.7057,
        ),
        LecturaMedidor(
          medidorId: 9,
          medidorNombre: 'MACRO MEDIDOR',
          tipoMedidor: 'macromedidor',
          lecturaActual: 4571.1700,
          lecturaAnterior: 4554.7800,
          consumo: 16.3900,
        ),
      ],
    );

    _jornadasMemoria.add(jornada17Feb);
  }

  /// Retorna la lista oficial de medidores
  List<Medidor> obtenerMedidores() => medidoresOficiales;

  CacheSincronizable<JornadaMedidores> get _cache => CacheSincronizable.de<JornadaMedidores>(
        'jornadas_medidores',
        aMapa: SerializacionLocal.jornadaAMapa,
        deMapa: SerializacionLocal.jornadaDeMapa,
        idDe: (j) => j.id,
      );

  /// true si la última jornada guardada quedó en el celular esperando conexión.
  bool ultimoGuardadoPendiente = false;

  /// Última lista conocida (la más reciente primero), para auto-llenar las lecturas anteriores.
  List<JornadaMedidores> _conocidas = const [];

  static List<JornadaMedidores> _ordenadas(Iterable<JornadaMedidores> lista) => lista.toList()
    ..sort((a, b) {
      final f = b.fecha.compareTo(a.fecha);
      return f != 0 ? f : b.hora.compareTo(a.hora);
    });

  /// Obtiene la última lectura conocida para cada medidor para auto-llenar el formulario
  Map<int, double> obtenerUltimasLecturas() {
    final mapa = <int, double>{};
    final base = _conocidas.isNotEmpty ? _conocidas : _jornadasMemoria;
    if (base.isNotEmpty) {
      for (final l in base.first.lecturas) {
        mapa[l.medidorId] = l.lecturaActual;
      }
    }
    return mapa;
  }

  /// Consulta el histórico de jornadas de medidores.
  /// Sin conexión devuelve la última copia guardada en el celular más lo pendiente de subir.
  Future<List<JornadaMedidores>> obtenerJornadas() async {
    if (!SupabaseConfig.estaInicializado) {
      return _conocidas = _ordenadas([...await _cache.todos(), ..._jornadasMemoria]);
    }

    try {
      final res = await SupabaseConfig.cliente
          .from('jornadas_medidores')
          .select('*, lecturas_medidores(*)')
          .order('fecha', ascending: false)
          .order('hora', ascending: false);

      final lista = (res as List).map((mapa) {
        final lecturasJson = mapa['lecturas_medidores'] as List? ?? [];
        final lecturas = lecturasJson.map((l) {
          final mId = int.tryParse(l['medidor_id']?.toString() ?? '0') ?? 0;
          final medidor = medidoresOficiales.firstWhere(
            (m) => m.id == mId,
            orElse: () => Medidor(id: mId, codigo: 'MED', nombre: 'Medidor $mId', tipo: 'micromedidor', orden: 0),
          );
          return LecturaMedidor.fromMap({
            ...Map<String, dynamic>.from(l as Map),
            'medidor_nombre': medidor.nombre,
            'tipo_medidor': medidor.tipo,
          });
        }).toList();

        return JornadaMedidores.fromMap(mapa, lecturas: lecturas);
      }).toList();

      await _cache.reemplazarSincronizados(lista);
    } catch (e) {
      debugPrint('Sin conexión con Supabase, se muestran las jornadas guardadas en el celular: $e');
    }
    return _conocidas = _ordenadas(await _cache.todos());
  }

  /// Guarda primero en el celular y luego intenta subir la jornada con sus lecturas y fotos.
  /// Sin conexión queda pendiente y se sube después (ver [subirPendientes]).
  Future<bool> guardarJornada(JornadaMedidores jornada) async {
    // Cada lectura lleva su propio id para que un reintento no la duplique.
    final mapa = SerializacionLocal.jornadaAMapa(jornada);
    for (final l in (mapa['lecturas'] as List).cast<Map<String, dynamic>>()) {
      l['id'] ??= generarUuid();
    }
    final j = SerializacionLocal.jornadaDeMapa(mapa);

    await _cache.agregarPendiente(j);
    _conocidas = _ordenadas([j, ..._conocidas.where((x) => x.id != j.id)]);
    ultimoGuardadoPendiente = true;
    if (!SupabaseConfig.estaInicializado) return true;

    try {
      await _cache.marcarSincronizado(j.id, actualizado: await _subir(j));
      ultimoGuardadoPendiente = false;
    } catch (e) {
      debugPrint('Jornada guardada en el celular; se subirá cuando haya conexión: $e');
    }
    return true;
  }

  /// Sube primero las fotos guardadas en el celular y después la jornada y sus lecturas.
  /// Devuelve la jornada con las rutas de las fotos ya subidas.
  Future<JornadaMedidores> _subir(JornadaMedidores j) async {
    final fotos = FotoLecturaService();
    final lecturas = <LecturaMedidor>[];
    for (final l in j.lecturas) {
      final local = FotoLecturaService.rutaLocalDe(l.fotoUrl);
      if (local == null) {
        lecturas.add(l);
        continue;
      }
      if (!await File(local).exists()) {
        // La foto se borró del celular: la lectura se sube sin ella.
        lecturas.add(l.copyWith(fotoUrl: ''));
        continue;
      }
      final codigo = medidoresOficiales
          .firstWhere((m) => m.id == l.medidorId,
              orElse: () => Medidor(id: l.medidorId, codigo: 'MED-${l.medidorId}', nombre: '', tipo: '', orden: 0))
          .codigo;
      final remota = await fotos.subir(
        local,
        FotoLecturaService.rutaRemota(fecha: j.fecha, jornadaId: j.id, codigoMedidor: codigo),
      );
      if (remota == null) throw Exception('No se pudo subir la foto de ${l.medidorNombre}');
      lecturas.add(l.copyWith(fotoUrl: remota));
    }
    final subida = JornadaMedidores.fromMap(SerializacionLocal.jornadaAMapa(j), lecturas: lecturas);

    final cliente = SupabaseConfig.cliente;
    final mapa = paraInsertarEnSupabase(subida.toMap());
    String idRemoto;
    if (mapa.containsKey('id')) {
      await cliente.from('jornadas_medidores').upsert(mapa, onConflict: 'id', ignoreDuplicates: true);
      idRemoto = subida.id;
    } else {
      final res = await cliente.from('jornadas_medidores').insert(mapa).select().single();
      idRemoto = res['id']?.toString() ?? subida.id;
    }
    if (lecturas.isNotEmpty) {
      await cliente.from('lecturas_medidores').upsert(
            [
              for (final l in lecturas)
                paraInsertarEnSupabase(l.toMap(fkJornadaId: idRemoto))
                  ..update('foto_url', (v) => (v == '') ? null : v),
            ],
            onConflict: 'id',
            ignoreDuplicates: true,
          );
    }
    return subida;
  }

  Future<int> contarPendientes() async =>
      SupabaseConfig.estaInicializado ? await _cache.contarPendientes() : 0;

  /// Sube lo que quedó guardado sin conexión. Devuelve el error de la primera jornada que falle.
  Future<String?> subirPendientes() async {
    if (!SupabaseConfig.estaInicializado) return null;
    String? error;
    for (final j in await _cache.pendientes()) {
      try {
        await _cache.marcarSincronizado(j.id, actualizado: await _subir(j));
      } catch (e) {
        error ??= '$e';
      }
    }
    return error;
  }
}
