import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/aforo_caudal_modelo.dart';
import '../../../data/models/alerta_sistema_modelo.dart';
import '../../../domain/calculations/calculos_caudal.dart';
import '../../alerts/providers/alertas_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/caudal_provider.dart';

class FormularioAforoCaudalScreen extends StatefulWidget {
  const FormularioAforoCaudalScreen({super.key});

  @override
  State<FormularioAforoCaudalScreen> createState() =>
      _FormularioAforoCaudalScreenState();
}

class _FormularioAforoCaudalScreenState
    extends State<FormularioAforoCaudalScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();

  // Parámetros de campo
  final _anchoController = TextEditingController(text: '0.41');
  final _p1Controller = TextEditingController(text: '0.09');
  final _p2Controller = TextEditingController(text: '0.06');
  final _p3Controller = TextEditingController(text: '0.05');
  final _p4Controller = TextEditingController(text: '0.06');
  final _distanciaController = TextEditingController(text: '3.0');
  final _t1Controller = TextEditingController(text: '7.55');
  final _t2Controller = TextEditingController(text: '5.66');
  final _t3Controller = TextEditingController(text: '8.59');
  final _t4Controller = TextEditingController(text: '7.03');
  final _observacionesController = TextEditingController();

  @override
  void dispose() {
    _anchoController.dispose();
    _p1Controller.dispose();
    _p2Controller.dispose();
    _p3Controller.dispose();
    _p4Controller.dispose();
    _distanciaController.dispose();
    _t1Controller.dispose();
    _t2Controller.dispose();
    _t3Controller.dispose();
    _t4Controller.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0.0;

  ResultadoCaudal? _calcularCaudalVivo() {
    final ancho = _parse(_anchoController);
    final p1 = _parse(_p1Controller);
    final p2 = _parse(_p2Controller);
    final p3 = _parse(_p3Controller);
    final p4 = _parse(_p4Controller);
    final dist = _parse(_distanciaController);
    final t1 = _parse(_t1Controller);
    final t2 = _parse(_t2Controller);
    final t3 = _parse(_t3Controller);
    final t4 = _parse(_t4Controller);

    if (ancho <= 0 || dist <= 0 || (t1 + t2 + t3 + t4) <= 0) {
      return null;
    }

    try {
      return CalculosCaudal.calcular(
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
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final resultado = _calcularCaudalVivo();
    if (resultado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifique los valores de ancho, distancia y tiempos ingresados (deben ser > 0).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validación fuera de rango operativo
    final fueraDeRango = resultado.caudalLS < 10.0 || resultado.caudalLS > 140.0;
    if (fueraDeRango) {
      final confirmar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.advertencia),
              SizedBox(width: 8),
              Expanded(
                child: Text('Caudal Fuera de Rango Operativo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El caudal calculado es de ${resultado.caudalLS.toStringAsFixed(2)} L/s.\n\n'
                '${resultado.caudalLS < 10.0 ? "El caudal es críticamente bajo en la fuente quebrada La Seca; riesgo de estiaje severo." : "El caudal supera la capacidad máxima de derivación y tratamiento."}\n\n'
                '¿Desea confirmar el registro? Debe ingresar obligatoriamente una observación técnica justificando la novedad.',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Corregir'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.advertencia),
              child: const Text('Guardar de todos modos'),
            ),
          ],
        ),
      );

      if (confirmar != true) return;
      if (!mounted) return;

      if (_observacionesController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe ingresar una observación justificando el caudal fuera de rango.'),
            backgroundColor: AppColors.critico,
          ),
        );
        return;
      }

      context.read<AlertasProvider>().agregarAlerta(
        titulo: 'Caudal en fuente fuera de rango',
        descripcion: 'Aforo arrojó ${resultado.caudalLS.toStringAsFixed(2)} L/s en Quebrada La Seca.',
        severidad: SeveridadAlerta.advertencia,
        parametro: 'Caudal Fuente',
        valorRegistrado: resultado.caudalLS,
      );
    }

    final authProvider = context.read<SesionUsuarioProvider>();
    final horaTexto =
        '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}';

    final nuevoAforo = AforoCaudal(
      id: 'aforo-${DateTime.now().millisecondsSinceEpoch}',
      fecha: _fecha,
      hora: horaTexto,
      anchoCauceM: _parse(_anchoController),
      profundidad1M: _parse(_p1Controller),
      profundidad2M: _parse(_p2Controller),
      profundidad3M: _parse(_p3Controller),
      profundidad4M: _parse(_p4Controller),
      distanciaFlotadorM: _parse(_distanciaController),
      tiempo1S: _parse(_t1Controller),
      tiempo2S: _parse(_t2Controller),
      tiempo3S: _parse(_t3Controller),
      tiempo4S: _parse(_t4Controller),
      factorCorreccion: 0.80,
      profundidadPromedioM: resultado.profundidadPromedioM,
      areaSeccionM2: resultado.areaSeccionM2,
      tiempoPromedioS: resultado.tiempoPromedioS,
      velocidadSuperficialMS: resultado.velocidadSuperficialMS,
      velocidadCorregidaMS: resultado.velocidadCorregidaMS,
      caudalM3S: resultado.caudalM3S,
      caudalM3H: resultado.caudalM3H,
      caudalLS: resultado.caudalLS,
      caudalLH: resultado.caudalLH,
      observaciones: _observacionesController.text.trim(),
      createdBy: authProvider.perfil?.id ?? 'operario',
      createdAt: DateTime.now(),
    );

    final provider = context.read<CaudalProvider>();
    final exito = await provider.guardarAforo(nuevoAforo);

    if (mounted) {
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aforo guardado: ${resultado.caudalLS.toStringAsFixed(2)} L/s (${resultado.caudalM3H.toStringAsFixed(1)} m³/h)',
            ),
            backgroundColor: AppColors.exito,
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

  @override
  Widget build(BuildContext context) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final resultado = _calcularCaudalVivo();

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        title: const Text('Nuevo Aforo de Caudal'),
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
              // 1. Fecha y Hora
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Fecha y Hora de Medición',
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Tarjeta de Resultado Calculado en Vivo
              Card(
                color: AppColors.aguaPrimario.withAlpha(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.aguaPrimario, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.water, color: AppColors.aguaPrimario),
                              SizedBox(width: 8),
                              Text(
                                'Caudal Calculado en Vivo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.senaAzul,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.senaVerde.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Método Flotador',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.senaVerde,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _DatoCalculado(
                            titulo: 'Caudal (L/s)',
                            valor: resultado != null
                                ? '${resultado.caudalLS.toStringAsFixed(2)} L/s'
                                : '0.00 L/s',
                            color: AppColors.senaAzul,
                            destacado: true,
                          ),
                          _DatoCalculado(
                            titulo: 'Caudal (m³/h)',
                            valor: resultado != null
                                ? '${resultado.caudalM3H.toStringAsFixed(2)} m³/h'
                                : '0.00 m³/h',
                            color: AppColors.aguaPrimario,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _DatoCalculado(
                            titulo: 'Área Sección',
                            valor: resultado != null
                                ? '${resultado.areaSeccionM2.toStringAsFixed(4)} m²'
                                : '0.00 m²',
                            color: AppColors.textoSecundario,
                          ),
                          _DatoCalculado(
                            titulo: 'Velocidad Corr.',
                            valor: resultado != null
                                ? '${resultado.velocidadCorregidaMS.toStringAsFixed(4)} m/s'
                                : '0.00 m/s',
                            color: AppColors.textoSecundario,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Sección Transversal (Ancho y Profundidades)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.straighten, color: AppColors.senaAzul, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '2. Sección Transversal del Cauce',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.senaAzul,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _anchoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Ancho del cauce',
                          suffixText: 'metros (m)',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Cuatro lecturas de profundidad (m):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _p1Controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Prof. 1 (m)'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _p2Controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Prof. 2 (m)'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _p3Controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Prof. 3 (m)'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _p4Controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Prof. 4 (m)'),
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

              // 4. Velocidad del Flotador
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.timer_outlined, color: AppColors.senaAzul, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '3. Velocidad del Flotador',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.senaAzul,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _distanciaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Distancia recorrida por el flotador',
                          suffixText: 'metros (m)',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Cuatro tiempos cronometrados (s):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _t1Controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Tiempo 1 (s)'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _t2Controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Tiempo 2 (s)'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _t3Controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Tiempo 3 (s)'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _t4Controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Tiempo 4 (s)'),
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

              // 5. Observaciones
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Observaciones del Aforo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.senaAzul,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _observacionesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Condiciones climáticas, turbulencia, presencia de sedimentos...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text(
                  'Guardar Aforo de Caudal',
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

class _DatoCalculado extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final bool destacado;

  const _DatoCalculado({
    required this.titulo,
    required this.valor,
    required this.color,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontSize: destacado ? 18 : 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
