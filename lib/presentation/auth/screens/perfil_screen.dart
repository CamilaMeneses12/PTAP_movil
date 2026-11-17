import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _notificacionesPush = true;
  bool _alertasSms = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<SesionUsuarioProvider>();
    final perfil = authProvider.perfil;
    final esAdmin = perfil?.esAdministrador ?? false;
    final nombre = perfil?.nombreCompleto ?? 'Andrea Ríos';

    // Iniciales
    final partes = nombre.trim().split(' ');
    String iniciales = 'AR';
    if (partes.length >= 2) {
      iniciales = '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    } else if (partes.isNotEmpty && partes[0].isNotEmpty) {
      iniciales = partes[0].substring(0, partes[0].length >= 2 ? 2 : 1).toUpperCase();
    }

    String rolTexto = 'Operadora de planta · Turno A';
    if (perfil?.esAdministrador ?? false) {
      rolTexto = 'Administrador general del sistema';
    } else if (perfil?.esConsultorSiga ?? false) {
      rolTexto = 'Consultor de auditoría SIGA';
    }

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        backgroundColor: AppColors.fondoGeneral,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Perfil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textoPrincipal,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Tarjeta de información del usuario
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.blanco,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.bordes),
                boxShadow: AppColors.sombraSuave,
              ),
              child: Column(
                children: [
                  // Avatar circular grande con iniciales
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.azulClaro,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.turquesa, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      iniciales,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.azulMarino,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nombre
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Rol
                  Text(
                    rolTexto,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Ubicación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.turquesa),
                      const SizedBox(width: 4),
                      Text(
                        perfil?.plantaNombre ?? 'PTAP Villa Clara',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Fila de 3 estadísticas del usuario
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.fondoGeneral,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ItemEstadisticaPerfil(
                          valor: '18',
                          label: 'Turnos este mes',
                        ),
                        Container(width: 1, height: 26, color: AppColors.bordes),
                        _ItemEstadisticaPerfil(
                          valor: '42',
                          label: 'Alertas atendidas',
                        ),
                        Container(width: 1, height: 26, color: AppColors.bordes),
                        _ItemEstadisticaPerfil(
                          valor: '3 años',
                          label: 'En la planta',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sección: UMBRALES DE ALERTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'UMBRALES DE ALERTA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textoSecundario,
                    letterSpacing: 0.8,
                  ),
                ),
                if (esAdmin)
                  InkWell(
                    onTap: () => context.push(AppRoutes.admin),
                    child: const Text(
                      'Editar límites',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.azulPrimario,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AppColors.blanco,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.bordes),
              ),
              child: Column(
                children: [
                  _FilaUmbralAlerta(
                    icono: Icons.arrow_downward_rounded,
                    titulo: 'Caudal de entrada',
                    rango: '110–140 L/s',
                    esAdmin: esAdmin,
                    alEditar: () => _editarUmbral(context, 'Caudal de entrada', '110–140 L/s'),
                  ),
                  const Divider(height: 1, indent: 48),
                  _FilaUmbralAlerta(
                    icono: Icons.arrow_upward_rounded,
                    titulo: 'Caudal de salida',
                    rango: '105–135 L/s',
                    esAdmin: esAdmin,
                    alEditar: () => _editarUmbral(context, 'Caudal de salida', '105–135 L/s'),
                  ),
                  const Divider(height: 1, indent: 48),
                  _FilaUmbralAlerta(
                    icono: Icons.speed_rounded,
                    titulo: 'Presión de red',
                    rango: '2,8–4,0 bar',
                    esAdmin: esAdmin,
                    alEditar: () => _editarUmbral(context, 'Presión de red', '2,8–4,0 bar'),
                  ),
                  const Divider(height: 1, indent: 48),
                  _FilaUmbralAlerta(
                    icono: Icons.water_rounded,
                    titulo: 'Nivel mínimo de tanque',
                    rango: '40 %',
                    esAdmin: esAdmin,
                    alEditar: () => _editarUmbral(context, 'Nivel mínimo de tanque', '40 %'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sección: PREFERENCIAS
            const Text(
              'PREFERENCIAS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textoSecundario,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AppColors.blanco,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.bordes),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeTrackColor: AppColors.turquesa,
                    secondary: const Icon(Icons.notifications_none_rounded, color: AppColors.textoSecundario),
                    title: const Text('Notificaciones push', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    value: _notificacionesPush,
                    onChanged: (val) => setState(() => _notificacionesPush = val),
                  ),
                  const Divider(height: 1, indent: 48),
                  SwitchListTile(
                    activeTrackColor: AppColors.turquesa,
                    secondary: const Icon(Icons.sms_outlined, color: AppColors.textoSecundario),
                    title: const Text('Alertas críticas por SMS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    value: _alertasSms,
                    onChanged: (val) => setState(() => _alertasSms = val),
                  ),
                  const Divider(height: 1, indent: 48),
                  ListTile(
                    leading: const Icon(Icons.straighten_rounded, color: AppColors.textoSecundario),
                    title: const Text('Unidades de medida', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('L/s · m³ · bar', style: TextStyle(fontSize: 12, color: AppColors.textoSecundario)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textoSecundario),
                      ],
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sección: CUENTA
            const Text(
              'CUENTA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textoSecundario,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AppColors.blanco,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.bordes),
              ),
              child: Column(
                children: [
                  if (esAdmin) ...[
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.azulPrimario),
                      title: const Text(
                        'Panel de Administración',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.azulMarino),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textoSecundario),
                      onTap: () => context.push(AppRoutes.admin),
                    ),
                    const Divider(height: 1, indent: 48),
                  ],
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded, color: AppColors.textoSecundario),
                    title: const Text('Seguridad y contraseña', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textoSecundario),
                    onTap: () => context.push(AppRoutes.configuracion),
                  ),
                  const Divider(height: 1, indent: 48),
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded, color: AppColors.textoSecundario),
                    title: const Text('Centro de ayuda y soporte', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textoSecundario),
                    onTap: () => context.push(AppRoutes.ayuda),
                  ),
                  const Divider(height: 1, indent: 48),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.critico),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.critico),
                    ),
                    onTap: () => _confirmarCerrarSesion(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Versión institucional al pie
            const Center(
              child: Text(
                'PTAP Monitor · Versión 1.0.0 · SENA Centro de Gestión Agroempresarial',
                style: TextStyle(fontSize: 10, color: AppColors.textoSecundario),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _editarUmbral(BuildContext context, String parametro, String rangoActual) {
    final perfil = context.read<SesionUsuarioProvider>().perfil;
    if (!(perfil?.esAdministrador ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo el Administrador puede modificar los umbrales de alerta normativos.')),
      );
      return;
    }
    context.push(AppRoutes.admin);
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas salir de PTAP Monitor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<SesionUsuarioProvider>().cerrarSesion();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.critico),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _ItemEstadisticaPerfil extends StatelessWidget {
  final String valor;
  final String label;

  const _ItemEstadisticaPerfil({required this.valor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textoPrincipal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textoSecundario,
          ),
        ),
      ],
    );
  }
}

class _FilaUmbralAlerta extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String rango;
  final bool esAdmin;
  final VoidCallback alEditar;

  const _FilaUmbralAlerta({
    required this.icono,
    required this.titulo,
    required this.rango,
    required this.esAdmin,
    required this.alEditar,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, size: 20, color: AppColors.azulPrimario),
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textoPrincipal),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rango,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textoSecundario),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textoSecundario),
        ],
      ),
      onTap: alEditar,
    );
  }
}
