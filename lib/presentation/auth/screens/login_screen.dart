import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/usuario_perfil.dart';
import '../providers/auth_provider.dart';

/// Pantalla de inicio de sesión de PTAP diseñada con fidelidad visual a referencia.png
/// Incorpora el icono oficial login.png, ondas orgánicas decorativas,
/// tipografía institucional y tarjeta de acceso moderna y centrada.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _claveController = TextEditingController();
  bool _ocultarClave = true;

  @override
  void dispose() {
    _correoController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  Future<void> _manejarIngreso() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<SesionUsuarioProvider>();
    final exito = await authProvider.iniciarSesion(
      _correoController.text.trim(),
      _claveController.text,
    );

    if (!exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.mensajeError ?? 'Error de autenticación'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _iniciarModoDemo(String rol) {
    final authProvider = context.read<SesionUsuarioProvider>();
    String nombre = 'Carlos Gómez (Operario)';
    if (rol == 'administrador') nombre = 'Diego Calderón (Administrador)';
    if (rol == 'consultor_siga') nombre = 'Auditor SIGA (La Salada)';

    authProvider.establecerPerfilPrueba(
      UsuarioPerfil(
        id: 'demo-$rol',
        nombreCompleto: nombre,
        correo: 'demo.$rol@sena.edu.co',
        rol: rol,
        activo: true,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<SesionUsuarioProvider>();
    final cargando = authProvider.estado == EstadoAuth.cargando;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      body: Stack(
        children: [
          // 1. Fondo con ondas orgánicas en esquinas superior izquierda e inferior derecha (fiel a referencia.png)
          Positioned.fill(
            child: CustomPaint(
              painter: _OndasDecorativasPainter(),
            ),
          ),

          // 2. Contenido principal con scroll responsivo y centrado
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 410),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),

                            // Icono principal login.png ubicado encima del título
                            Center(
                              child: Image.asset(
                                'imagenes/login.png',
                                height: 88,
                                width: 88,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  'imagenes/login.jpeg',
                                  height: 88,
                                  width: 88,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Título institucional de la aplicación
                            const Text(
                              'PLANTA DE TRATAMIENTO\nDE AGUA POTABLE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF093970),
                                letterSpacing: 0.4,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Subtítulo institucional
                            const Text(
                              'Centro de los Recursos Naturales Renovables La Salada',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF5D7189),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Tarjeta blanca estilizada idéntica a referencia.png
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: const Color(0xFFE2EDF7), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0A3768).withAlpha(18),
                                    blurRadius: 30,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Iniciar Sesión',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF092E58),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Ingresa con tu correo institucional',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7E93),
                                      ),
                                    ),
                                    const SizedBox(height: 22),

                                    // Campo Correo institucional
                                    TextFormField(
                                      controller: _correoController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF1B365D)),
                                      decoration: InputDecoration(
                                        hintText: 'Correo institucional',
                                        hintStyle: const TextStyle(color: Color(0xFF8395A7), fontSize: 14),
                                        prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF0B58A2), size: 21),
                                        filled: true,
                                        fillColor: const Color(0xFFFCFDFF),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFFD4E2EE), width: 1.2),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFF0B58A2), width: 1.6),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
                                        ),
                                      ),
                                      validator: (valor) {
                                        if (valor == null || valor.trim().isEmpty) {
                                          return 'Ingresa tu correo institucional';
                                        }
                                        if (!valor.contains('@')) {
                                          return 'Ingresa un correo válido';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // Campo Contraseña
                                    TextFormField(
                                      controller: _claveController,
                                      obscureText: _ocultarClave,
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF1B365D)),
                                      decoration: InputDecoration(
                                        hintText: 'Contraseña',
                                        hintStyle: const TextStyle(color: Color(0xFF8395A7), fontSize: 14),
                                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF0B58A2), size: 21),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _ocultarClave ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                            color: const Color(0xFF5D7189),
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() => _ocultarClave = !_ocultarClave),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFFCFDFF),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFFD4E2EE), width: 1.2),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFF0B58A2), width: 1.6),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
                                        ),
                                      ),
                                      validator: (valor) {
                                        if (valor == null || valor.isEmpty) {
                                          return 'Ingresa tu contraseña';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Botón Iniciar Sesión (sólido azul profundo como referencia.png)
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: cargando ? null : _manejarIngreso,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF084C8D),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        child: cargando
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                              )
                                            : const Text(
                                                'Iniciar Sesión',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Enlace de texto: Crear nueva cuenta
                                    Center(
                                      child: TextButton(
                                        onPressed: () => context.push(AppRoutes.registro),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFF0B58A2),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        ),
                                        child: const Text(
                                          'Crear nueva cuenta',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0B58A2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Selector rápido de roles para pruebas en campo / demostración
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(220),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFDCE6F0)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Acceso rápido por rol (Demostración y Campo):',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6B7E93),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        _BotonRolDemo(
                                          titulo: 'Operario',
                                          color: AppColors.verdeAmbiental,
                                          icono: Icons.engineering_outlined,
                                          onTap: () => _iniciarModoDemo('operario'),
                                        ),
                                        _BotonRolDemo(
                                          titulo: 'Admin',
                                          color: AppColors.azulMarino,
                                          icono: Icons.admin_panel_settings_outlined,
                                          onTap: () => _iniciarModoDemo('administrador'),
                                        ),
                                        _BotonRolDemo(
                                          titulo: 'SIGA',
                                          color: AppColors.alerta,
                                          icono: Icons.verified_user_outlined,
                                          onTap: () => _iniciarModoDemo('consultor_siga'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Pintor de ondas orgánicas en esquinas superior izquierda e inferior derecha
/// reproduciendo exactamente el fondo estilizado de referencia.png
class _OndasDecorativasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fondo suave base
    final bgPaint = Paint()..color = const Color(0xFFF3F7FC);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Ondas superiores izquierdas
    // Capa 1: Externa suave
    final topPath1 = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h * 0.22)
      ..cubicTo(w * 0.08, h * 0.20, w * 0.22, h * 0.14, w * 0.38, 0)
      ..close();
    final topPaint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFB5DBFA), Color(0xFF89BFF5)],
      ).createShader(Rect.fromLTWH(0, 0, w * 0.4, h * 0.25))
      ..style = PaintingStyle.fill;
    canvas.drawPath(topPath1, topPaint1);

    // Capa 2: Intermedia
    final topPath2 = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h * 0.16)
      ..cubicTo(w * 0.05, h * 0.15, w * 0.16, h * 0.09, w * 0.27, 0)
      ..close();
    final topPaint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8CBFF5), Color(0xFF5E9DE8)],
      ).createShader(Rect.fromLTWH(0, 0, w * 0.3, h * 0.2))
      ..style = PaintingStyle.fill;
    canvas.drawPath(topPath2, topPaint2);

    // Capa 3: Profunda
    final topPath3 = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h * 0.10)
      ..cubicTo(w * 0.04, h * 0.09, w * 0.10, h * 0.05, w * 0.17, 0)
      ..close();
    final topPaint3 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF67A4EB), Color(0xFF4C8FE0)],
      ).createShader(Rect.fromLTWH(0, 0, w * 0.2, h * 0.12))
      ..style = PaintingStyle.fill;
    canvas.drawPath(topPath3, topPaint3);

    // Ondas inferiores derechas
    // Capa 1: Fondo suave
    final bottomPath1 = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.97)
      ..cubicTo(w * 0.25, h * 0.93, w * 0.45, h * 0.98, w * 0.68, h * 0.91)
      ..cubicTo(w * 0.84, h * 0.86, w * 0.94, h * 0.83, w, h * 0.81)
      ..lineTo(w, h)
      ..close();
    final bottomPaint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFFB5DBFA), Color(0xFF89BFF5)],
      ).createShader(Rect.fromLTWH(0, h * 0.78, w, h * 0.22))
      ..style = PaintingStyle.fill;
    canvas.drawPath(bottomPath1, bottomPaint1);

    // Capa 2: Intermedia
    final bottomPath2 = Path()
      ..moveTo(w * 0.15, h)
      ..cubicTo(w * 0.35, h * 0.95, w * 0.55, h * 0.97, w * 0.75, h * 0.91)
      ..cubicTo(w * 0.88, h * 0.87, w * 0.96, h * 0.85, w, h * 0.84)
      ..lineTo(w, h)
      ..close();
    final bottomPaint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF7CB3EF), Color(0xFF5A9AE6)],
      ).createShader(Rect.fromLTWH(0, h * 0.82, w, h * 0.18))
      ..style = PaintingStyle.fill;
    canvas.drawPath(bottomPath2, bottomPaint2);

    // Capa 3: Inferior intensa
    final bottomPath3 = Path()
      ..moveTo(w * 0.40, h)
      ..cubicTo(w * 0.60, h * 0.97, w * 0.80, h * 0.94, w, h * 0.89)
      ..lineTo(w, h)
      ..close();
    final bottomPaint3 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF5A9AE6), Color(0xFF3F85DC)],
      ).createShader(Rect.fromLTWH(w * 0.3, h * 0.88, w * 0.7, h * 0.12))
      ..style = PaintingStyle.fill;
    canvas.drawPath(bottomPath3, bottomPaint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BotonRolDemo extends StatelessWidget {
  final String titulo;
  final Color color;
  final IconData icono;
  final VoidCallback onTap;

  const _BotonRolDemo({
    required this.titulo,
    required this.color,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(70)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
