import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _claveController = TextEditingController();
  final _confirmarClaveController = TextEditingController();

  bool _ocultarClave = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _claveController.dispose();
    _confirmarClaveController.dispose();
    super.dispose();
  }

  Future<void> _manejarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<SesionUsuarioProvider>();
    final exito = await authProvider.registrarUsuario(
      correo: _correoController.text.trim(),
      contrasena: _claveController.text,
      nombreCompleto: _nombreController.text.trim(),
    );

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('¡Cuenta creada con éxito! Bienvenido a PTAP.'),
            ],
          ),
          backgroundColor: AppColors.verdeAmbiental,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.go(AppRoutes.home);
    } else if (!exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.mensajeError ?? 'Error al crear la cuenta.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<SesionUsuarioProvider>();
    final cargando = authProvider.estado == EstadoAuth.cargando;

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      // SingleChildScrollView en la raíz del body para permitir desplazamiento vertical fluido
      // garantizando CERO desbordamientos (RenderFlex overflow) en cualquier resolución y con teclado activo.
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.bordes, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Crear Nueva Cuenta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Diligencia tus datos institucionales para acceder a la PTAP',
                          style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                        ),
                        const SizedBox(height: 18),

                        // Nombre Completo
                        TextFormField(
                          controller: _nombreController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingresa tu nombre completo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Correo Electrónico
                        TextFormField(
                          controller: _correoController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            hintText: 'ejemplo@sena.edu.co',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingresa tu correo institucional';
                            }
                            if (!v.contains('@')) {
                              return 'Ingresa un correo electrónico válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Rol fijo: toda cuenta nueva entra como operario.
                        const Text(
                          'Rol en la planta',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 8),

                        _TarjetaOpcionRol(
                          key: const Key('rol_operario_fijo'),
                          rol: 'operario',
                          titulo: AppStrings.rolOperario,
                          descripcion: 'Registra en campo y monitoreo de planta',
                          icono: Icons.engineering_outlined,
                          color: AppColors.azulInstitucional,
                          seleccionado: true,
                          onTap: () {},
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Las cuentas nuevas entran como Operario. Si necesitas otro rol, pídeselo a un administrador.',
                          style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                        ),
                        const SizedBox(height: 16),

                        // Contraseña
                        TextFormField(
                          controller: _claveController,
                          obscureText: _ocultarClave,
                          decoration: InputDecoration(
                            labelText: 'Contraseña (mínimo 6 caracteres)',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _ocultarClave
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() => _ocultarClave = !_ocultarClave);
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Confirmar contraseña
                        TextFormField(
                          controller: _confirmarClaveController,
                          obscureText: _ocultarClave,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                          validator: (v) {
                            if (v != _claveController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),

                        // Botón Registrar
                        ElevatedButton(
                          onPressed: cargando ? null : _manejarRegistro,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulInstitucional,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: cargando
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Registrar Cuenta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),

                        // Volver a Iniciar Sesión
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('¿Ya tienes cuenta? Iniciar Sesión'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta adaptativa para selección visual de rol sin desbordamiento
class _TarjetaOpcionRol extends StatelessWidget {
  final String rol;
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  const _TarjetaOpcionRol({
    super.key,
    required this.rol,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? color.withAlpha(20) : AppColors.blanco,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? color : AppColors.bordes,
            width: seleccionado ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: seleccionado ? color.withAlpha(35) : AppColors.fondoGeneral,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icono,
                size: 18,
                color: seleccionado ? color : AppColors.textoSecundario,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: seleccionado ? FontWeight.bold : FontWeight.w600,
                      color: seleccionado ? color : AppColors.textoPrincipal,
                    ),
                  ),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              seleccionado ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: seleccionado ? color : AppColors.bordes,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
