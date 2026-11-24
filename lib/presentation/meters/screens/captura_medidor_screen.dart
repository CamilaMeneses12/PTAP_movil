import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/medidores_modelos.dart';
import '../../../data/services/dataset_medidores_service.dart';
import '../../../data/services/lector_medidor_ia_service.dart';
import '../../../data/services/ocr_medidor_service.dart';
import '../../../domain/ocr/interprete_lectura_medidor.dart';

/// Lectura obtenida con la cámara para un medidor.
class LecturaCapturada {
  final double valor;
  final String rutaFoto;

  /// 'camara_ocr' si se usó el valor detectado, 'ocr_editado' si el operario lo corrigió.
  final String metodo;

  const LecturaCapturada({required this.valor, required this.rutaFoto, required this.metodo});
}

enum _Fase { camara, procesando, confirmacion }

/// Abre la cámara, lee el contador con OCR y devuelve las lecturas confirmadas
/// (`Map<idMedidor, LecturaCapturada>`). Con varios medidores los recorre en orden.
class CapturaMedidorScreen extends StatefulWidget {
  final List<Medidor> medidores;
  final Map<int, double> lecturasAnteriores;

  const CapturaMedidorScreen({super.key, required this.medidores, required this.lecturasAnteriores});

  @override
  State<CapturaMedidorScreen> createState() => _CapturaMedidorScreenState();
}

class _CapturaMedidorScreenState extends State<CapturaMedidorScreen> with WidgetsBindingObserver {
  final _ocr = OcrMedidorService();
  final _ia = LectorMedidorIaService();
  final _dataset = DatasetMedidoresService();
  final _valorCtrl = TextEditingController();
  final Map<int, LecturaCapturada> _resultados = {};

  CameraController? _camara;
  String? _errorCamara;
  bool _flash = false;
  bool _vertical = false; // recuadro vertical para medidores instalados de lado
  int _indice = 0;
  _Fase _fase = _Fase.camara;
  FotoProcesada? _foto;
  ResultadoLecturaOcr? _lecturaOcr;
  String? _recorteUsado; // recorte (en la orientación correcta) del que salió la lectura
  String? _fuenteLectura; // 'Modelo propio' o 'ML Kit'
  String? _errorValor;

