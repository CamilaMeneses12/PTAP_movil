import '../models/item_historial_modelo.dart';
import 'caudal_repository.dart';
import 'fisicoquimico_repository.dart';
import 'medidores_repository.dart';

/// Repositorio que unifica los registros de todos los módulos para consultas y filtros
class HistorialRepository {
  final FisicoquimicoRepository _fisicoquimicoRepo;
  final MedidoresRepository _medidoresRepo;
  final CaudalRepository _caudalRepo;

  HistorialRepository({
    FisicoquimicoRepository? fisicoquimicoRepo,
    MedidoresRepository? medidoresRepo,
    CaudalRepository? caudalRepo,
  })  : _fisicoquimicoRepo = fisicoquimicoRepo ?? FisicoquimicoRepository(),
        _medidoresRepo = medidoresRepo ?? MedidoresRepository(),
        _caudalRepo = caudalRepo ?? CaudalRepository();

  /// Obtiene todos los registros combinados en orden cronológico descendente
  Future<List<ItemHistorial>> obtenerHistorialCompleto() async {
    final items = <ItemHistorial>[];

    // 1. Fisicoquímicos
    final fisicoquimicos = await _fisicoquimicoRepo.obtenerRegistros();
    for (final f in fisicoquimicos) {
      items.add(
        ItemHistorial(
          id: f.id,
          tipo: TipoRegistroHistorial.fisicoquimico,
          fecha: f.fecha,
          hora: f.hora,
          titulo: 'Calidad del Agua DO-F-070',
          subtitulo: 'pH: ${f.cloradaPh ?? "-"} | Turb: ${f.cloradaTurbidez ?? "-"} NTU | Cloro: ${f.cloradaCloroResidual ?? "-"} mg/L',
          responsable: f.responsableNombre.isNotEmpty ? f.responsableNombre : 'Operario',
          creadoPorId: f.createdBy,
          tieneAlerta: f.fueraDeRango,
          mensajeAlerta: f.fueraDeRango ? 'Parámetros fuera de norma Res. 2115' : null,
          objetoOriginal: f,
        ),
      );
    }

    // 2. Medidores
    final jornadas = await _medidoresRepo.obtenerJornadas();
    for (final j in jornadas) {
      final perdidaAlta = j.aguaNoRegistrada > 5.0;
      items.add(
        ItemHistorial(
          id: j.id,
          tipo: TipoRegistroHistorial.medidores,
          fecha: j.fecha,
          hora: j.hora,
          titulo: 'Lectura de Medidores',
          subtitulo: 'Macro: ${j.consumoMacromedidor.toStringAsFixed(2)} m³ | Pérdida: ${j.aguaNoRegistrada.toStringAsFixed(2)} m³',
          responsable: j.responsableLectura.isNotEmpty ? j.responsableLectura : 'Lector PTAP',
          creadoPorId: j.createdBy,
          tieneAlerta: perdidaAlta,
          mensajeAlerta: perdidaAlta ? 'Pérdida elevada (> 5 m³)' : null,
          objetoOriginal: j,
        ),
      );
    }

    // 3. Caudal La Seca
    final aforos = await _caudalRepo.obtenerAforos();
    for (final a in aforos) {
      items.add(
        ItemHistorial(
          id: a.id,
          tipo: TipoRegistroHistorial.caudal,
          fecha: a.fecha,
          hora: a.hora,
          titulo: 'Aforo Quebrada La Seca',
          subtitulo: 'Caudal: ${a.caudalLS.toStringAsFixed(2)} L/s (${a.caudalM3H.toStringAsFixed(1)} m³/h)',
          responsable: a.createdBy.isNotEmpty ? a.createdBy : 'Operario PTAP',
          creadoPorId: a.createdBy,
          tieneAlerta: a.caudalLS < 10.0,
          mensajeAlerta: a.caudalLS < 10.0 ? 'Caudal bajo en quebrada' : null,
          objetoOriginal: a,
        ),
      );
    }

    // Ordenar de más reciente a más antiguo
    items.sort((a, b) {
      final compFecha = b.fecha.compareTo(a.fecha);
      if (compFecha != 0) return compFecha;
      return b.hora.compareTo(a.hora);
    });

    return items;
  }

  /// Extrae la lista de responsables únicos existentes en los registros
  Future<List<String>> obtenerResponsablesUnicos() async {
    final todos = await obtenerHistorialCompleto();
    final conjunto = <String>{};
    for (final item in todos) {
      if (item.responsable.trim().isNotEmpty) {
        conjunto.add(item.responsable.trim());
      }
    }
    final lista = conjunto.toList()..sort();
    return lista;
  }
}
