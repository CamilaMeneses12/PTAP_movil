import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';

/// Video de bienvenida (imagenes/animacion.mp4) que se ve al abrir la app, antes del login.
/// Dura [duracion] (4 s) aunque el archivo sea más largo, o menos si el operario toca "Omitir".
class IntroVideoScreen extends StatefulWidget {
  final VoidCallback alTerminar;

  /// Ruta del video dentro de los assets.
  final String video;

  /// Cuánto se muestra el video desde que empieza a reproducirse.
  final Duration duracion;

  /// Tiempo máximo de espera por si el video no se puede reproducir en el celular.
  final Duration limite;

  /// Parte de la pantalla que ocupa el video (0,65 = 65 %).
  final double escala;

  const IntroVideoScreen({
    super.key,
    required this.alTerminar,
    this.video = 'imagenes/animacion.mp4',
    this.duracion = const Duration(seconds: 4),
    this.limite = const Duration(seconds: 6),
    this.escala = 0.65,
  });

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  VideoPlayerController? _controlador;
  Timer? _limite;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    _limite = Timer(widget.limite, _terminar);
    _iniciar();
  }

  Future<void> _iniciar() async {
    final c = VideoPlayerController.asset(widget.video);
    _controlador = c;
    try {
      await c.initialize();
      if (!mounted || _terminado) return;
      await c.setVolume(0);
      c.addListener(_revisarFin);
      await c.play();
      // Corta a los 4 s aunque el archivo dure más.
      _limite?.cancel();
      _limite = Timer(widget.duracion, _terminar);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('No se pudo reproducir el video de inicio: $e');
      _terminar();
    }
  }

  void _revisarFin() {
    final v = _controlador?.value;
    if (v == null || !v.isInitialized) return;
    if (v.hasError || (v.duration > Duration.zero && v.position >= v.duration)) _terminar();
  }

  void _terminar() {
    if (_terminado) return;
    _terminado = true;
    _limite?.cancel();
    widget.alTerminar();
  }

  @override
  void dispose() {
    _limite?.cancel();
    _controlador?.removeListener(_revisarFin);
    _controlador?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controlador;
    final listo = c != null && c.value.isInitialized;
    final escala = widget.escala;
    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _terminar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (listo)
              // Más pequeño que la pantalla y centrado; el fondo blanco del video se funde con el de la app.
              Center(
                child: FractionallySizedBox(
                  key: const Key('video_intro'),
                  widthFactor: escala,
                  heightFactor: escala,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: c.value.size.width,
                      height: c.value.size.height,
                      child: VideoPlayer(c),
                    ),
                  ),
                ),
              )
            else
              // Mientras el video abre se ve el mismo logo que en el arranque de Android.
              Center(
                // Logo con fondo transparente (el mismo de la pantalla de arranque de Android).
                child: FractionallySizedBox(
                  widthFactor: 0.6,
                  child: Image.asset(
                    'imagenes/logo_intro.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Positioned(
              right: 16,
              bottom: 24,
              child: SafeArea(
                child: TextButton(
                  key: const Key('omitir_intro'),
                  onPressed: _terminar,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withAlpha(90),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Omitir'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
