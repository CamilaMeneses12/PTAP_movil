import '../../data/models/aforo_caudal_modelo.dart';
import '../../data/models/alerta_sistema_modelo.dart';
import '../../data/models/medidores_modelos.dart';
import '../../data/models/registro_fisicoquimico.dart';
import '../calculations/resumen_inicio.dart';
import '../validators/validador_rangos.dart';

/// Un valor histórico de un parámetro, tomado de los registros del operario.
class ValorHistorico {
  final DateTime momento;
  final double valor;
  final bool fueraDeRango;
  const ValorHistorico(this.momento, this.valor, this.fueraDeRango);
}

/// Referencia normativa (o de control interno) del límite de un parámetro.
class ReferenciaLimite {
  final String titulo;
  final String detalle;

  /// Identificador de la norma en la pantalla de Normatividad; null si es un límite interno.
  final String? normaId;

  const ReferenciaLimite({required this.titulo, required this.detalle, this.normaId});
}

/// Definición de un parámetro que puede generar alertas: cómo se valida, de dónde se lee su
/// historial, qué revisar y qué norma fija el límite.
class ParametroAlerta {
  final String clave;
  final String nombre;
  final String unidad;
  final TipoFormatoAlerta formato;

  /// Valida un valor. [referencia] es la lectura anterior en los medidores.
  final EvaluacionRango Function(double valor, {double? referencia}) evaluar;

  final double? Function(RegistroFisicoquimico r, String? punto)? deFisico;
  final double? Function(JornadaMedidores j, String? punto)? deJornada;
  final double? Function(AforoCaudal a)? deAforo;

  /// Acciones sugeridas cuando el valor queda por debajo o por encima del rango.
  final List<String> accionesBajo;
  final List<String> accionesAlto;
  final ReferenciaLimite referencia;

  const ParametroAlerta({
    required this.clave,
    required this.nombre,
    required this.unidad,
    required this.formato,
    required this.evaluar,
    required this.accionesBajo,
    required this.accionesAlto,
    required this.referencia,
    this.deFisico,
    this.deJornada,
    this.deAforo,
  });

  List<String> acciones(EvaluacionRango e) => e.tipo == 'por_debajo' ? accionesBajo : accionesAlto;
}

class CatalogoParametrosAlerta {
  /// Rango operativo del caudal de la fuente que ya usa el formulario de aforo.
  static const double caudalFuenteMinLS = 10.0;
  static const double caudalFuenteMaxLS = 140.0;

  /// Límite que ya usa la app para marcar pérdida elevada en Medidores e Historial.
  static const double perdidaElevadaM3 = ResumenInicio.perdidaElevadaM3;

  // TODO: verificar con la norma el artículo exacto de la Res. 2115 de 2007 que fija cada límite.
  static const _res2115 = ReferenciaLimite(
    titulo: 'Resolución 2115 de 2007',
    detalle: 'Características físicas y químicas del agua para consumo humano y frecuencias de control.',
    normaId: 'res_2115_2007',
  );

  // TODO: verificar con la norma la referencia del rango de control del agua cruda.
  static const _controlCruda = ReferenciaLimite(
    titulo: 'Rango de control del agua cruda (formato DO-F-070)',
    detalle: 'Límite de control de la planta para el agua que llega de la captación, antes del tratamiento.',
  );

  static const _limiteOperativo = ReferenciaLimite(
    titulo: 'Límite operativo de la PTAP',
    detalle: 'No es un valor normativo: lo define la planta para su control interno.',
  );

  static const _repetir = 'Repetir la medición y registrar el nuevo valor.';
  static const _turbidezAlta = [
    'Revisar el estado de los filtros y programar retrolavado si corresponde.',
    'Revisar la dosis de coagulante (prueba de jarras).',
    _repetir,
  ];
  static const _phBajo = [
    'Revisar la dosificación de coagulante y de alcalinizante.',
    'Verificar la calibración del pHmetro.',
    _repetir,
  ];
  static const _phAlto = [
    'Revisar la dosificación de alcalinizante.',
    'Verificar la calibración del pHmetro.',
    _repetir,
  ];
  static const _cruda = [
    'Ajustar la dosis de coagulante (prueba de jarras).',
    'Inspeccionar la captación: lluvias, crecientes o arrastre de sedimentos.',
    'Aumentar la frecuencia de control del agua tratada.',
  ];
  static const _cloroBajo = [
    'Revisar la dosificación de cloro: equipo dosificador y concentración de la solución.',
    'Repetir la medición en 30 min.',
    'Si sigue bajo, informar al responsable de la planta.',
  ];
  static const _cloroAlto = [
    'Reducir la dosificación de cloro.',
    'Repetir la medición en 30 min.',
  ];
  static const _red = 'Revisar el punto de muestreo y la red cercana.';

