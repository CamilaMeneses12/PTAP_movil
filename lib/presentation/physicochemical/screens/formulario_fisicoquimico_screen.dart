import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/registro_fisicoquimico.dart';
import '../../../domain/validators/validador_rangos.dart';
import '../../auth/providers/auth_provider.dart';
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

  // Puntos por defecto para agregar rápido
  final List<String> _areasDisponibles = [
    'Biocabaña',
    'Agroindustria',
    'Gastronomia',
    'ENCC',
    'Dispensador Bienestar',
  ];

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

  // Evalúa si existe algún parámetro fuera de los límites de la Resolución 2115 / DO-F-070
  List<String> _obtenerAlertasFueraDeRango() {
    final alertas = <String>[];

    // Cruda
    final crudaPh = _parse(_crudaPhController);
    final valCrudaPh = ValidadorRangos.validarPhCruda(crudaPh);
    if (!valCrudaPh.cumple) alertas.add(valCrudaPh.mensajeAlerta!);

    final crudaTurb = _parse(_crudaTurbidezController);
    final valCrudaTurb = ValidadorRangos.validarTurbidezCruda(crudaTurb);
    if (!valCrudaTurb.cumple) alertas.add(valCrudaTurb.mensajeAlerta!);

    final crudaColor = _parse(_crudaColorController);
    final valCrudaCol = ValidadorRangos.validarColorCruda(crudaColor);
    if (!valCrudaCol.cumple) alertas.add(valCrudaCol.mensajeAlerta!);

    // Filtrada
    final filtPh = _parse(_filtradaPhController);
    final valFiltPh = ValidadorRangos.validarPhTratada(filtPh, nombre: 'pH Agua Filtrada');
    if (!valFiltPh.cumple) alertas.add(valFiltPh.mensajeAlerta!);

    final filtTurb = _parse(_filtradaTurbidezController);
    final valFiltTurb = ValidadorRangos.validarTurbidezTratada(filtTurb, nombre: 'Turbidez Agua Filtrada');
    if (!valFiltTurb.cumple) alertas.add(valFiltTurb.mensajeAlerta!);

    // Clorada
    final clorPh = _parse(_cloradaPhController);
    final valClorPh = ValidadorRangos.validarPhTratada(clorPh, nombre: 'pH Agua Clorada');
    if (!valClorPh.cumple) alertas.add(valClorPh.mensajeAlerta!);

    final clorTurb = _parse(_cloradaTurbidezController);
    final valClorTurb = ValidadorRangos.validarTurbidezTratada(clorTurb, nombre: 'Turbidez Agua Clorada');
    if (!valClorTurb.cumple) alertas.add(valClorTurb.mensajeAlerta!);

    final clorCol = _parse(_cloradaColorController);
    final valClorCol = ValidadorRangos.validarColorAparente(clorCol, nombre: 'Color Aparente Clorada');
    if (!valClorCol.cumple) alertas.add(valClorCol.mensajeAlerta!);

    final clorCloro = _parse(_cloradaCloroController);
    final valClorCloro = ValidadorRangos.validarCloroResidual(clorCloro, nombre: 'Cloro Residual Clorada');
    if (!valClorCloro.cumple) alertas.add(valClorCloro.mensajeAlerta!);

    // Puntos de Red
    for (final p in _puntosControl) {
      if (p.ph != null) {
        final v = ValidadorRangos.validarPhTratada(p.ph, nombre: 'pH ${p.areaNombre}');
        if (!v.cumple) alertas.add(v.mensajeAlerta!);
      }
      if (p.turbidez != null) {
        final v = ValidadorRangos.validarTurbidezTratada(p.turbidez, nombre: 'Turbidez ${p.areaNombre}');
        if (!v.cumple) alertas.add(v.mensajeAlerta!);
      }
      if (p.cloroResidual != null) {
        final v = ValidadorRangos.validarCloroResidual(p.cloroResidual, nombre: 'Cloro ${p.areaNombre}');
        if (!v.cumple) alertas.add(v.mensajeAlerta!);
      }
    }

    return alertas;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final alertas = _obtenerAlertasFueraDeRango();
    final hayAlertas = alertas.isNotEmpty;

    // Si hay parámetros fuera de rango, es obligatorio documentar la observación
    if (hayAlertas && _observacionesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Atención! Hay valores fuera de rango. Debe ingresar una observación justificando la anomalía antes de guardar.',
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final authProvider = context.read<SesionUsuarioProvider>();
    final horaTexto =
        '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}';

    final nuevoRegistro = RegistroFisicoquimico(
      id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
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
              hayAlertas
                  ? 'Registro guardado con observaciones por valores fuera de rango.'
                  : 'Registro de calidad del agua guardado correctamente.',
            ),
            backgroundColor: hayAlertas ? AppColors.alerta : AppColors.exito,
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
                      const SizedBox(height: 6),
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
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _crudaCaudalController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Caudal entrada',
                                suffixText: 'L/S',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _crudaPhController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'pH',
                                hintText: '5.0 - 9.0',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _crudaTurbidezController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Turbidez entrada',
                                suffixText: 'UJT',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _crudaColorController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Color',
                                suffixText: 'UPC',
                              ),
                              onChanged: (_) => setState(() {}),
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
                      const Text(
                        'Res. 2115: pH [6.5 - 9.0] | Turbidez [0.0 - 2.0 NTU]',
                        style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _filtradaPhController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'pH filtrada',
                                hintText: '6.5 - 9.0',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _filtradaTurbidezController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Turbidez filtrada',
                                suffixText: 'NTU',
                              ),
                              onChanged: (_) => setState(() {}),
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
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cloradaPhController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'pH clorada',
                                hintText: '6.5 - 9.0',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _cloradaTurbidezController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Turbidez',
                                suffixText: 'NTU',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cloradaColorController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Color Aparente',
                                suffixText: 'UPC',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _cloradaCloroController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Cloro residual',
                                suffixText: 'mg/L',
                              ),
                              onChanged: (_) => setState(() {}),
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
                      const Text(
                        'Toma de muestras en áreas de formación (Biocabaña, Gastronomía, etc.)',
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
