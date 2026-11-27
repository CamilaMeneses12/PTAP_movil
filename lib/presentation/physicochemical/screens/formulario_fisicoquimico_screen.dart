import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/identificador.dart';
import '../../../data/models/alerta_sistema_modelo.dart';
import '../../../data/models/registro_fisicoquimico.dart';
import '../../../domain/alertas/catalogo_parametros_alerta.dart';
import '../../../domain/catalogos/puntos_control_red.dart';
import '../../../domain/validators/validador_rangos.dart';
import '../../alerts/providers/alertas_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/widgets/mensaje_fuera_de_rango.dart';
import '../../help/widgets/boton_ver_norma.dart';
import '../providers/fisicoquimico_provider.dart';

class FormularioFisicoquimicoScreen extends StatefulWidget {
  const FormularioFisicoquimicoScreen({super.key});

  @override
  State<FormularioFisicoquimicoScreen> createState() =>
      _FormularioFisicoquimicoScreenState();
}

class _FormularioFisicoquimicoScreenState
    extends State<FormularioFisicoquimicoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Fechas y metadatos
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();
  final _responsableController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Agua Cruda
  final _crudaCaudalController = TextEditingController();
  final _crudaPhController = TextEditingController();
  final _crudaTurbidezController = TextEditingController();
  final _crudaColorController = TextEditingController();
  final _crudaDurezaController = TextEditingController();
  final _crudaDosisCoagulanteController = TextEditingController();

  // Agua Filtrada
  final _filtradaTurbidezController = TextEditingController();
  final _filtradaPhController = TextEditingController();

  // Agua Clorada
  final _cloradaTurbidezController = TextEditingController();
  final _cloradaPhController = TextEditingController();
  final _cloradaColorController = TextEditingController();
  final _cloradaCloroController = TextEditingController();

  // Puntos de Control en Red
  final List<MedicionPuntoControl> _puntosControl = [];

  // Todos los puntos de control en red del DO-F-070
  final List<String> _areasDisponibles = PuntosControlRed.nombres;

  @override
  void initState() {
    super.initState();
    final perfil = context.read<SesionUsuarioProvider>().perfil;
    _responsableController.text = perfil?.nombreCompleto ?? '';

    // Inicializar puntos de red por defecto
    for (final area in _areasDisponibles) {
      _puntosControl.add(MedicionPuntoControl(areaNombre: area));
    }
  }

  @override
  void dispose() {
    _responsableController.dispose();
    _observacionesController.dispose();
    _crudaCaudalController.dispose();
    _crudaPhController.dispose();
    _crudaTurbidezController.dispose();
    _crudaColorController.dispose();
    _crudaDurezaController.dispose();
    _crudaDosisCoagulanteController.dispose();
    _filtradaTurbidezController.dispose();
    _filtradaPhController.dispose();
    _cloradaTurbidezController.dispose();
    _cloradaPhController.dispose();
    _cloradaColorController.dispose();
    _cloradaCloroController.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  // Evalúa si existe algún parámetro fuera de los límites de la Resolución 2115 / DO-F-070.
  // Cada hallazgo lleva la clave del parámetro y el punto de control para el detalle de la alerta.
  List<_Hallazgo> _obtenerHallazgos() {
    final hallazgos = <_Hallazgo>[];
    void evaluar(String clave, String nombre, double? valor, {String? punto}) {
      if (valor == null) return;
      final param = CatalogoParametrosAlerta.buscar(clave)!;
      final eval = punto == null
          ? param.evaluar(valor)
          : switch (clave) {
              'ph_red' => ValidadorRangos.validarPhTratada(valor, nombre: 'pH $punto'),
              'turbidez_red' => ValidadorRangos.validarTurbidezTratada(valor, nombre: 'Turbidez $punto'),
              _ => ValidadorRangos.validarCloroResidual(valor, nombre: 'Cloro $punto'),
            };
      if (!eval.cumple) hallazgos.add(_Hallazgo(clave, nombre, punto, eval));
    }

    // Cruda
    evaluar('ph_cruda', 'pH agua cruda', _parse(_crudaPhController));
    evaluar('turbidez_cruda', 'Turbidez agua cruda', _parse(_crudaTurbidezController));
    evaluar('color_cruda', 'Color agua cruda', _parse(_crudaColorController));

    // Filtrada
    evaluar('ph_filtrada', 'pH agua filtrada', _parse(_filtradaPhController));
    evaluar('turbidez_filtrada', 'Turbidez agua filtrada', _parse(_filtradaTurbidezController));

    // Clorada
    evaluar('ph_clorada', 'pH agua tratada', _parse(_cloradaPhController));
    evaluar('turbidez_clorada', 'Turbidez agua tratada', _parse(_cloradaTurbidezController));
    evaluar('color_clorada', 'Color aparente agua tratada', _parse(_cloradaColorController));
    evaluar('cloro_clorada', 'Cloro residual libre', _parse(_cloradaCloroController));

    // Puntos de Red
    for (final p in _puntosControl) {
      evaluar('ph_red', 'pH en la red', p.ph, punto: p.areaNombre);
      evaluar('turbidez_red', 'Turbidez en la red', p.turbidez, punto: p.areaNombre);
      evaluar('cloro_red', 'Cloro residual en la red', p.cloroResidual, punto: p.areaNombre);
    }

    return hallazgos;
  }

  List<EvaluacionRango> _obtenerEvaluacionesFueraDeRango() =>
      _obtenerHallazgos().map((h) => h.evaluacion).toList();

  List<String> _obtenerAlertasFueraDeRango() {
    return _obtenerEvaluacionesFueraDeRango()
        .map((e) => e.mensajeCompleto)
        .toList();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final hallazgos = _obtenerHallazgos();
    final evaluaciones = hallazgos.map((h) => h.evaluacion).toList();
    final hayAlertas = evaluaciones.isNotEmpty;
    final registroId = generarUuid();

    // Validación: Valores fuera de rango -> Aviso informativo no bloqueante
    if (hayAlertas) {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.advertenciaFondo,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.advertencia, size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Aviso: Parámetros fuera de rango',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'El registro se guardará con los siguientes parámetros anómalos y generará una alerta en el sistema:',
                  style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 10),
                ...evaluaciones.map(
                  (eval) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: eval.esCritico ? AppColors.criticoFondo : AppColors.advertenciaFondo,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: eval.esCritico ? AppColors.critico : AppColors.advertencia,
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eval.esCritico ? 'CRÍTICA' : 'ADVERTENCIA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: eval.esCritico ? AppColors.critico : AppColors.advertencia,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          eval.mensajeCompleto,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: eval.esCritico ? AppColors.critico : AppColors.advertencia,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'La observación explicativa es opcional pero recomendada.',
                  style: TextStyle(fontSize: 11, color: AppColors.textoSecundario, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulPrimario,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (!mounted) return;

      // Generar alertas en AlertasProvider
      final alertasProv = context.read<AlertasProvider>();
      for (final h in hallazgos) {
        alertasProv.agregarDesdeEvaluacion(
          evaluacion: h.evaluacion,
          titulo: h.punto == null ? '${h.nombre} fuera de rango' : '${h.nombre} fuera de rango · ${h.punto}',
          parametro: h.nombre,
          parametroClave: h.clave,
          tipoFormato: TipoFormatoAlerta.fisicoquimico,
          registroId: registroId,
          responsable: _responsableController.text.trim(),
          puntoControl: h.punto,
        );
      }
    }

    final authProvider = context.read<SesionUsuarioProvider>();
    final horaTexto =
        '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}';

    final nuevoRegistro = RegistroFisicoquimico(
      id: registroId,
      fecha: _fecha,
      hora: horaTexto,
      crudaCaudalEntrada: _parse(_crudaCaudalController),
      crudaPh: _parse(_crudaPhController),
      crudaTurbidez: _parse(_crudaTurbidezController),
      crudaColor: _parse(_crudaColorController),
      crudaDureza: _parse(_crudaDurezaController),
      crudaDosisCoagulante: _crudaDosisCoagulanteController.text.trim(),
      filtradaTurbidez: _parse(_filtradaTurbidezController),
      filtradaPh: _parse(_filtradaPhController),
      cloradaTurbidez: _parse(_cloradaTurbidezController),
      cloradaPh: _parse(_cloradaPhController),
      cloradaColorAparente: _parse(_cloradaColorController),
      cloradaCloroResidual: _parse(_cloradaCloroController),
      puntosControl: _puntosControl,
      observaciones: _observacionesController.text.trim(),
      responsableNombre: _responsableController.text.trim(),
      fueraDeRango: hayAlertas,
      createdBy: authProvider.perfil?.id ?? 'operario',
      createdAt: DateTime.now(),
    );

    final provider = context.read<FisicoquimicoProvider>();
    final exito = await provider.guardarRegistro(nuevoRegistro);

    if (mounted) {
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (hayAlertas
                      ? 'Registro guardado con observaciones y alerta generada en el sistema.'
                      : 'Registro de calidad del agua guardado correctamente.') +
                  (provider.ultimoGuardadoPendiente ? ' Sin conexión: quedó en el celular y se subirá cuando vuelva la señal.' : ''),
            ),
            backgroundColor: hayAlertas ? AppColors.advertencia : AppColors.exito,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.mensajeError ?? 'Error al guardar'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _editarPuntoRed(int index) {
    final p = _puntosControl[index];
    final turbCtrl = TextEditingController(text: p.turbidez?.toString() ?? '');
    final phCtrl = TextEditingController(text: p.ph?.toString() ?? '');
    final colCtrl = TextEditingController(text: p.colorAparente?.toString() ?? '');
    final clorCtrl = TextEditingController(text: p.cloroResidual?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Medición: ${p.areaNombre}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: phCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'pH (6.5 - 9.0)',
                  suffixText: 'pH',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: turbCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Turbidez (0.0 - 2.0)',
                  suffixText: 'NTU',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: colCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Color Aparente (máx 15)',
                  suffixText: 'UPC',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: clorCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cloro residual (0.3 - 2.0)',
                  suffixText: 'mg/L',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final turb = double.tryParse(turbCtrl.text.replaceAll(',', '.'));
              final ph = double.tryParse(phCtrl.text.replaceAll(',', '.'));
              final col = double.tryParse(colCtrl.text.replaceAll(',', '.'));
              final clor = double.tryParse(clorCtrl.text.replaceAll(',', '.'));

              bool fuera = false;
              if (ph != null && (ph < 6.5 || ph > 9.0)) fuera = true;
              if (turb != null && (turb < 0 || turb > 2.0)) fuera = true;
              if (col != null && col > 15.0) fuera = true;
              if (clor != null && (clor < 0.3 || clor > 2.0)) fuera = true;

              setState(() {
                _puntosControl[index] = p.copyWith(
                  turbidez: turb,
                  ph: ph,
                  colorAparente: col,
                  cloroResidual: clor,
                  fueraDeRango: fuera,
                );
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Guardar Punto'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final alertas = _obtenerAlertasFueraDeRango();
    final hayAlertas = alertas.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        title: const Text('Formato DO-F-070'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Banner reactivo de fuera de rango
              if (hayAlertas)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.alertaFondo,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.alerta, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.alerta, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '¡Alerta! ${alertas.length} parámetro(s) fuera de rango normativo (Res. 2115/2007)',
                              style: const TextStyle(
                                color: AppColors.alerta,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Align(alignment: Alignment.centerRight, child: BotonVerNorma()),
                      Text(
                        'Se permite guardar, pero debe ingresar obligatoriamente una observación al final justificando la novedad.',
                        style: TextStyle(
                          color: Colors.brown.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              // 1. Cabecera (Fecha, Hora, Responsable)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Datos Generales de la Toma',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.senaAzul,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(formatoFecha.format(_fecha)),
                              onPressed: () async {
                                final pick = await showDatePicker(
                                  context: context,
                                  initialDate: _fecha,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (pick != null) setState(() => _fecha = pick);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.access_time, size: 16),
                              label: Text(_hora.format(context)),
                              onPressed: () async {
                                final pick = await showTimePicker(
                                  context: context,
                                  initialTime: _hora,
                                );
                                if (pick != null) setState(() => _hora = pick);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _responsableController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del responsable del análisis',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingrese el responsable de la toma'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Agua Cruda
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.waves, color: Colors.brown, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '2. Agua Cruda (Entrada)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.senaAzul,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Norma DO-F-070: pH [5.0-9.0] | Turbidez [máx 10 UJT] | Color [máx 20 UPC]',
                        style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _crudaCaudalController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Caudal entrada',
                                    suffixText: 'L/s',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const IndicadorRangoPermitido(textoRango: '110–140 L/s'),
                                MensajeFueraDeRango(
                                  evaluacion: ValidadorRangos.validarCaudalEntrada(_parse(_crudaCaudalController)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _crudaPhController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'pH',
                                    hintText: '5.0 - 9.0',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const IndicadorRangoPermitido(textoRango: '5,0–9,0 pH'),
                                MensajeFueraDeRango(
                                  evaluacion: ValidadorRangos.validarPhCruda(_parse(_crudaPhController)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _crudaTurbidezController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Turbidez entrada',
                                    suffixText: 'UJT',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const IndicadorRangoPermitido(textoRango: 'máx. 10 UJT'),
                                MensajeFueraDeRango(
                                  evaluacion: ValidadorRangos.validarTurbidezCruda(_parse(_crudaTurbidezController)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _crudaColorController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Color',
                                    suffixText: 'UPC',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const IndicadorRangoPermitido(textoRango: 'máx. 20 UPC'),
                                MensajeFueraDeRango(
                                  evaluacion: ValidadorRangos.validarColorCruda(_parse(_crudaColorController)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _crudaDurezaController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Dureza',
                                suffixText: 'mg/L',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _crudaDosisCoagulanteController,
                              decoration: const InputDecoration(
                                labelText: 'Dosis coagulante',
                                hintText: 'mg/L o test',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Agua Filtrada
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.filter_alt_outlined, color: AppColors.aguaPrimario, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '3. Agua Filtrada',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.senaAzul,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Res. 2115: pH [6.5 - 9.0] | Turbidez [0.0 - 2.0 NTU]',
                              style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                            ),
                          ),
                          BotonVerNorma(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _filtradaPhController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'pH filtrada',
                                    hintText: '6.5 - 9.0',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const IndicadorRangoPermitido(textoRango: '6,5–9,0 pH'),
                                MensajeFueraDeRango(
                                  evaluacion: ValidadorRangos.validarPhTratada(_parse(_filtradaPhController), nombre: 'pH Agua Filtrada'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _filtradaTurbidezController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Turbidez filtrada',
                                    suffixText: 'NTU',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const IndicadorRangoPermitido(textoRango: '0,0–2,0 NTU'),
                                MensajeFueraDeRango(
                                  evaluacion: ValidadorRangos.validarTurbidezTratada(_parse(_filtradaTurbidezController), nombre: 'Turbidez Agua Filtrada'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4. Agua Clorada
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.sanitizer_outlined, color: AppColors.senaVerde, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '4. Agua Clorada (Salida PTAP)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.senaAzul,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'pH [6.5-9.0] | Turbidez [0-2 NTU] | Color [máx 15 UPC] | Cloro [0.3-2.0 mg/L]',
                        style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _cloradaPhController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'pH clorada',
                                    hintText: '6.5 - 9.0',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const IndicadorRangoPermitido(textoRango: '6,5–9,0 pH'),
                                MensajeFueraDeRango(
                                  evaluacion: ValidadorRangos.validarPhTratada(_parse(_cloradaPhController), nombre: 'pH Agua Clorada'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _cloradaTurbidezController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Turbidez',
                                    suffixText: 'NTU',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const IndicadorRangoPermitido(textoRango: '0,0–2,0 NTU'),
                                MensajeFueraDeRango(
                                  evaluacion: ValidadorRangos.validarTurbidezTratada(_parse(_cloradaTurbidezController), nombre: 'Turbidez Agua Clorada'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _cloradaColorController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Color Aparente',
                                    suffixText: 'UPC',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const IndicadorRangoPermitido(textoRango: 'máx. 15 UPC'),
                                MensajeFueraDeRango(
                                  evaluacion: ValidadorRangos.validarColorAparente(_parse(_cloradaColorController), nombre: 'Color Aparente Clorada'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _cloradaCloroController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Cloro residual',
                                    suffixText: 'mg/L',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const IndicadorRangoPermitido(textoRango: '0,3–2,0 mg/L'),
                                MensajeFueraDeRango(
                                  evaluacion: ValidadorRangos.validarCloroResidual(_parse(_cloradaCloroController), nombre: 'Cloro Residual Clorada'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 5. Puntos de Control (Red interna)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            '5. Puntos de Control en Red',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.senaAzul,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toma de muestras en las ${PuntosControlRed.todos.length} áreas de la red. Toque cada punto para registrar sus valores.',
                        style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_puntosControl.length, (index) {
                        final p = _puntosControl[index];
                        final datosLlenos = p.ph != null || p.cloroResidual != null;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: p.fueraDeRango
                                ? AppColors.alertaFondo
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: p.fueraDeRango
                                  ? AppColors.alerta
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              datosLlenos
                                  ? (p.fueraDeRango ? Icons.warning : Icons.check_circle)
                                  : Icons.radio_button_unchecked,
                              color: p.fueraDeRango
                                  ? AppColors.alerta
                                  : (datosLlenos ? AppColors.senaVerde : Colors.grey),
                            ),
                            title: Text(
                              p.areaNombre,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: datosLlenos
                                ? Text(
                                    'pH: ${p.ph ?? "-"} | Turb: ${p.turbidez ?? "-"} NTU | Cloro: ${p.cloroResidual ?? "-"} mg/L',
                                    style: const TextStyle(fontSize: 11),
                                  )
                                : const Text('Sin registrar (toca para diligenciar)'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_note, color: AppColors.senaAzul),
                              onPressed: () => _editarPuntoRed(index),
                            ),
                            onTap: () => _editarPuntoRed(index),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 6. Observaciones y Cierre
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '6. Observaciones de la Toma',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.senaAzul,
                            ),
                          ),
                          if (hayAlertas) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '*(Obligatorio por alerta)',
                              style: TextStyle(
                                color: AppColors.alerta,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _observacionesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: hayAlertas
                              ? 'Indica la causa de los valores fuera de rango y las acciones correctivas aplicadas...'
                              : 'Observaciones generales o anomalías presentadas en la planta...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar Registro
              ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text(
                  'Guardar Formato DO-F-070',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _guardar,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Valor fuera de rango del DO-F-070 con los datos que necesita su alerta.
class _Hallazgo {
  final String clave;
  final String nombre;
  final String? punto;
  final EvaluacionRango evaluacion;
  const _Hallazgo(this.clave, this.nombre, this.punto, this.evaluacion);
}