  static MedicionPuntoControl? _punto(RegistroFisicoquimico r, String? nombre) {
    for (final p in r.puntosControl) {
      if (p.areaNombre == nombre) return p;
    }
    return null;
  }

  static LecturaMedidor? _lectura(JornadaMedidores j, String? medidor) {
    for (final l in j.lecturas) {
      if (l.medidorNombre == medidor) return l;
    }
    return null;
  }

  static final Map<String, ParametroAlerta> _parametros = {
    for (final p in <ParametroAlerta>[
      // --- DO-F-070: agua cruda ---
      ParametroAlerta(
        clave: 'ph_cruda',
        nombre: 'pH agua cruda',
        unidad: 'pH',
        formato: TipoFormatoAlerta.fisicoquimico,
        evaluar: (v, {referencia}) => ValidadorRangos.validarPhCruda(v),
        deFisico: (r, _) => r.crudaPh,
        accionesBajo: _cruda,
        accionesAlto: _cruda,
        referencia: _controlCruda,
      ),
      ParametroAlerta(
        clave: 'turbidez_cruda',
        nombre: 'Turbidez agua cruda',
        unidad: 'UJT',
        formato: TipoFormatoAlerta.fisicoquimico,
        evaluar: (v, {referencia}) => ValidadorRangos.validarTurbidezCruda(v),
        deFisico: (r, _) => r.crudaTurbidez,
        accionesBajo: _cruda,
        accionesAlto: _cruda,
        referencia: _controlCruda,
      ),
      ParametroAlerta(
        clave: 'color_cruda',
        nombre: 'Color agua cruda',
        unidad: 'UPC',
        formato: TipoFormatoAlerta.fisicoquimico,
        evaluar: (v, {referencia}) => ValidadorRangos.validarColorCruda(v),
        deFisico: (r, _) => r.crudaColor,
        accionesBajo: _cruda,
        accionesAlto: _cruda,
        referencia: _controlCruda,
      ),
      // --- DO-F-070: agua filtrada ---
      ParametroAlerta(
        clave: 'ph_filtrada',
        nombre: 'pH agua filtrada',
        unidad: 'pH',
        formato: TipoFormatoAlerta.fisicoquimico,
        evaluar: (v, {referencia}) => ValidadorRangos.validarPhTratada(v, nombre: 'pH Agua Filtrada'),
        deFisico: (r, _) => r.filtradaPh,
        accionesBajo: _phBajo,
        accionesAlto: _phAlto,
        referencia: _res2115,
      ),
      ParametroAlerta(
        clave: 'turbidez_filtrada',
        nombre: 'Turbidez agua filtrada',
        unidad: 'NTU',
        formato: TipoFormatoAlerta.fisicoquimico,
        evaluar: (v, {referencia}) =>
            ValidadorRangos.validarTurbidezTratada(v, nombre: 'Turbidez Agua Filtrada'),
        deFisico: (r, _) => r.filtradaTurbidez,
        accionesBajo: const [_repetir],
        accionesAlto: _turbidezAlta,
        referencia: _res2115,
      ),
      // --- DO-F-070: agua clorada (tratada) ---
      ParametroAlerta(
        clave: 'ph_clorada',
        nombre: 'pH agua tratada',
        unidad: 'pH',
        formato: TipoFormatoAlerta.fisicoquimico,
        evaluar: (v, {referencia}) => ValidadorRangos.validarPhTratada(v, nombre: 'pH Agua Clorada'),
        deFisico: (r, _) => r.cloradaPh,
        accionesBajo: _phBajo,
        accionesAlto: _phAlto,
        referencia: _res2115,
      ),
      ParametroAlerta(
        clave: 'turbidez_clorada',
        nombre: 'Turbidez agua tratada',
        unidad: 'NTU',
        formato: TipoFormatoAlerta.fisicoquimico,
        evaluar: (v, {referencia}) =>
            ValidadorRangos.validarTurbidezTratada(v, nombre: 'Turbidez Agua Clorada'),
        deFisico: (r, _) => r.cloradaTurbidez,
        accionesBajo: const [_repetir],
        accionesAlto: _turbidezAlta,
        referencia: _res2115,
      ),
      ParametroAlerta(
        clave: 'color_clorada',
        nombre: 'Color aparente agua tratada',
        unidad: 'UPC',
        formato: TipoFormatoAlerta.fisicoquimico,
        evaluar: (v, {referencia}) =>
            ValidadorRangos.validarColorAparente(v, nombre: 'Color Aparente Clorada'),
        deFisico: (r, _) => r.cloradaColorAparente,
        accionesBajo: const [_repetir],
        accionesAlto: const ['Revisar la coagulación y la filtración.', _repetir],
        referencia: _res2115,
      ),
      ParametroAlerta(
        clave: 'cloro_clorada',
        nombre: 'Cloro residual libre',
        unidad: 'mg/L',
        formato: TipoFormatoAlerta.fisicoquimico,
        evaluar: (v, {referencia}) =>
            ValidadorRangos.validarCloroResidual(v, nombre: 'Cloro Residual Clorada'),
        deFisico: (r, _) => r.cloradaCloroResidual,
        accionesBajo: _cloroBajo,
        accionesAlto: _cloroAlto,
        referencia: _res2115,
      ),
      // --- DO-F-070: puntos de control de la red ---
      ParametroAlerta(
        clave: 'ph_red',
        nombre: 'pH en la red',
        unidad: 'pH',
        formato: TipoFormatoAlerta.fisicoquimico,
        evaluar: (v, {referencia}) => ValidadorRangos.validarPhTratada(v),
        deFisico: (r, punto) => _punto(r, punto)?.ph,
        accionesBajo: [..._phBajo, _red],
        accionesAlto: [..._phAlto, _red],
        referencia: _res2115,
      ),
      ParametroAlerta(
        clave: 'turbidez_red',
        nombre: 'Turbidez en la red',
        unidad: 'NTU',
        formato: TipoFormatoAlerta.fisicoquimico,
        evaluar: (v, {referencia}) => ValidadorRangos.validarTurbidezTratada(v),
        deFisico: (r, punto) => _punto(r, punto)?.turbidez,
        accionesBajo: const [_repetir],
        accionesAlto: [..._turbidezAlta, _red],
        referencia: _res2115,
      ),
      ParametroAlerta(
        clave: 'cloro_red',
        nombre: 'Cloro residual en la red',
        unidad: 'mg/L',
        formato: TipoFormatoAlerta.fisicoquimico,
        evaluar: (v, {referencia}) => ValidadorRangos.validarCloroResidual(v),
        deFisico: (r, punto) => _punto(r, punto)?.cloroResidual,
        accionesBajo: [..._cloroBajo, _red],
        accionesAlto: [..._cloroAlto, _red],
        referencia: _res2115,
      ),
      // --- Medidores ---
      ParametroAlerta(
        clave: 'agua_no_registrada',
        nombre: 'Agua no registrada',
        unidad: 'm³',
        formato: TipoFormatoAlerta.medidores,
        evaluar: (v, {referencia}) => v > perdidaElevadaM3
            ? EvaluacionRango.fueraDeRango(
                parametro: 'Agua no registrada',
                valor: v,
                minimo: null,
                maximo: perdidaElevadaM3,
                unidad: 'm³',
                explicacion:
                    'El macromedidor registró más agua que la suma de los micromedidores: posibles fugas, '
                    'consumos sin medidor o lecturas erradas.',
              )
            : EvaluacionRango.correcto('m³', valor: v, max: perdidaElevadaM3),
        deJornada: (j, _) => j.aguaNoRegistrada,
        accionesBajo: const [_repetir],
        accionesAlto: const [
          'Revisar fugas visibles en la red y en el tanque.',
          'Verificar las lecturas y fotos de los micromedidores.',
          'Comparar con la jornada anterior.',
        ],
        referencia: _limiteOperativo,
      ),
      ParametroAlerta(
        clave: 'lectura_medidor',
        nombre: 'Lectura del medidor',
        unidad: 'm³',
        formato: TipoFormatoAlerta.medidores,
        evaluar: (v, {referencia}) =>
            ValidadorRangos.validarLecturaMedidor(inicial: referencia, finalLectura: v),
        deJornada: (j, medidor) => _lectura(j, medidor)?.lecturaActual,
        accionesBajo: const [
          'Verificar la lectura y la foto del medidor.',
          'Confirmar si el medidor fue cambiado o reiniciado.',
        ],
        accionesAlto: const ['Verificar la lectura y la foto del medidor.'],
        referencia: _limiteOperativo,
      ),
      // --- Aforo ---
      ParametroAlerta(
        clave: 'caudal_fuente',
        nombre: 'Caudal de la Quebrada La Seca',
        unidad: 'L/s',
        formato: TipoFormatoAlerta.aforo,
        evaluar: (v, {referencia}) => (v < caudalFuenteMinLS || v > caudalFuenteMaxLS)
            ? EvaluacionRango.fueraDeRango(
                parametro: 'Caudal Quebrada La Seca',
                valor: v,
                minimo: caudalFuenteMinLS,
                maximo: caudalFuenteMaxLS,
                unidad: 'L/s',
                explicacion: v < caudalFuenteMinLS
                    ? 'El caudal es críticamente bajo en la fuente; riesgo de estiaje severo.'
                    : 'Puede superar la capacidad de tratamiento / indicar falla en la captación.',
              )
            : EvaluacionRango.correcto('L/s', valor: v, min: caudalFuenteMinLS, max: caudalFuenteMaxLS),
        deAforo: (a) => a.caudalLS,
        accionesBajo: const [
          'Inspeccionar la captación y la bocatoma: obstrucciones o desvíos.',
          'Repetir el aforo.',
          'Informar un posible estiaje.',
        ],
        accionesAlto: const [
          'Revisar crecientes y arrastre de sedimentos en la captación.',
          'Repetir el aforo.',
        ],
        referencia: _limiteOperativo,
      ),
    ])
      p.clave: p,
  };

