import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/aforo_caudal_modelo.dart';
import '../../data/models/medidores_modelos.dart';
import '../../data/models/registro_fisicoquimico.dart';
import '../../data/models/usuario_perfil.dart';
import '../../presentation/admin/screens/admin_dashboard_screen.dart';
import '../../presentation/alerts/screens/alertas_screen.dart';
import '../../presentation/alerts/screens/detalle_alerta_screen.dart';
import '../../presentation/asistente/screens/asistente_screen.dart';
import '../../presentation/auth/providers/auth_provider.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/perfil_screen.dart';
import '../../presentation/auth/screens/registro_screen.dart';
import '../../presentation/common/widgets/barra_navegacion_inferior.dart';
import '../../presentation/flow/screens/caudal_dashboard_screen.dart';
import '../../presentation/flow/screens/detalle_aforo_caudal_screen.dart';
import '../../presentation/flow/screens/formulario_aforo_caudal_screen.dart';
import '../../presentation/flow/screens/monitoreo_screen.dart';
import '../../presentation/help/screens/ayuda_screen.dart';
import '../../presentation/help/screens/normatividad_screen.dart';
import '../../presentation/history/screens/historial_screen.dart';
import '../../presentation/home/screens/home_screen.dart';
import '../../presentation/meters/screens/detalle_jornada_medidores_screen.dart';
import '../../presentation/meters/screens/formulario_jornada_medidores_screen.dart';
import '../../presentation/meters/screens/lista_jornadas_medidores_screen.dart';
import '../../presentation/physicochemical/screens/detalle_fisicoquimico_screen.dart';
import '../../presentation/physicochemical/screens/formulario_fisicoquimico_screen.dart';
import '../../presentation/physicochemical/screens/lista_fisicoquimicos_screen.dart';
import '../../presentation/reports/screens/estadisticas_screen.dart';
import '../../presentation/reports/screens/exportar_reportes_screen.dart';
import '../../presentation/settings/screens/configuracion_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String registro = '/registro';

  // 5 Pestañas de la Barra Inferior (Figma Oficial)
  static const String inicio = '/inicio';
  static const String monitoreo = '/monitoreo';
  static const String estadisticas = '/estadisticas';
  static const String registros = '/registros';
  static const String perfil = '/perfil';

  // Rutas de compatibilidad anteriores
  static const String home = '/inicio';
  static const String dashboard = '/inicio';
  static const String historial = '/registros';

  // Pantalla de Alertas (abierta encima del shell con "<")
  static const String alertas = '/alertas';

  // Detalle de una alerta: /alertas/detalle/<id>
  static const String alertaDetalle = '/alertas/detalle';
  static String rutaAlerta(String id) => '$alertaDetalle/${Uri.encodeComponent(id)}';

  // Asistente PTAP (chatbot: servidor con nube + modelo local, o modelo dentro del celular)
  static const String asistente = '/asistente';

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

  // Exportar Reportes (PDF / Excel)
  static const String exportar = '/exportar';

  // Administración y Configuración
  static const String admin = '/admin';
  static const String configuracion = '/configuracion';
  static const String ayuda = '/ayuda';
  static const String normatividad = '/ayuda/normatividad';

  /// Rutas para crear registros: solo operario y administrador.
  static const Set<String> rutasEdicion = {fisicoquimicoNuevo, medidoresNuevo, caudalNuevo};

  /// Indica si el rol del usuario puede abrir la ruta. Se aplica en el redirect del router,
  /// así una ruta prohibida no se abre aunque se llegue a ella por un enlace o botón.
  static bool rutaPermitida(UsuarioPerfil? perfil, String ubicacion) {
    if (perfil == null) return true;
    if (ubicacion == admin || ubicacion.startsWith('$admin/')) return perfil.puedeAdministrar;
    if (rutasEdicion.contains(ubicacion)) return perfil.puedeEditar;
    return true;
  }

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

        if (estaAutenticado && (enLogin || enRegistro || state.matchedLocation == '/')) {
          return inicio;
        }

        if (state.matchedLocation == '/historial') {
          return registros;
        }

        if (state.matchedLocation == '/dashboard') {
          return inicio;
        }

        if (estaAutenticado && !rutaPermitida(authProvider.perfil, state.uri.path)) {
          return inicio;
        }

        return null;
      },
      routes: [
        // Rutas de Autenticación
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

        // Shell de Navegación con 5 Pestañas Fijas Fieles a Figma
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return _ContenedorPrincipalShell(navigationShell: navigationShell);
          },
          branches: [
            // 01 Inicio (Dashboard)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: inicio,
                  name: 'inicio',
                  builder: (context, state) => HomeScreen(
                    alCambiarPestana: (idx) {
                      // Permite a HomeScreen cambiar de pestaña directamente
                      final shell = _ContenedorPrincipalShell.of(context);
                      shell?.navigationShell.goBranch(idx);
                    },
                  ),
                ),
              ],
            ),

            // 02 Monitoreo (Tiempo Real)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: monitoreo,
                  name: 'monitoreo',
                  builder: (context, state) => const MonitoreoScreen(),
                ),
              ],
            ),

            // 03 Estadísticas
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: estadisticas,
                  name: 'estadisticas',
                  builder: (context, state) => const EstadisticasScreen(),
                ),
              ],
            ),

            // 04 Registros
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: registros,
                  name: 'registros',
                  builder: (context, state) => const HistorialScreen(),
                ),
              ],
            ),

            // 06 Perfil
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: perfil,
                  name: 'perfil',
                  builder: (context, state) => const PerfilScreen(),
                ),
              ],
            ),
          ],
        ),

        // 05 Alertas (Abre encima del shell con botón atrás "<")
        GoRoute(
          path: alertas,
          name: 'alertas',
          builder: (context, state) => const AlertasScreen(),
        ),
        GoRoute(
          path: '$alertaDetalle/:id',
          name: 'alertaDetalle',
          builder: (context, state) => DetalleAlertaScreen(alertaId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: asistente,
          name: 'asistente',
          builder: (context, state) => const AsistenteScreen(),
        ),

        // Sub-rutas de Formularios y Detalles (encima del shell)
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
          builder: (context, state) => AdminDashboardScreen(
            pestanaInicial: state.extra is int ? state.extra as int : 0,
          ),
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
          path: normatividad,
          name: 'normatividad',
          builder: (context, state) => NormatividadScreen(normaId: state.extra as String?),
        ),
      ],
    );
  }
}

class _ContenedorPrincipalShell extends InheritedWidget {
  final StatefulNavigationShell navigationShell;

  const _ContenedorPrincipalShell({
    required this.navigationShell,
  }) : super(
          child: const _VistaShellInterna(),
        );

  static _ContenedorPrincipalShell? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ContenedorPrincipalShell>();
  }

  @override
  bool updateShouldNotify(_ContenedorPrincipalShell oldWidget) {
    return navigationShell != oldWidget.navigationShell;
  }
}

class _VistaShellInterna extends StatelessWidget {
  const _VistaShellInterna();

  @override
  Widget build(BuildContext context) {
    final shell = _ContenedorPrincipalShell.of(context)!.navigationShell;

    return Scaffold(
      body: shell,
      bottomNavigationBar: BarraNavegacionInferior(
        indiceActual: shell.currentIndex,
        alSeleccionar: (index) {
          shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          );
        },
      ),
    );
  }
}