  Medidor get _medidor => widget.medidores[_indice];
  double get _anterior => widget.lecturasAnteriores[_medidor.id] ?? 0;
  bool get _esUltimo => _indice == widget.medidores.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciarCamara();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camara?.dispose();
    _ocr.cerrar();
    _ia.cerrar();
    _valorCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // La cámara se libera al salir de la app y se vuelve a abrir al regresar.
    if (state == AppLifecycleState.inactive) {
      final c = _camara;
      _camara = null;
      c?.dispose();
    } else if (state == AppLifecycleState.resumed && _camara == null) {
      _iniciarCamara();
    }
  }

  Future<void> _iniciarCamara() async {
    try {
      final camaras = await availableCameras();
      if (camaras.isEmpty) {
        setState(() => _errorCamara = 'Este dispositivo no tiene cámara disponible.');
        return;
      }
      final trasera = camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => camaras.first,
      );
      final controlador = CameraController(trasera, ResolutionPreset.high, enableAudio: false);
      await controlador.initialize();
      await controlador.setFlashMode(_flash ? FlashMode.torch : FlashMode.off);
      if (!mounted) {
        await controlador.dispose();
        return;
      }
      setState(() {
        _camara = controlador;
        _errorCamara = null;
      });
    } on CameraException catch (e) {
      final denegado = e.code.startsWith('CameraAccessDenied') || e.code == 'CameraAccessRestricted';
      if (!mounted) return;
      setState(() => _errorCamara = denegado
          ? 'La app no tiene permiso para usar la cámara. Actívelo en Ajustes › Aplicaciones › PTAP › Permisos, '
              'o ingrese la lectura manualmente.'
          : 'No se pudo abrir la cámara: ${e.description ?? e.code}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorCamara = 'No se pudo abrir la cámara: $e');
    }
  }

  Future<void> _cambiarFlash() async {
    final c = _camara;
    if (c == null) return;
    final nuevo = !_flash;
    try {
      await c.setFlashMode(nuevo ? FlashMode.torch : FlashMode.off);
      setState(() => _flash = nuevo);
    } on CameraException catch (_) {
      _mostrarMensaje('Este dispositivo no permite encender la linterna.');
    }
  }

  Future<void> _capturar() async {
    final c = _camara;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;
    setState(() => _fase = _Fase.procesando);
    try {
      final archivo = await c.takePicture();
      final foto = await _ocr.prepararFoto(archivo.path, vertical: _vertical);
      // De lado, el contador puede estar girado hacia cualquiera de los dos sentidos: se prueban ambos.
      final recortes = [foto.rutaRecorte, ?foto.rutaRecorteAlterno];
      final opciones = <ResultadoLecturaOcr?>[];
      final origen = <(String ruta, String fuente)>[];
      for (final ruta in recortes) {
        opciones.add(await _ia.leer(
          ruta,
          digitosEnteros: _medidor.digitosEnteros,
          digitosDecimales: _medidor.digitosDecimales,
        ));
        origen.add((ruta, 'Modelo propio'));
      }
      for (final ruta in recortes) {
        opciones.add(InterpreteLecturaMedidor.interpretar(
          await _ocr.reconocerTexto(ruta),
          digitosEnteros: _medidor.digitosEnteros,
          digitosDecimales: _medidor.digitosDecimales,
          lecturaAnterior: _anterior,
        ));
        origen.add((ruta, 'ML Kit'));
      }
      final indice = InterpreteLecturaMedidor.elegirMejor(opciones, lecturaAnterior: _anterior);
      final lectura = InterpreteLecturaMedidor.mejorLectura(opciones, lecturaAnterior: _anterior);
      if (!mounted) return;
      setState(() {
        _foto = foto;
        _lecturaOcr = lectura;
        _recorteUsado = indice >= 0 ? origen[indice].$1 : foto.rutaRecorte;
        _fuenteLectura = indice >= 0 ? origen[indice].$2 : null;
        _valorCtrl.text = lectura == null ? '' : _formatear(lectura.valor);
        _errorValor = null;
        _fase = _Fase.confirmacion;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _fase = _Fase.camara);
      _mostrarMensaje('No se pudo procesar la foto. Intente de nuevo. ($e)');
    }
  }

  String _formatear(double v) => v.toStringAsFixed(_medidor.digitosDecimales);

  double? get _valorEscrito => double.tryParse(_valorCtrl.text.trim().replaceAll(',', '.'));

  void _usarValor() {
    final valor = _valorEscrito;
    final foto = _foto;
    if (valor == null || foto == null) {
      setState(() => _errorValor = 'Escriba la lectura con números (ej. 829.149).');
      return;
    }
    final sinCambios = _lecturaOcr != null && _formatear(_lecturaOcr!.valor) == _formatear(valor);
    // Cada lectura confirmada queda como ejemplo para volver a entrenar el modelo (entrenamiento/)
    _dataset.guardar(
      rutaRecorte: _recorteUsado ?? foto.rutaRecorte,
      valor: valor,
      codigoMedidor: _medidor.codigo,
      digitosEnteros: _medidor.digitosEnteros,
      digitosDecimales: _medidor.digitosDecimales,
    );
    _resultados[_medidor.id] = LecturaCapturada(
      valor: valor,
      rutaFoto: foto.rutaEvidencia,
      metodo: sinCambios ? 'camara_ocr' : 'ocr_editado',
    );
    _siguiente();
  }

  void _siguiente() {
    if (_esUltimo) {
      Navigator.of(context).pop(_resultados);
      return;
    }
    setState(() {
      _indice++;
      _fase = _Fase.camara;
      _foto = null;
      _lecturaOcr = null;
      _recorteUsado = null;
      _fuenteLectura = null;
      _valorCtrl.clear();
      _errorValor = null;
    });
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_resultados);
      },
      child: Scaffold(
        backgroundColor: _fase == _Fase.confirmacion ? AppColors.fondoGeneral : Colors.black,
        appBar: AppBar(
          backgroundColor: AppColors.azulMarino,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Terminar',
            onPressed: () => Navigator.of(context).pop(_resultados),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.medidores.length > 1
                    ? 'Medidor ${_indice + 1} de ${widget.medidores.length}'
                    : 'Leer medidor',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              Text(
                '${_medidor.nombre} · ${_medidor.codigo}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: switch (_fase) {
            _Fase.confirmacion => _vistaConfirmacion(),
            _ => _vistaCamara(),
          },
        ),
      ),
    );
  }

  Widget _vistaCamara() {
    final c = _camara;
    final anteriorTxt = NumberFormat('#,##0.0###', 'es_CO').format(_anterior);

    Widget centro;
    if (_errorCamara != null) {
      centro = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_outlined, size: 48, color: Colors.white70),
            const SizedBox(height: 12),
            Text(_errorCamara!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _iniciarCamara,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    } else if (c == null || !c.value.isInitialized) {
      centro = const Center(child: CircularProgressIndicator(color: AppColors.turquesa));
    } else {
      centro = Center(
        child: CameraPreview(
          c,
          child: CustomPaint(painter: _GuiaPainter(vertical: _vertical), child: const SizedBox.expand()),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.azulMarino.withAlpha(220),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Alinee los números del contador dentro del recuadro.  Lectura anterior: $anteriorTxt m³',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              TextButton.icon(
                key: const Key('girar_recuadro'),
                onPressed: () => setState(() => _vertical = !_vertical),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.screen_rotation_alt_rounded, size: 18),
                label: Text(_vertical ? 'Horizontal' : 'De lado'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: centro),
              if (_fase == _Fase.procesando)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.turquesa),
                        SizedBox(height: 12),
                        Text('Leyendo el contador…', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          color: AppColors.azulMarino.withAlpha(235),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: _flash ? 'Apagar linterna' : 'Encender linterna',
                    onPressed: c == null ? null : _cambiarFlash,
                    icon: Icon(_flash ? Icons.flash_on_rounded : Icons.flash_off_rounded, color: Colors.white),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Tomar foto',
                child: GestureDetector(
                  onTap: _fase == _Fase.camara ? _capturar : null,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.turquesa, width: 4),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _fase == _Fase.camara && c != null ? Colors.white : Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _siguiente,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: Text(_esUltimo ? 'Ingresar\nmanual' : 'Omitir', textAlign: TextAlign.center),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vistaConfirmacion() {
    final (Color colorConf, Color fondoConf, String textoConf) = switch (_lecturaOcr?.confianza) {
      ConfianzaOcr.alta => (AppColors.exito, AppColors.exitoFondo, 'Lectura clara'),
      ConfianzaOcr.media => (AppColors.advertencia, AppColors.advertenciaFondo, 'Revise el valor'),
      ConfianzaOcr.baja => (AppColors.critico, AppColors.criticoFondo, 'Lectura dudosa: verifique'),
      null => (AppColors.critico, AppColors.criticoFondo, 'No se detectaron números'),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_foto != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(_recorteUsado ?? _foto!.rutaRecorte), fit: BoxFit.cover, height: 110),
          ),
        if (_fuenteLectura != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Leído por: $_fuenteLectura',
              style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text('Valor detectado',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textoSecundario)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: fondoConf, borderRadius: BorderRadius.circular(20)),
              child: Text(textoConf, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorConf)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('valor_ocr'),
          controller: _valorCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
          decoration: InputDecoration(
            suffixText: 'm³',
            hintText: 'Escriba la lectura',
            errorText: _errorValor,
            helperText: 'Lectura anterior: ${_formatear(_anterior)} m³ · Puede corregir el número antes de usarlo',
          ),
          onChanged: (_) => setState(() => _errorValor = null),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _fase = _Fase.camara),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Repetir foto'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('usar_valor'),
                onPressed: _usarValor,
                icon: Icon(_esUltimo ? Icons.check_rounded : Icons.arrow_forward_rounded),
                label: Text(_esUltimo ? 'Usar valor' : 'Usar y seguir'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Oscurece todo menos el recuadro guía donde deben quedar los números del contador.
class _GuiaPainter extends CustomPainter {
  final bool vertical;
  const _GuiaPainter({required this.vertical});

  @override
  void paint(Canvas canvas, Size size) {
    final guia = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * OcrMedidorService.guiaCentroY),
        width: size.width * OcrMedidorService.anchoGuia(vertical),
        height: size.height * OcrMedidorService.altoGuia(vertical),
      ),
      const Radius.circular(12),
    );
    final fuera = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(guia),
    );
    canvas.drawPath(fuera, Paint()..color = AppColors.azulMarino.withAlpha(150));
    canvas.drawRRect(
      guia,
      Paint()
        ..color = AppColors.turquesa
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _GuiaPainter oldDelegate) => oldDelegate.vertical != vertical;
}
