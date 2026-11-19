import 'package:flutter/foundation.dart';
import '../../core/utils/mapa_supabase.dart';
import '../../core/utils/supabase_config.dart';
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

  /// Obtiene la última lectura conocida para cada medidor para auto-llenar el formulario
  Map<int, double> obtenerUltimasLecturas() {
    final mapa = <int, double>{};

    if (_jornadasMemoria.isNotEmpty) {
      final ultimaJornada = _jornadasMemoria.first;
      for (final l in ultimaJornada.lecturas) {
        mapa[l.medidorId] = l.lecturaActual;
      }
    }

    return mapa;
  }

  /// Consulta el histórico de jornadas de medidores
  Future<List<JornadaMedidores>> obtenerJornadas() async {
    if (!SupabaseConfig.estaInicializado) {
      return List.unmodifiable(_jornadasMemoria);
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
          return LecturaMedidor(
            id: l['id']?.toString(),
            jornadaId: l['jornada_id']?.toString(),
            medidorId: mId,
            medidorNombre: medidor.nombre,
            tipoMedidor: medidor.tipo,
            lecturaActual: (l['lectura_actual'] as num?)?.toDouble() ?? 0.0,
            lecturaAnterior: (l['lectura_anterior'] as num?)?.toDouble() ?? 0.0,
            consumo: (l['consumo'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        return JornadaMedidores.fromMap(mapa, lecturas: lecturas);
      }).toList();

      return lista;
    } catch (e) {
      debugPrint('Error al consultar jornadas en Supabase, usando memoria: $e');
      return List.unmodifiable(_jornadasMemoria);
    }
  }

  /// Guarda una nueva jornada de medidores junto con las lecturas de los 9 medidores
  Future<bool> guardarJornada(JornadaMedidores jornada) async {
    _jornadasMemoria.insert(0, jornada);

    if (!SupabaseConfig.estaInicializado) return true;

    try {
      final mapaJornada = paraInsertarEnSupabase(jornada.toMap());
      final res = await SupabaseConfig.cliente
          .from('jornadas_medidores')
          .insert(mapaJornada)
          .select()
          .single();

      final idInsertado = res['id']?.toString() ?? jornada.id;

      if (jornada.lecturas.isNotEmpty) {
        final listaLecturas = jornada.lecturas
            .map((l) => paraInsertarEnSupabase(l.toMap(fkJornadaId: idInsertado)))
            .toList();

        await SupabaseConfig.cliente
            .from('lecturas_medidores')
            .insert(listaLecturas);
      }

      return true;
    } catch (e) {
      debugPrint('Error guardando jornada en Supabase: $e');
      return true; // Preservada en memoria
    }
  }
}
