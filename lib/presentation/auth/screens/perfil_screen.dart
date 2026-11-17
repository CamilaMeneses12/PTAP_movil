import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../common/widgets/app_drawer.dart';
import '../providers/auth_provider.dart';

/// Pantalla moderna y elegante de perfil de usuario y permisos
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nombreController = TextEditingController();
  bool _editando = false;

  @override
  void initState() {
    super.initState();
    final perfil = context.read<SesionUsuarioProvider>().perfil;
    _nombreController.text = perfil?.nombreCompleto ?? '';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    final authProvider = context.read<SesionUsuarioProvider>();
    final nuevoNombre = _nombreController.text.trim();
    if (nuevoNombre.isEmpty) return;

    final exito = await authProvider.actualizarNombre(nuevoNombre);
    if (mounted) {
      if (exito) {
        setState(() => _editando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nombre actualizado con éxito.'),
            backgroundColor: AppColors.verdeAmbiental,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.mensajeError ?? 'Error al actualizar.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<SesionUsuarioProvider>();
    final perfil = authProvider.perfil;
    final rol = perfil?.rol ?? 'operario';

    String rolEtiqueta = AppStrings.rolOperario;
    const Color rolColor = AppColors.azulInstitucional;
    String descripcionPermisos =
        'Captura y edición de parámetros fisicoquímicos, lecturas de medidores y aforos de caudal en campo.';

    if (rol == 'administrador') {
      rolEtiqueta = AppStrings.rolAdmin;
      descripcionPermisos =
          'Control total del sistema: gestión de usuarios, catálogo de medidores, calibración de rangos y todos los registros.';
    } else if (rol == 'consultor_siga') {
      rolEtiqueta = AppStrings.rolConsultorSiga;
      descripcionPermisos =
          'Acceso de solo consulta, auditoría de procesos y exportación de reportes oficiales en PDF y Excel para el SIGA.';
    }

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      drawer: const AppDrawer(rutaActual: AppRoutes.perfil),
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            tooltip: 'Ir a Inicio',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Cabecera con avatar e insignia
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: rolColor.withAlpha(25),
                    child: Text(
                      (perfil?.nombreCompleto.isNotEmpty ?? false)
                          ? perfil!.nombreCompleto.substring(0, 1).toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: rolColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    perfil?.nombreCompleto ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: rolColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: rolColor.withAlpha(90)),
                    ),
                    child: Text(
                      'Rol: $rolEtiqueta',
                      style: TextStyle(
                        color: rolColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tarjeta de información personal
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.bordes, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Datos del Usuario',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _editando ? Icons.close : Icons.edit_outlined,
                            color: AppColors.azulInstitucional,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _editando = !_editando;
                              if (!_editando) {
                                _nombreController.text = perfil?.nombreCompleto ?? '';
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 16),

                    if (_editando) ...[
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.azulInstitucional),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulInstitucional,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Guardar Cambios'),
                        onPressed: _guardarCambios,
                      ),
                    ] else ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.azulClaro,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person_outline, color: AppColors.azulInstitucional, size: 20),
                        ),
                        title: const Text('Nombre completo', style: TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
                        subtitle: Text(
                          perfil?.nombreCompleto ?? 'No especificado',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textoPrincipal),
                        ),
                      ),
                    ],

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.azulClaro,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.email_outlined, color: AppColors.azulInstitucional, size: 20),
                      ),
                      title: const Text('Correo electrónico institucional', style: TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
                      subtitle: Text(
                        perfil?.correo ?? '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textoPrincipal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta de permisos del rol
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.bordes, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, color: rolColor, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Permisos y Alcance',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      descripcionPermisos,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textoSecundario,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ChipPermiso(
                          etiqueta: 'Crear Registros',
                          habilitado: perfil?.puedeEditar ?? false,
                        ),
                        _ChipPermiso(
                          etiqueta: 'Editar Propios',
                          habilitado: perfil?.puedeEditar ?? false,
                        ),
                        _ChipPermiso(
                          etiqueta: 'Consultar y Exportar',
                          habilitado: true,
                        ),
                        _ChipPermiso(
                          etiqueta: 'Administrar Catálogos',
                          habilitado: perfil?.puedeAdministrar ?? false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipPermiso extends StatelessWidget {
  final String etiqueta;
  final bool habilitado;

  const _ChipPermiso({
    required this.etiqueta,
    required this.habilitado,
  });

  @override
  Widget build(BuildContext context) {
    final color = habilitado ? AppColors.verdeAmbiental : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            habilitado ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
