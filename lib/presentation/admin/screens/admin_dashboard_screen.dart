import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/parametro_catalogo_modelo.dart';
import '../../../data/models/usuario_perfil.dart';
import '../../common/widgets/app_drawer.dart';
import '../providers/admin_provider.dart';

/// Panel principal de Administración: Usuarios, Catálogo de Medidores y Rangos Normativos
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.fondoGeneral,
        drawer: const AppDrawer(rutaActual: AppRoutes.admin),
        appBar: AppBar(
          title: const Text('Administración PTAP'),
          bottom: const TabBar(
            indicatorColor: AppColors.turquesa,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFB0C7D8),
            tabs: [
              Tab(icon: Icon(Icons.people_alt_outlined), text: 'Usuarios'),
              Tab(icon: Icon(Icons.speed_outlined), text: 'Medidores'),
              Tab(icon: Icon(Icons.tune_outlined), text: 'Rangos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PestanaUsuarios(),
            _PestanaMedidores(),
            _PestanaParametros(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PESTAÑA 1: GESTIÓN DE USUARIOS Y ROLES
// -----------------------------------------------------------------------------
class _PestanaUsuarios extends StatelessWidget {
  const _PestanaUsuarios();

  void _abrirDialogoCambiarRol(BuildContext context, UsuarioPerfil usuario) {
    String rolSeleccionado = usuario.rol;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Modificar Rol: ${usuario.nombreCompleto}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona el rol asignado en la planta:',
                style: TextStyle(fontSize: 13, color: AppColors.textoSecundario),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: rolSeleccionado,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'operario', child: Text('Operario (Captura y edición)')),
                  DropdownMenuItem(value: 'administrador', child: Text('Administrador (Acceso total)')),
                  DropdownMenuItem(value: 'consultor_siga', child: Text('Consultor SIGA (Solo consulta)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => rolSeleccionado = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulInstitucional,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                context.read<AdminProvider>().cambiarRolUsuario(usuario.id, rolSeleccionado);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rol de usuario actualizado')),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    if (provider.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.usuarios.length,
      itemBuilder: (context, index) {
        final u = provider.usuarios[index];
        final colorRol = _obtenerColorRol(u.rol);

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorRol.withAlpha(30),
                  child: Icon(Icons.person, color: colorRol),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.nombreCompleto,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        u.correo,
                        style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorRol.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _obtenerTextoRol(u.rol),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorRol,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cambiar rol',
                  icon: const Icon(Icons.manage_accounts_outlined, color: AppColors.azulMarino),
                  onPressed: () => _abrirDialogoCambiarRol(context, u),
                ),
                Switch(
                  activeThumbColor: AppColors.azulInstitucional,
                  value: u.activo,
                  onChanged: (_) => provider.toggleEstadoUsuario(u.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// PESTAÑA 2: CATÁLOGO DE MEDIDORES (8 MICROS + MACRO)
// -----------------------------------------------------------------------------
class _PestanaMedidores extends StatelessWidget {
  const _PestanaMedidores();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          color: AppColors.azulClaro,
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: AppColors.azulInstitucional),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Catálogo oficial de los 9 medidores del formato Excel. Activa o desactiva medidores según mantenimiento.',
                  style: TextStyle(fontSize: 12, color: AppColors.textoPrincipal),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.medidores.length,
            itemBuilder: (context, index) {
              final m = provider.medidores[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: m.esMacro ? AppColors.azulInstitucional.withAlpha(100) : AppColors.bordes,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: m.esMacro ? AppColors.azulInstitucional : AppColors.azulTecnologico,
                    foregroundColor: Colors.white,
                    child: Text('${m.orden}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(
                    m.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Código: ${m.codigo} | Tipo: ${m.esMacro ? "Macromedidor General" : "Micromedidor"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Switch(
                    activeThumbColor: AppColors.azulInstitucional,
                    value: m.activo,
                    onChanged: (_) => provider.toggleEstadoMedidor(m.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// PESTAÑA 3: PARÁMETROS Y RANGOS NORMATIVOS (RES. 2115)
// -----------------------------------------------------------------------------
class _PestanaParametros extends StatelessWidget {
  const _PestanaParametros();

  void _abrirDialogoEditarRango(BuildContext context, ParametroCatalogo parametro) {
    final minCtrl = TextEditingController(text: parametro.valorMin.toString());
    final maxCtrl = TextEditingController(text: parametro.valorMax.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Rangos: ${parametro.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unidad: ${parametro.unidad}\nReferencia: ${parametro.normaReferencia}',
              style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Mínimo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Máximo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulInstitucional,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final min = double.tryParse(minCtrl.text) ?? parametro.valorMin;
              final max = double.tryParse(maxCtrl.text) ?? parametro.valorMax;
              context.read<AdminProvider>().actualizarRangoParametro(parametro.id, min, max);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rangos normativos actualizados')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          color: AppColors.alerta.withAlpha(20),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.alerta),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Límites permitidos según Resolución 2115 de 2007. Si un valor ingresado en campo queda fuera, generará una alerta visual.',
                  style: TextStyle(fontSize: 12, color: AppColors.textoPrincipal),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.parametros.length,
            itemBuilder: (context, index) {
              final p = provider.parametros[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.bordes),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.azulMarino,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.science, size: 20),
                  ),
                  title: Text(
                    p.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Rango: ${p.valorMin} - ${p.valorMax} ${p.unidad}\n${p.normaReferencia}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.azulTecnologico),
                    onPressed: () => _abrirDialogoEditarRango(context, p),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
