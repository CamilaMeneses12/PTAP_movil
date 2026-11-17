import 'package:go_router/go_router.dart';
import '../../data/models/aforo_caudal_modelo.dart';
import '../../data/models/medidores_modelos.dart';
import '../../data/models/registro_fisicoquimico.dart';
import '../../presentation/admin/screens/admin_dashboard_screen.dart';
import '../../presentation/auth/providers/auth_provider.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/perfil_screen.dart';
import '../../presentation/auth/screens/registro_screen.dart';
import '../../presentation/flow/screens/caudal_dashboard_screen.dart';
import '../../presentation/flow/screens/detalle_aforo_caudal_screen.dart';
import '../../presentation/flow/screens/formulario_aforo_caudal_screen.dart';
import '../../presentation/help/screens/ayuda_screen.dart';
import '../../presentation/history/screens/historial_screen.dart';
import '../../presentation/home/screens/home_screen.dart';
import '../../presentation/meters/screens/detalle_jornada_medidores_screen.dart';
import '../../presentation/meters/screens/formulario_jornada_medidores_screen.dart';
import '../../presentation/meters/screens/lista_jornadas_medidores_screen.dart';
import '../../presentation/physicochemical/screens/detalle_fisicoquimico_screen.dart';
import '../../presentation/physicochemical/screens/formulario_fisicoquimico_screen.dart';
import '../../presentation/physicochemical/screens/lista_fisicoquimicos_screen.dart';
import '../../presentation/reports/screens/exportar_reportes_screen.dart';
import '../../presentation/settings/screens/configuracion_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String registro = '/registro';
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String perfil = '/perfil';
  static const String configuracion = '/configuracion';
  static const String ayuda = '/ayuda';

  // Parámetros Fisicoquímicos (DO-F-070)
  static const String fisicoquimicos = '/fisicoquimicos';
  static const String fisicoquimicoNuevo = '/fisicoquimicos/nuevo';
  static const String fisicoquimicoDetalle = '/fisicoquimicos/detalle';

  // Medidores y Pérdidas
  static const String medidores = '/medidores';
  static const String medidoresNuevo = '/medidores/nuevo';
  static const String medidoresDetalle = '/medidores/detalle';

  // Caudal Quebrada La Seca
  static const String caudal = '/caudal';
  static const String caudalNuevo = '/caudal/nuevo';
  static const String caudalDetalle = '/caudal/detalle';

  // Historial y Filtros
  static const String historial = '/historial';

  // Exportar Reportes (PDF / Excel)
  static const String exportar = '/exportar';

  // Administración (Usuarios y Catálogos)
  static const String admin = '/admin';

  static GoRouter crearRouter(SesionUsuarioProvider authProvider) {
    return GoRouter(
      initialLocation: login,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final estaAutenticado = authProvider.estaAutenticado;
        final enLogin = state.matchedLocation == login;
        final enRegistro = state.matchedLocation == registro;

        if (!estaAutenticado && !enLogin && !enRegistro) {
          return login;
        }

        if (estaAutenticado && (enLogin || enRegistro)) {
          return home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: registro,
          name: 'registro',
          builder: (context, state) => const RegistroScreen(),
        ),
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: dashboard,
          name: 'dashboard',
          redirect: (context, state) => home,
        ),
        GoRoute(
          path: perfil,
          name: 'perfil',
          builder: (context, state) => const PerfilScreen(),
        ),
        GoRoute(
          path: configuracion,
          name: 'configuracion',
          builder: (context, state) => const ConfiguracionScreen(),
        ),
        GoRoute(
          path: ayuda,
          name: 'ayuda',
          builder: (context, state) => const AyudaScreen(),
        ),
        GoRoute(
          path: fisicoquimicos,
          name: 'fisicoquimicos',
          builder: (context, state) => const ListaFisicoquimicosScreen(),
        ),
        GoRoute(
          path: fisicoquimicoNuevo,
          name: 'fisicoquimicoNuevo',
          builder: (context, state) => const FormularioFisicoquimicoScreen(),
        ),
        GoRoute(
          path: fisicoquimicoDetalle,
          name: 'fisicoquimicoDetalle',
          builder: (context, state) {
            final registro = state.extra as RegistroFisicoquimico;
            return DetalleFisicoquimicoScreen(registro: registro);
          },
        ),
        GoRoute(
          path: medidores,
          name: 'medidores',
          builder: (context, state) => const ListaJornadasMedidoresScreen(),
        ),
        GoRoute(
          path: medidoresNuevo,
          name: 'medidoresNuevo',
          builder: (context, state) => const FormularioJornadaMedidoresScreen(),
        ),
        GoRoute(
          path: medidoresDetalle,
          name: 'medidoresDetalle',
          builder: (context, state) {
            final jornada = state.extra as JornadaMedidores;
            return DetalleJornadaMedidoresScreen(jornada: jornada);
          },
        ),
        GoRoute(
          path: caudal,
          name: 'caudal',
          builder: (context, state) => const CaudalDashboardScreen(),
        ),
        GoRoute(
          path: caudalNuevo,
          name: 'caudalNuevo',
          builder: (context, state) => const FormularioAforoCaudalScreen(),
        ),
        GoRoute(
          path: caudalDetalle,
          name: 'caudalDetalle',
          builder: (context, state) {
            final aforo = state.extra as AforoCaudal;
            return DetalleAforoCaudalScreen(aforo: aforo);
          },
        ),
        GoRoute(
          path: historial,
          name: 'historial',
          builder: (context, state) => const HistorialScreen(),
        ),
        GoRoute(
          path: exportar,
          name: 'exportar',
          builder: (context, state) {
            final tipoInicial = state.extra as TipoFormatoExportar?;
            return ExportarReportesScreen(tipoInicial: tipoInicial);
          },
        ),
        GoRoute(
          path: admin,
          name: 'admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
      ],
    );
  }
}
