import 'package:flutter/foundation.dart';
import '../../core/utils/supabase_config.dart';
import '../models/registro_fisicoquimico.dart';

/// Repositorio para la gestión del formato DO-F-070 en Supabase
class FisicoquimicoRepository {
  // Lista en memoria para modo demo / sin conexión
  final List<RegistroFisicoquimico> _registrosMemoria = [];

  FisicoquimicoRepository() {
    _cargarDatosSemillaMemoria();
  }

  void _cargarDatosSemillaMemoria() {
    // Registro de ejemplo basado fielmente en la fila 11 del formato Excel DO-F-070
    final registroEjemplo = RegistroFisicoquimico(
      id: 'semilla-01',
      fecha: DateTime(2025, 2, 21),
      hora: '01:20',
      regional: 'Distrito Capital',
      centroFormacion: 'Centro de Tecnologías Agroindustriales',
      sede: 'Sede Principal',
      crudaCaudalEntrada: 0.7,
      crudaPh: 8.0,
      crudaTurbidez: 4.68,
      crudaColor: 15.0,
      crudaDosisCoagulante: '0.2',
      filtradaTurbidez: 0.92,
      filtradaPh: 7.6,
      cloradaTurbidez: 1.61,
      cloradaPh: 7.9,
      cloradaColorAparente: 15.0,
      cloradaCloroResidual: 2.5, // Fuera de rango (> 2.0 mg/L)
      fueraDeRango: true,
      observaciones: 'Cloro residual ligeramente alto en salida de cloración.',
      responsableNombre: 'Diego Calderón',
      createdBy: 'operario-1',
      createdAt: DateTime(2025, 2, 21, 1, 20),
      puntosControl: const [
        MedicionPuntoControl(
          areaNombre: 'Biocabaña',
          turbidez: 0.0,
          ph: 7.7,
          colorAparente: 10.0,
          cloroResidual: 1.98,
        ),
        MedicionPuntoControl(
          areaNombre: 'Agroindustria',
          turbidez: 0.92,
          ph: 8.0,
          colorAparente: 10.0,
          cloroResidual: 1.95,
        ),
        MedicionPuntoControl(
          areaNombre: 'Gastronomia',
          turbidez: 0.24,
          ph: 7.9,
          colorAparente: 10.0,
          cloroResidual: 1.5,
        ),
        MedicionPuntoControl(
          areaNombre: 'ENCC',
          turbidez: 0.0,
          ph: 8.0,
          colorAparente: 0.0,
          cloroResidual: 1.29,
        ),
      ],
    );
    _registrosMemoria.add(registroEjemplo);
  }

  /// Puntos de muestreo por defecto según el formato Excel
  List<String> obtenerPuntosMuestreoDefecto() {
    return const [
      'Biocabaña',
      'Agroindustria',
      'Gastronomia',
      'ENCC',
      'Dispensador Bienestar',
    ];
  }

  /// Obtiene todos los registros ordenados por fecha descendente
  Future<List<RegistroFisicoquimico>> obtenerRegistros() async {
    if (!SupabaseConfig.estaInicializado) {
      return List.unmodifiable(_registrosMemoria);
    }

    try {
      final res = await SupabaseConfig.cliente
          .from('registros_fisicoquimicos')
          .select('*, puntos_control_mediciones(*)')
          .order('fecha', ascending: false)
          .order('hora', ascending: false);

      final lista = (res as List).map((mapa) {
        final puntosJson = mapa['puntos_control_mediciones'] as List? ?? [];
        final puntos = puntosJson
            .map((p) => MedicionPuntoControl.fromMap(p as Map<String, dynamic>))
            .toList();
        return RegistroFisicoquimico.fromMap(mapa, puntos: puntos);
      }).toList();

      return lista;
    } catch (e) {
      debugPrint('Error al obtener registros de Supabase, usando memoria: $e');
      return List.unmodifiable(_registrosMemoria);
    }
  }

  /// Guarda un nuevo registro junto con sus puntos de control
  Future<bool> guardarRegistro(RegistroFisicoquimico registro) async {
    if (!SupabaseConfig.estaInicializado) {
      _registrosMemoria.insert(0, registro);
      return true;
    }

    try {
      final mapaRegistro = registro.toMap();
      final res = await SupabaseConfig.cliente
          .from('registros_fisicoquimicos')
          .insert(mapaRegistro)
          .select()
          .single();

      final idInsertado = res['id']?.toString() ?? registro.id;

      if (registro.puntosControl.isNotEmpty) {
        final listaPuntos = registro.puntosControl
            .map((p) => p.toMap(fkRegistroId: idInsertado))
            .toList();

        await SupabaseConfig.cliente
            .from('puntos_control_mediciones')
            .insert(listaPuntos);
      }

      _registrosMemoria.insert(0, registro);
      return true;
    } catch (e) {
      debugPrint('Error al guardar registro en Supabase: $e');
      // Guardar en memoria para no perder datos en campo
      _registrosMemoria.insert(0, registro);
      return true;
    }
  }

  /// Elimina un registro por ID
  Future<bool> eliminarRegistro(String id) async {
    _registrosMemoria.removeWhere((r) => r.id == id);

    if (!SupabaseConfig.estaInicializado) return true;

    try {
      await SupabaseConfig.cliente
          .from('registros_fisicoquimicos')
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error al eliminar registro: $e');
      return false;
    }
  }
}