  static ParametroAlerta? buscar(String? clave) => clave == null ? null : _parametros[clave];

  static Iterable<ParametroAlerta> get todos => _parametros.values;

  /// Evaluación del valor de la alerta con el validador del parámetro (de ahí salen las causas).
  static EvaluacionRango? evaluar(AlertaSistema alerta) {
    final p = buscar(alerta.parametroClave);
    final v = alerta.valorRegistrado;
    if (p == null || v == null) return null;
    return p.evaluar(v, referencia: alerta.minimo);
  }

  /// Últimos [cantidad] valores registrados del parámetro de la alerta, en orden cronológico.
  static List<ValorHistorico> historial(
    AlertaSistema alerta, {
    required List<RegistroFisicoquimico> fisicoquimicos,
    required List<JornadaMedidores> jornadas,
    required List<AforoCaudal> aforos,
    int cantidad = 10,
  }) {
    final p = buscar(alerta.parametroClave);
    if (p == null) return const [];
    final punto = alerta.puntoControl;
    final valores = <ValorHistorico>[];

    if (p.deFisico != null) {
      for (final r in fisicoquimicos) {
        final v = p.deFisico!(r, punto);
        if (v != null) valores.add(ValorHistorico(momentoRegistro(r.fecha, r.hora), v, !p.evaluar(v).cumple));
      }
    }
    if (p.deJornada != null) {
      for (final j in jornadas) {
        final v = p.deJornada!(j, punto);
        if (v == null) continue;
        final fuera = p.clave == 'lectura_medidor'
            ? (_lectura(j, punto)?.fueraDeRango ?? false)
            : !p.evaluar(v).cumple;
        valores.add(ValorHistorico(momentoRegistro(j.fecha, j.hora), v, fuera));
      }
    }
    if (p.deAforo != null) {
      for (final a in aforos) {
        final v = p.deAforo!(a);
        if (v != null) valores.add(ValorHistorico(momentoRegistro(a.fecha, a.hora), v, !p.evaluar(v).cumple));
      }
    }

    valores.sort((a, b) => a.momento.compareTo(b.momento));
    return valores.length > cantidad ? valores.sublist(valores.length - cantidad) : valores;
  }
}
