import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/supabase_config.dart';
import 'presentation/admin/providers/admin_provider.dart';
import 'presentation/alerts/providers/alertas_provider.dart';
import 'presentation/asistente/providers/asistente_provider.dart';
import 'presentation/auth/providers/auth_provider.dart';
import 'presentation/common/providers/sincronizacion_provider.dart';
import 'presentation/flow/providers/caudal_provider.dart';
import 'presentation/history/providers/historial_provider.dart';
import 'presentation/intro/screens/intro_video_screen.dart';
import 'presentation/meters/providers/medidores_provider.dart';
import 'presentation/physicochemical/providers/fisicoquimico_provider.dart';
import 'presentation/settings/providers/preferencias_provider.dart';
import 'presentation/settings/providers/umbrales_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // El video de bienvenida sale de una vez; mientras se ve, la app se prepara por detrás.
  runApp(const ArranqueApp());
}

/// Localización en español y Supabase (si las credenciales están presentes).
Future<void> prepararApp() async {
  await initializeDateFormatting('es_ES', null);
  await SupabaseConfig.inicializar();
}

/// Muestra el video de bienvenida apenas se abre la app y luego pasa al login.
/// La app real se crea cuando terminan el video y la preparación (lo que tarde más).
class ArranqueApp extends StatefulWidget {
  final Future<void> Function() preparar;

  const ArranqueApp({super.key, this.preparar = prepararApp});

  @override
  State<ArranqueApp> createState() => _ArranqueAppState();
}

class _ArranqueAppState extends State<ArranqueApp> {
  bool _videoTerminado = false;
  bool _appLista = false;

  @override
  void initState() {
    super.initState();
    widget.preparar().whenComplete(() {
      if (mounted) setState(() => _appLista = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_videoTerminado && _appLista) return const PlantaAguaApp();
    return MaterialApp(
      title: AppStrings.appNombre,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.temaClaro,
      home: IntroVideoScreen(alTerminar: () => setState(() => _videoTerminado = true)),
    );
  }
}

class PlantaAguaApp extends StatefulWidget {
  const PlantaAguaApp({super.key});

  @override
  State<PlantaAguaApp> createState() => _PlantaAguaAppState();
}

class _PlantaAguaAppState extends State<PlantaAguaApp> {
  late final SesionUsuarioProvider _authProvider;
  late final FisicoquimicoProvider _fisicoquimicoProvider;
  late final MedidoresProvider _medidoresProvider;
  late final CaudalProvider _caudalProvider;
  late final HistorialProvider _historialProvider;
  late final AdminProvider _adminProvider;
  late final AlertasProvider _alertasProvider;
  late final UmbralesProvider _umbralesProvider;
  late final PreferenciasProvider _preferenciasProvider;
  late final AsistenteProvider _asistenteProvider;
  late final SincronizacionProvider _sincronizacionProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = SesionUsuarioProvider();
    _fisicoquimicoProvider = FisicoquimicoProvider();
    _medidoresProvider = MedidoresProvider();
    _caudalProvider = CaudalProvider();
    _historialProvider = HistorialProvider();
    _adminProvider = AdminProvider();
    _alertasProvider = AlertasProvider();
    // Carga los umbrales vigentes (Supabase o valores normativos) y los aplica al validador
    _umbralesProvider = UmbralesProvider()..cargar();
    _preferenciasProvider = PreferenciasProvider();
    _asistenteProvider = AsistenteProvider();
    // Sube a Supabase lo que se guardó en el celular sin conexión.
    _sincronizacionProvider = SincronizacionProvider(
      fisico: _fisicoquimicoProvider,
      medidores: _medidoresProvider,
      caudal: _caudalProvider,
    );
  }

  @override
  void dispose() {
    _sincronizacionProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _fisicoquimicoProvider),
        ChangeNotifierProvider.value(value: _medidoresProvider),
        ChangeNotifierProvider.value(value: _caudalProvider),
        ChangeNotifierProvider.value(value: _historialProvider),
        ChangeNotifierProvider.value(value: _adminProvider),
        ChangeNotifierProvider.value(value: _alertasProvider),
        ChangeNotifierProvider.value(value: _umbralesProvider),
        ChangeNotifierProvider.value(value: _preferenciasProvider),
        ChangeNotifierProvider.value(value: _asistenteProvider),
        ChangeNotifierProvider.value(value: _sincronizacionProvider),
      ],
      child: Builder(
        builder: (context) {

          final auth = context.watch<SesionUsuarioProvider>();
          final router = AppRoutes.crearRouter(auth);

          return MaterialApp.router(
            title: AppStrings.appNombre,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.temaClaro,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
