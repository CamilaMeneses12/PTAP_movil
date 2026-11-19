import '../../data/models/item_historial_modelo.dart';
import '../../data/models/registro_fisicoquimico.dart';
import '../../data/models/usuario_perfil.dart';
import '../validators/validador_rangos.dart';

/// Conteo de cumplimiento normativo de un parámetro o tipo de registro.
class CumplimientoParametro {
  final String nombre;
  final int total;
  final int incumplimientos;

  const CumplimientoParametro({
    required this.nombre,
    required this.total,
    required this.incumplimientos,
  });

  /// Porcentaje dentro de norma; null si no hay datos.
  double? get porcentaje => total == 0 ? null : (total - incumplimientos) / total * 100;
}

/// Cálculos de los perfiles por rol a partir del historial unificado.
class EstadisticasPerfil {
  static DateTime _dia(DateTime f) => DateTime(f.year, f.month, f.day);

  /// El registro pertenece al usuario si lo creó (created_by) o figura como responsable.
  static bool esDelUsuario(ItemHistorial item, UsuarioPerfil perfil) {
    final creador = item.creadoPorId;
    if (creador != null && creador.isNotEmpty && creador == perfil.id) return true;
    final nombre = perfil.nombreCompleto.trim().toLowerCase();
    return nombre.isNotEmpty && item.responsable.trim().toLowerCase() == nombre;
  }

  static List<ItemHistorial> delUsuario(List<ItemHistorial> items, UsuarioPerfil perfil) =>
      items.where((i) => esDelUsuario(i, perfil)).toList();

  static List<ItemHistorial> delMes(List<ItemHistorial> items, DateTime ahora) =>
      items.where((i) => i.fecha.year == ahora.year && i.fecha.month == ahora.month).toList();

  static List<ItemHistorial> ultimosDias(List<ItemHistorial> items, DateTime ahora, int dias) {
    final desde = _dia(ahora).subtract(Duration(days: dias - 1));
    return items.where((i) => !_dia(i.fecha).isBefore(desde)).toList();
  }

  static int conAviso(List<ItemHistorial> items) => items.where((i) => i.tieneAlerta).length;

  /// Días consecutivos con al menos un registro. La racha sigue viva si hoy aún no se ha registrado.
  static int diasSeguidos(List<ItemHistorial> items, DateTime ahora) {
    final dias = items.map((i) => _dia(i.fecha)).toSet();
    var cursor = _dia(ahora);
    if (!dias.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
    var racha = 0;
    while (dias.contains(cursor)) {
      racha++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return racha;
  }

  /// Para cada tarea diaria, indica si ya existe un registro de hoy.
  static Map<TipoRegistroHistorial, bool> tareasDeHoy(List<ItemHistorial> items, DateTime ahora) {
    final hoy = _dia(ahora);
    bool hecho(TipoRegistroHistorial t) => items.any((i) => i.tipo == t && _dia(i.fecha) == hoy);
    return {
      TipoRegistroHistorial.fisicoquimico: hecho(TipoRegistroHistorial.fisicoquimico),
      TipoRegistroHistorial.medidores: hecho(TipoRegistroHistorial.medidores),
      TipoRegistroHistorial.caudal: hecho(TipoRegistroHistorial.caudal),
    };
  }

  /// Porcentaje de registros sin aviso; null si no hay registros.
  static double? porcentajeCumplimiento(List<ItemHistorial> items) {
    if (items.isEmpty) return null;
    return (items.length - conAviso(items)) / items.length * 100;
  }

  /// Cumplimiento por parámetro fisicoquímico (agua tratada y cruda), más medidores y caudal.
  static List<CumplimientoParametro> cumplimientoPorParametro(List<ItemHistorial> items) {
    final registros = items
        .where((i) => i.tipo == TipoRegistroHistorial.fisicoquimico)
        .map((i) => i.objetoOriginal)
        .whereType<RegistroFisicoquimico>()
        .toList();

    CumplimientoParametro contar(
      String nombre,
      double? Function(RegistroFisicoquimico) valor,
      EvaluacionRango Function(double) validar,
    ) {
      var total = 0;
      var fuera = 0;
      for (final r in registros) {
        final v = valor(r);
        if (v == null) continue;
        total++;
        if (!validar(v).cumple) fuera++;
      }
      return CumplimientoParametro(nombre: nombre, total: total, incumplimientos: fuera);
    }

    CumplimientoParametro porTipo(String nombre, TipoRegistroHistorial tipo) {
      final deTipo = items.where((i) => i.tipo == tipo).toList();
      return CumplimientoParametro(nombre: nombre, total: deTipo.length, incumplimientos: conAviso(deTipo));
    }

    return [
      contar('pH agua tratada', (r) => r.cloradaPh, ValidadorRangos.validarPhTratada),
      contar('Turbidez agua tratada', (r) => r.cloradaTurbidez, ValidadorRangos.validarTurbidezTratada),
      contar('Color aparente', (r) => r.cloradaColorAparente, ValidadorRangos.validarColorAparente),
      contar('Cloro residual', (r) => r.cloradaCloroResidual, ValidadorRangos.validarCloroResidual),
      contar('pH agua cruda', (r) => r.crudaPh, ValidadorRangos.validarPhCruda),
      contar('Turbidez agua cruda', (r) => r.crudaTurbidez, ValidadorRangos.validarTurbidezCruda),
      porTipo('Pérdidas en medidores', TipoRegistroHistorial.medidores),
      porTipo('Caudal quebrada La Seca', TipoRegistroHistorial.caudal),
    ];
  }
}
