import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/supabase_config.dart';
import 'presentation/admin/providers/admin_provider.dart';
import 'presentation/auth/providers/auth_provider.dart';
import 'presentation/flow/providers/caudal_provider.dart';
import 'presentation/history/providers/historial_provider.dart';
import 'presentation/meters/providers/medidores_provider.dart';
import 'presentation/physicochemical/providers/fisicoquimico_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar localización en español
  await initializeDateFormatting('es_ES', null);

  // Inicializar Supabase si las credenciales están presentes
  await SupabaseConfig.inicializar();

  runApp(const PlantaAguaApp());
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

  @override
  void initState() {
    super.initState();
    _authProvider = SesionUsuarioProvider();
    _fisicoquimicoProvider = FisicoquimicoProvider();
    _medidoresProvider = MedidoresProvider();
    _caudalProvider = CaudalProvider();
    _historialProvider = HistorialProvider();
    _adminProvider = AdminProvider();
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
