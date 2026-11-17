import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/usuario_perfil.dart';
import '../../auth/providers/auth_provider.dart';

/// Modelo ligero para representar submódulos autorizados dentro del Dashboard desplegable
class _ModuloItem {
  final String titulo;
  final String ruta;
  final IconData icono;
  final IconData iconoActivo;
  final List<String> rutasHijas;

  const _ModuloItem({
    required this.titulo,
    required this.ruta,
    required this.icono,
    required this.iconoActivo,
    this.rutasHijas = const [],
  });

  bool esActivo(String rutaActual) {
    if (rutaActual == ruta) return true;
    return rutasHijas.contains(rutaActual);
  }
}

/// Menú lateral desplegable unificado y elegante.
/// El Dashboard funciona como una sección desplegable (acordeón animado)
/// con los módulos autorizados para cada perfil, sin navegar a pantallas intermedias.
class AppDrawer extends StatefulWidget {
  final String rutaActual;

  const AppDrawer({
    super.key,
    required this.rutaActual,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> with SingleTickerProviderStateMixin {
  late bool _dashboardExpandido;

  @override
  void initState() {
    super.initState();
    // Si la ruta actual es uno de los submódulos del Dashboard, mantenerlo expandido
    final esSubmodulo = [
      AppRoutes.fisicoquimicos,
      AppRoutes.fisicoquimicoNuevo,
      AppRoutes.fisicoquimicoDetalle,
      AppRoutes.medidores,
      AppRoutes.medidoresNuevo,
      AppRoutes.medidoresDetalle,
      AppRoutes.caudal,
      AppRoutes.caudalNuevo,
      AppRoutes.caudalDetalle,
      AppRoutes.historial,
      AppRoutes.exportar,
    ].contains(widget.rutaActual);

    _dashboardExpandido = esSubmodulo;
  }

  void _navegar(BuildContext context, String ruta) {
    Navigator.of(context).pop(); // Cerrar el drawer suavemente
    if (widget.rutaActual != ruta) {
      context.go(ruta);
    }
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.error),
            SizedBox(width: 10),
            Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas salir del sistema de monitoreo PTAP?',
          style: TextStyle(fontSize: 14, color: AppColors.textoPrincipal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<SesionUsuarioProvider>().cerrarSesion();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  Color _obtenerColorRol(String rol) {
    // Identidad unificada basada en referencia.png para todos los perfiles
    return AppColors.azulTecnologico;
  }

  String _obtenerTextoRol(String rol) {
    switch (rol) {
      case 'administrador':
        return 'Administrador';
      case 'operario':
        return 'Operario PTAP';
      case 'consultor_siga':
        return 'Consultor SIGA';
      default:
        return rol;
    }
  }

  /// Retorna exclusivamente los módulos autorizados según el rol del perfil
  List<_ModuloItem> _obtenerModulosAutorizados(UsuarioPerfil? perfil) {
    final rol = perfil?.rol ?? 'operario';

    if (rol == 'administrador') {
      // 5 Módulos autorizados bajo el Dashboard del Administrador
      // (Administración y catálogos se coloca como opción independiente en el menú principal)
      return const [
        _ModuloItem(
          titulo: 'Parámetros fisicoquímicos',
          ruta: AppRoutes.fisicoquimicos,
          icono: Icons.science_outlined,
          iconoActivo: Icons.science,
          rutasHijas: [AppRoutes.fisicoquimicoNuevo, AppRoutes.fisicoquimicoDetalle],
        ),
        _ModuloItem(
          titulo: 'Lectura de medidores',
          ruta: AppRoutes.medidores,
          icono: Icons.speed_outlined,
          iconoActivo: Icons.speed,
          rutasHijas: [AppRoutes.medidoresNuevo, AppRoutes.medidoresDetalle],
        ),
        _ModuloItem(
          titulo: 'Caudal Quebrada La Seca',
          ruta: AppRoutes.caudal,
          icono: Icons.water_outlined,
          iconoActivo: Icons.water,
          rutasHijas: [AppRoutes.caudalNuevo, AppRoutes.caudalDetalle],
        ),
        _ModuloItem(
          titulo: 'Historial y filtros',
          ruta: AppRoutes.historial,
          icono: Icons.history_outlined,
          iconoActivo: Icons.history,
        ),
        _ModuloItem(
          titulo: 'Exportar reportes (PDF/Excel)',
          ruta: AppRoutes.exportar,
          icono: Icons.file_download_outlined,
          iconoActivo: Icons.file_download,
        ),
      ];
    } else if (rol == 'operario') {
      // Módulos operativos autorizados
      return const [
        _ModuloItem(
          titulo: 'Parámetros fisicoquímicos',
          ruta: AppRoutes.fisicoquimicos,
          icono: Icons.science_outlined,
          iconoActivo: Icons.science,
          rutasHijas: [AppRoutes.fisicoquimicoNuevo, AppRoutes.fisicoquimicoDetalle],
        ),
        _ModuloItem(
          titulo: 'Lectura de medidores',
          ruta: AppRoutes.medidores,
          icono: Icons.speed_outlined,
          iconoActivo: Icons.speed,
          rutasHijas: [AppRoutes.medidoresNuevo, AppRoutes.medidoresDetalle],
        ),
        _ModuloItem(
          titulo: 'Caudal Quebrada La Seca',
          ruta: AppRoutes.caudal,
          icono: Icons.water_outlined,
          iconoActivo: Icons.water,
          rutasHijas: [AppRoutes.caudalNuevo, AppRoutes.caudalDetalle],
        ),
        _ModuloItem(
          titulo: 'Historial y filtros',
          ruta: AppRoutes.historial,
          icono: Icons.history_outlined,
          iconoActivo: Icons.history,
        ),
      ];
    } else {
      // Consultor SIGA: solo consulta, auditoría y reportes
      return const [
        _ModuloItem(
          titulo: 'Historial y filtros',
          ruta: AppRoutes.historial,
          icono: Icons.history_outlined,
          iconoActivo: Icons.history,
        ),
        _ModuloItem(
          titulo: 'Exportar reportes (PDF/Excel)',
          ruta: AppRoutes.exportar,
          icono: Icons.file_download_outlined,
          iconoActivo: Icons.file_download,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<SesionUsuarioProvider>();
    final perfil = auth.perfil;
    final esAdmin = perfil?.esAdministrador ?? false;
    final rolColor = _obtenerColorRol(perfil?.rol ?? 'operario');
    final modulosAutorizados = _obtenerModulosAutorizados(perfil);

    // Verifica si la ruta actual es algún submódulo de los que están desplegados
    final estaEnSubmodulo = modulosAutorizados.any((m) => m.esActivo(widget.rutaActual));

    return Drawer(
      backgroundColor: AppColors.blanco,
      child: Column(
        children: [
          // 1. Encabezado institucional con perfil del usuario
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 18,
              left: 18,
              right: 18,
              bottom: 18,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.gradienteAzul,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withAlpha(40),
                      child: Text(
                        (perfil?.nombreCompleto.isNotEmpty ?? false)
                            ? perfil!.nombreCompleto.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blanco,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: rolColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _obtenerTextoRol(perfil?.rol ?? 'operario'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blanco,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  perfil?.nombreCompleto ?? 'Usuario del Sistema',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blanco,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  perfil?.correo ?? 'ptap.lasalada@sena.edu.co',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(200),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 2. Opciones de navegación con Dashboard como sección desplegable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                // Inicio
                _ItemDrawer(
                  icono: Icons.home_outlined,
                  iconoActivo: Icons.home,
                  titulo: 'Inicio',
                  activo: widget.rutaActual == AppRoutes.home,
                  onTap: () => _navegar(context, AppRoutes.home),
                ),
                const SizedBox(height: 2),

                // Dashboard ▼ (Categoría desplegable sin navegar a pantalla independiente)
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: (_dashboardExpandido || estaEnSubmodulo)
                        ? AppColors.azulClaro.withAlpha(60)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _dashboardExpandido = !_dashboardExpandido;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            (_dashboardExpandido || estaEnSubmodulo)
                                ? Icons.dashboard
                                : Icons.dashboard_outlined,
                            color: (_dashboardExpandido || estaEnSubmodulo)
                                ? AppColors.azulInstitucional
                                : AppColors.textoSecundario,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: (_dashboardExpandido || estaEnSubmodulo)
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: (_dashboardExpandido || estaEnSubmodulo)
                                    ? AppColors.azulInstitucional
                                    : AppColors.textoPrincipal,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _dashboardExpandido ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 220),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: (_dashboardExpandido || estaEnSubmodulo)
                                  ? AppColors.azulInstitucional
                                  : AppColors.textoSecundario,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Submódulos autorizados bajo el Dashboard con animación e indentación
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(left: 18, top: 4, bottom: 6),
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: AppColors.bordes,
                            width: 2,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: modulosAutorizados.map((modulo) {
                          final activo = modulo.esActivo(widget.rutaActual);
                          return _ItemSubmodulo(
                            modulo: modulo,
                            activo: activo,
                            onTap: () => _navegar(context, modulo.ruta),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  crossFadeState: _dashboardExpandido
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),

                // Opción INDEPENDIENTE: Administración y catálogos (Solo Administrador)
                if (esAdmin) ...[
                  const SizedBox(height: 2),
                  _ItemDrawer(
                    icono: Icons.admin_panel_settings_outlined,
                    iconoActivo: Icons.admin_panel_settings,
                    titulo: 'Administración y catálogos',
                    activo: widget.rutaActual == AppRoutes.admin,
                    onTap: () => _navegar(context, AppRoutes.admin),
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.bordes),
                ),

                // Mi Perfil
                _ItemDrawer(
                  icono: Icons.person_outline,
                  iconoActivo: Icons.person,
                  titulo: 'Mi Perfil',
                  activo: widget.rutaActual == AppRoutes.perfil,
                  onTap: () => _navegar(context, AppRoutes.perfil),
                ),

                // Configuración
                _ItemDrawer(
                  icono: Icons.settings_outlined,
                  iconoActivo: Icons.settings,
                  titulo: 'Configuración',
                  activo: widget.rutaActual == AppRoutes.configuracion,
                  onTap: () => _navegar(context, AppRoutes.configuracion),
                ),

                // Ayuda
                _ItemDrawer(
                  icono: Icons.help_outline,
                  iconoActivo: Icons.help,
                  titulo: 'Ayuda',
                  activo: widget.rutaActual == AppRoutes.ayuda,
                  onTap: () => _navegar(context, AppRoutes.ayuda),
                ),
              ],
            ),
          ),

          // 3. Pie: Cerrar Sesión
          const Divider(height: 1, color: AppColors.bordes),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: InkWell(
              onTap: () => _confirmarCerrarSesion(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.errorFondo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppColors.error),
                    SizedBox(width: 12),
                    Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Item principal del menú lateral
class _ItemDrawer extends StatelessWidget {
  final IconData icono;
  final IconData iconoActivo;
  final String titulo;
  final bool activo;
  final VoidCallback onTap;

  const _ItemDrawer({
    required this.icono,
    required this.iconoActivo,
    required this.titulo,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: activo ? AppColors.azulClaro : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        dense: true,
        leading: Icon(
          activo ? iconoActivo : icono,
          color: activo ? AppColors.azulInstitucional : AppColors.textoSecundario,
          size: 22,
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontSize: 14,
            fontWeight: activo ? FontWeight.bold : FontWeight.w500,
            color: activo ? AppColors.azulInstitucional : AppColors.textoPrincipal,
          ),
        ),
        trailing: activo
            ? Container(
                width: 5,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.azulInstitucional,
                  borderRadius: BorderRadius.circular(3),
                ),
              )
            : null,
      ),
    );
  }
}

/// Item de submódulo indentado dentro de la sección desplegable Dashboard
class _ItemSubmodulo extends StatelessWidget {
  final _ModuloItem modulo;
  final bool activo;
  final VoidCallback onTap;

  const _ItemSubmodulo({
    required this.modulo,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: activo ? AppColors.azulClaro : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: Icon(
          activo ? modulo.iconoActivo : modulo.icono,
          color: activo ? AppColors.azulInstitucional : AppColors.textoSecundario,
          size: 19,
        ),
        title: Text(
          modulo.titulo,
          style: TextStyle(
            fontSize: 13,
            fontWeight: activo ? FontWeight.bold : FontWeight.normal,
            color: activo ? AppColors.azulInstitucional : AppColors.textoPrincipal,
          ),
        ),
        trailing: activo
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.azulInstitucional,
                  shape: BoxShape.circle,
                ),
              )
            : const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.bordes),
      ),
    );
  }
}
