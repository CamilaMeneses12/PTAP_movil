import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/utils/supabase_config.dart';
import '../../flow/providers/caudal_provider.dart';
import '../../meters/providers/medidores_provider.dart';
import '../../physicochemical/providers/fisicoquimico_provider.dart';

/// Sube a Supabase lo que se guardó en el celular sin conexión.
///
/// Lo intenta al abrir la app, cuando la app vuelve a primer plano y cada [intervalo]
/// (15 s) mientras haya pendientes. El operario también puede pedirlo con "Sincronizar ahora".
class SincronizacionProvider extends ChangeNotifier with WidgetsBindingObserver {
  final FisicoquimicoProvider fisico;
  final MedidoresProvider medidores;
  final CaudalProvider caudal;
  final Duration intervalo;

  Timer? _timer;
  bool _sincronizando = false;
  String? _ultimoError;
  DateTime? _ultimaSincronizacion;

  SincronizacionProvider({
    required this.fisico,
    required this.medidores,
    required this.caudal,
    // Corto para que lo guardado sin señal suba apenas vuelva internet. Solo se intenta
    // mientras haya pendientes, así que no gasta datos cuando todo está al día.
    this.intervalo = const Duration(seconds: 15),
    bool automatico = true,
  }) {
    for (final p in [fisico, medidores, caudal]) {
      p.addListener(notifyListeners);
    }
    if (automatico) {
      WidgetsBinding.instance.addObserver(this);
      _timer = Timer.periodic(intervalo, (_) {
        if (pendientes > 0) sincronizar();
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (pendientes > 0) sincronizar();
      });
    }
  }

  /// Supabase no está configurado: todo se guarda solo en este celular.
  bool get modoLocal => !SupabaseConfig.estaInicializado;

  int get pendientes => fisico.pendientes + medidores.pendientes + caudal.pendientes;
  bool get sincronizando => _sincronizando;
  String? get ultimoError => _ultimoError;
  DateTime? get ultimaSincronizacion => _ultimaSincronizacion;

  Future<void> sincronizar() async {
    if (_sincronizando || modoLocal) return;
    _sincronizando = true;
    notifyListeners();
    try {
      final errores = await Future.wait([fisico.sincronizar(), medidores.sincronizar(), caudal.sincronizar()]);
      _ultimoError = errores.whereType<String>().firstOrNull;
      if (_ultimoError == null) _ultimaSincronizacion = DateTime.now();
    } catch (e) {
      _ultimoError = '$e';
    } finally {
      _sincronizando = false;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && pendientes > 0) sincronizar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    for (final p in [fisico, medidores, caudal]) {
      p.removeListener(notifyListeners);
    }
    super.dispose();
  }
}
