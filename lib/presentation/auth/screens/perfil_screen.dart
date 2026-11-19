import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../admin/providers/admin_provider.dart';
import '../../history/providers/historial_provider.dart';
import '../../settings/providers/umbrales_provider.dart';
import '../providers/auth_provider.dart';
import 'perfil/perfil_administrador_view.dart';
import 'perfil/perfil_consultor_view.dart';
import 'perfil/perfil_operario_view.dart';

/// Pestaña Perfil: muestra una vista distinta según el rol del usuario.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar(soloSiFalta: true));
  }

  Future<void> _cargar({bool soloSiFalta = false}) async {
    if (!mounted) return;
    final historial = context.read<HistorialProvider>();
    final umbrales = context.read<UmbralesProvider>();
    final perfil = context.read<SesionUsuarioProvider>().perfil;
    final tareas = <Future<void>>[];

    if (!soloSiFalta || (historial.todosLosItems.isEmpty && !historial.cargando)) {
      tareas.add(historial.cargarHistorial());
    }
    if (!soloSiFalta) tareas.add(umbrales.cargar());
    if (perfil?.esAdministrador ?? false) {
      final admin = context.read<AdminProvider>();
      if (!soloSiFalta || admin.usuarios.isEmpty) tareas.add(admin.cargarTodo());
    }
    await Future.wait(tareas);
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<SesionUsuarioProvider>().perfil;

    final Widget contenido;
    if (perfil == null) {
      contenido = const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: Text('No hay una sesión activa.')),
      );
    } else if (perfil.esAdministrador) {
      contenido = PerfilAdministradorView(perfil: perfil);
    } else if (perfil.esConsultorSiga) {
      contenido = PerfilConsultorView(perfil: perfil);
    } else {
      contenido = PerfilOperarioView(perfil: perfil);
    }

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        backgroundColor: AppColors.fondoGeneral,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
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
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [contenido],
          ),
        ),
      ),
    );
  }
}
