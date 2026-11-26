import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/identificador.dart';
import '../../../data/models/alerta_sistema_modelo.dart';
import '../../../data/models/medidores_modelos.dart';
import '../../../data/services/foto_lectura_service.dart';
import '../../../domain/calculations/calculos_medidores.dart';
import '../../../domain/alertas/catalogo_parametros_alerta.dart';
import '../../../domain/validators/validador_rangos.dart';
import '../../alerts/providers/alertas_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/preferencias_provider.dart';
import '../providers/medidores_provider.dart';
import 'captura_medidor_screen.dart';

class FormularioJornadaMedidoresScreen extends StatefulWidget {
  const FormularioJornadaMedidoresScreen({super.key});

  @override
  State<FormularioJornadaMedidoresScreen> createState() =>
      _FormularioJornadaMedidoresScreenState();
}

class _FormularioJornadaMedidoresScreenState
    extends State<FormularioJornadaMedidoresScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();
  final _responsableController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Controladores de lecturas actuales y anteriores para cada medidor
  final Map<int, TextEditingController> _actualControllers = {};
  final Map<int, TextEditingController> _anteriorControllers = {};

  // Lecturas tomadas con la cámara: foto de evidencia y método ('camara_ocr' | 'ocr_editado')
  final Map<int, String> _fotos = {};
  final Map<int, String> _metodos = {};
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<SesionUsuarioProvider>();
    _responsableController.text = auth.perfil?.nombreCompleto ?? '';

    final medidoresProv = context.read<MedidoresProvider>();
    final ultimas = medidoresProv.ultimasLecturas;

    for (final m in medidoresProv.catalogoMedidores) {
      final anterior = ultimas[m.id] ?? 0.0;
      _anteriorControllers[m.id] = TextEditingController(
        text: anterior > 0 ? anterior.toStringAsFixed(4) : '0.0000',
      );
      _actualControllers[m.id] = TextEditingController();
    }

    // Si el operario lo eligió en su perfil, la cámara se abre al crear la jornada.
    final usarCamara = context.read<PreferenciasProvider>().usarCamaraMedidores;
    if (usarCamara && (auth.perfil?.puedeEditar ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _abrirCamara(_micromedidores()));
    }
  }

  List<Medidor> _micromedidores() {
    final lista = context.read<MedidoresProvider>().catalogoMedidores.where((m) => m.esMicro).toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
    return lista;
  }

  /// Abre la cámara para los medidores indicados y llena las lecturas confirmadas.
  Future<void> _abrirCamara(List<Medidor> medidores) async {
    if (medidores.isEmpty || !mounted) return;
    final anteriores = {for (final m in medidores) m.id: _parse(_anteriorControllers[m.id]!)};
    final resultados = await Navigator.of(context).push<Map<int, LecturaCapturada>>(
      MaterialPageRoute(
        builder: (_) => CapturaMedidorScreen(medidores: medidores, lecturasAnteriores: anteriores),
      ),
    );
    if (!mounted || resultados == null || resultados.isEmpty) return;

    setState(() {
      for (final m in medidores) {
        final r = resultados[m.id];
        if (r == null) continue;
        _actualControllers[m.id]!.text = r.valor.toStringAsFixed(m.digitosDecimales);
        _fotos[m.id] = r.rutaFoto;
        _metodos[m.id] = r.metodo;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultados.length == 1
            ? 'Lectura cargada desde la cámara.'
            : 'Se cargaron ${resultados.length} lecturas desde la cámara.'),
      ),
    );
  }

  @override
  void dispose() {
    _responsableController.dispose();
    _observacionesController.dispose();
    for (final c in _actualControllers.values) {
      c.dispose();
    }
    for (final c in _anteriorControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0.0;

  // Realiza el balance hídrico automático en tiempo real
  BalanceMedidores _calcularBalanceVivo() {
    final medidores = context.read<MedidoresProvider>().catalogoMedidores;

    final consumosMicros = <double>[];
    double consumoMacro = 0.0;

    for (final m in medidores) {
      final act = _parse(_actualControllers[m.id]!);
      final ant = _parse(_anteriorControllers[m.id]!);
      final con = CalculosMedidores.calcularConsumo(
        lecturaActual: act,
        lecturaAnterior: ant,
      );

      if (m.esMacro) {
        consumoMacro = con;
      } else {
        consumosMicros.add(con);
      }
    }

    return CalculosMedidores.calcularBalance(
      consumosMicros: consumosMicros,
      consumoMacro: consumoMacro,
    );
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) return;

    final medidores = context.read<MedidoresProvider>().catalogoMedidores;

    final balance = _calcularBalanceVivo();
    final authProvider = context.read<SesionUsuarioProvider>();
    final alertasProv = context.read<AlertasProvider>();

    // Las anomalías no se muestran al operario mientras registra: se marcan en el registro
    // (fuera_de_rango) y se envían a la pantalla Alertas.
    bool fueraDeRango = false;
    final jornadaId = generarUuid();
    final responsable = _responsableController.text.trim();

    for (final m in medidores) {
      final act = _parse(_actualControllers[m.id]!);
      final ant = _parse(_anteriorControllers[m.id]!);
      final val = ValidadorRangos.validarLecturaMedidor(
        inicial: ant,
        finalLectura: act,
        nombreMedidor: m.nombre,
      );
      if (!val.cumple) {
        fueraDeRango = true;
        alertasProv.agregarAlerta(
          titulo: 'Lectura de medidor anómala · ${m.nombre}',
          descripcion: val.mensajeCompleto,
          severidad: SeveridadAlerta.advertencia,
          parametro: 'Lectura del medidor',
          valorRegistrado: act,
          tipoFormato: TipoFormatoAlerta.medidores,
          registroId: jornadaId,
          responsable: responsable,
          puntoControl: m.nombre,
          parametroClave: 'lectura_medidor',
          minimo: ant,
          unidad: 'm³',
          rangoEsperado: 'Igual o mayor que la lectura anterior',
        );
      }
    }

    final perdidaAlta = balance.aguaNoRegistrada.abs() > 5.0;
    if (perdidaAlta) {
      fueraDeRango = true;
      alertasProv.agregarAlerta(
        titulo: 'Pérdida hídrica anormal detectada',
        descripcion:
            'Balance hídrico con ANR de ${balance.aguaNoRegistrada.toStringAsFixed(2)} m³ (${balance.porcentajePerdida.toStringAsFixed(1)}%).',
        severidad: SeveridadAlerta.advertencia,
        parametro: 'Agua no registrada',
        valorRegistrado: balance.aguaNoRegistrada,
        tipoFormato: TipoFormatoAlerta.medidores,
        registroId: jornadaId,
        responsable: responsable,
        parametroClave: 'agua_no_registrada',
        maximo: CatalogoParametrosAlerta.perdidaElevadaM3,
        unidad: 'm³',
      );
    }

    setState(() => _guardando = true);
    final listaLecturas = <LecturaMedidor>[];

    for (final m in medidores) {
      final act = _parse(_actualControllers[m.id]!);
      final ant = _parse(_anteriorControllers[m.id]!);
      final con = CalculosMedidores.calcularConsumo(
        lecturaActual: act,
        lecturaAnterior: ant,
      );
      final cumple = ValidadorRangos.validarLecturaMedidor(
        inicial: ant,
        finalLectura: act,
        nombreMedidor: m.nombre,
      ).cumple;

      // La foto de evidencia se guarda en el celular y se sube junto con la jornada,
      // ahora o cuando vuelva la conexión.
      final fotoLocal = _fotos[m.id];
      final fotoUrl = fotoLocal == null
          ? null
          : await FotoLecturaService.guardarCopiaLocal(fotoLocal, '${jornadaId}_${m.codigo}');

      listaLecturas.add(
        LecturaMedidor(
          medidorId: m.id,
          medidorNombre: m.nombre,
          tipoMedidor: m.tipo,
          lecturaActual: act,
          lecturaAnterior: ant,
          consumo: con,
          fotoUrl: fotoUrl,
          metodoLectura: _metodos[m.id] ?? 'manual',
          fueraDeRango: !cumple,
        ),
      );
    }

    if (!mounted) return;
    final horaTexto =
        '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}';

    final nuevaJornada = JornadaMedidores(
      id: jornadaId,
      fecha: _fecha,
      hora: horaTexto,
      responsableLectura: _responsableController.text.trim(),
      observaciones: _observacionesController.text.trim(),
      consumoTotalMicros: balance.consumoTotalMicros,
      consumoMacromedidor: balance.consumoMacromedidor,
      aguaNoRegistrada: balance.aguaNoRegistrada,
      fueraDeRango: fueraDeRango,
      lecturas: listaLecturas,
      createdBy: authProvider.perfil?.id ?? 'operario',
      createdAt: DateTime.now(),
    );

    final provider = context.read<MedidoresProvider>();
    final exito = await provider.guardarJornada(nuevaJornada);

    if (mounted) {
      setState(() => _guardando = false);
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Jornada de medidores guardada exitosamente.'
              '${provider.ultimoGuardadoPendiente ? ' Sin conexión: quedó en el celular y se subirá cuando vuelva la señal.' : ''}',
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
    final medidores = context.watch<MedidoresProvider>().catalogoMedidores;
    final balance = _calcularBalanceVivo();

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        title: const Text('Registro de Medidores'),
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
              // 1. Datos Generales
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Datos de la Jornada de Lectura',
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
                          labelText: 'Responsable de la lectura',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingrese el responsable de lectura'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Tarjeta resumen del Balance Hídrico en Vivo
              Card(
                color: AppColors.senaAzul.withAlpha(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.aguaPrimario, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.balance, color: AppColors.aguaPrimario, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Balance Hídrico Automático (m³)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.senaAzul,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ColumnaBalance(
                            titulo: 'Total Micros',
                            valor: '${balance.consumoTotalMicros.toStringAsFixed(2)} m³',
                            color: AppColors.aguaPrimario,
                          ),
                          _ColumnaBalance(
                            titulo: 'Macro Medidor',
                            valor: '${balance.consumoMacromedidor.toStringAsFixed(2)} m³',
                            color: AppColors.senaAzul,
                          ),
                          _ColumnaBalance(
                            titulo: 'No Registrada',
                            valor: '${balance.aguaNoRegistrada.toStringAsFixed(2)} m³',
                            color: balance.aguaNoRegistrada > 5.0
                                ? AppColors.alerta
                                : AppColors.exito,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Formulario individual por cada uno de los 9 medidores
              const Text(
                '2. Lecturas Individuales de Medidores',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textoPrincipal,
                ),
              ),
              const SizedBox(height: 10),

              // Lectura rápida: recorre los 8 micromedidores con la cámara
              Card(
                color: AppColors.azulClaro,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        key: const Key('leer_con_camara'),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Leer micromedidores con cámara'),
                        onPressed: () => _abrirCamara(_micromedidores()),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enfoque el contador de cada medidor; el valor se llena solo y puede corregirlo. '
                        'También puede usar el ícono de cámara de cada lectura.',
                        style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              ...medidores.map((m) {
                final esMacro = m.esMacro;
                final actCtrl = _actualControllers[m.id]!;
                final antCtrl = _anteriorControllers[m.id]!;

                final actVal = _parse(actCtrl);
                final antVal = _parse(antCtrl);
                final conVal = CalculosMedidores.calcularConsumo(
                  lecturaActual: actVal,
                  lecturaAnterior: antVal,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: esMacro ? AppColors.senaAzul : Colors.grey.shade300,
                      width: esMacro ? 1.8 : 0.8,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  esMacro ? Icons.speed : Icons.water_drop_outlined,
                                  color: esMacro ? AppColors.senaAzul : AppColors.aguaPrimario,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  m.nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: esMacro
                                        ? AppColors.senaAzul
                                        : AppColors.textoPrincipal,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: esMacro
                                    ? AppColors.senaAzul.withAlpha(20)
                                    : AppColors.senaVerde.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Consumo: ${conVal.toStringAsFixed(4)} m³',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: esMacro ? AppColors.senaAzul : AppColors.senaVerde,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Lectura Anterior
                            Expanded(
                              child: TextFormField(
                                controller: antCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Lectura anterior',
                                  suffixText: 'm³',
                                  isDense: true,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Lectura Actual
                            Expanded(
                              child: TextFormField(
                                controller: actCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Lectura actual',
                                  suffixText: 'm³',
                                  isDense: true,
                                  suffixIcon: IconButton(
                                    tooltip: 'Leer con cámara',
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.photo_camera_outlined, size: 20),
                                    color: AppColors.azulPrimario,
                                    onPressed: () => _abrirCamara([m]),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Requerido';
                                  }
                                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                                    return 'Número inválido';
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {
                                  // Si se edita a mano un valor leído por cámara, queda como corregido
                                  if (_metodos[m.id] == 'camara_ocr') _metodos[m.id] = 'ocr_editado';
                                }),
                              ),
                            ),
                          ],
                        ),
                        if (_fotos[m.id] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    File(_fotos[m.id]!),
                                    width: 56,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const SizedBox(width: 56, height: 40),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  _metodos[m.id] == 'ocr_editado' ? Icons.edit_outlined : Icons.photo_camera_outlined,
                                  size: 15,
                                  color: AppColors.turquesaTexto,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _metodos[m.id] == 'ocr_editado'
                                      ? 'Leída con cámara y corregida'
                                      : 'Leída con cámara',
                                  style: const TextStyle(fontSize: 11, color: AppColors.turquesaTexto),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 14),

              // 4. Observaciones
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Observaciones de la Lectura',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.senaAzul,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _observacionesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Novedades sobre medidores, fugas o mantenimientos...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              ElevatedButton.icon(
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _guardando ? 'Guardando…' : 'Guardar Lecturas de Medidores',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _guardando ? null : _guardar,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColumnaBalance extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;

  const _ColumnaBalance({
    required this.titulo,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
