import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/asistente_provider.dart';

/// Herramientas que el servidor MCP ofrece según el rol (ver servidor_ia/src/mcp/herramientas.ts).
const _herramientas = [
  ('consultar_planta', 'Consultar información de la planta', {'operario', 'administrador', 'consultor_siga'}),
  ('consultar_parametros', 'Consultar parámetros y rangos', {'operario', 'administrador', 'consultor_siga'}),
  ('consultar_registros', 'Consultar registros', {'operario', 'administrador', 'consultor_siga'}),
  ('registrar_medicion', 'Registrar una medición', {'operario', 'administrador'}),
  ('anular_registro', 'Anular registro', {'operario', 'administrador'}),
  ('cambiar_estado_registro', 'Revisar o aprobar un registro', {'administrador'}),
];

/// Conexión de un asistente de IA (por ejemplo Claude Code) al servidor MCP de la planta:
/// dirección, token de 7 días y herramientas que puede usar según el rol.
class ConexionMcpScreen extends StatefulWidget {
  const ConexionMcpScreen({super.key});

  @override
  State<ConexionMcpScreen> createState() => _ConexionMcpScreenState();
}

class _ConexionMcpScreenState extends State<ConexionMcpScreen> {
  final _url = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _ocupado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = context.read<AsistenteProvider>();
    _url.text = a.urlServidor;
    a.cargar().then((_) {
      if (mounted && _url.text.isEmpty) _url.text = a.urlServidor;
    });
  }

  @override
  void dispose() {
    _url.dispose();
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(Future<String?> Function() accion) async {
    setState(() {
      _ocupado = true;
      _error = null;
    });
    final error = await accion();
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _error = error;
    });
  }

  Future<String?> _entrar() async {
    final a = context.read<AsistenteProvider>();
    if (_url.text.trim().isEmpty) return 'Escriba la dirección del servidor.';
    if (_url.text.trim() != a.urlServidor) await a.cambiarUrl(_url.text);
    final error = await a.entrar(_correo.text, _clave.text);
    if (error == null) _clave.clear();
    return error;
  }

  void _copiar(String texto, String que) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$que copiado')));
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AsistenteProvider>();
    final sesion = a.sesion;
    final token = a.tokenMcp;

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(title: const Text('Servidor MCP')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Conecte un asistente de IA (por ejemplo Claude Code) a los datos de la planta. '
            'El asistente usa las mismas reglas y permisos de su rol.',
            style: TextStyle(fontSize: 13, color: AppColors.textoSecundario, height: 1.4),
          ),
          const SizedBox(height: 14),

          // 1. Servidor y sesión
          _Tarjeta(
            titulo: '1. Servidor',
            icono: Icons.dns_outlined,
            children: [
              if (sesion == null) ...[
                TextField(
                  key: const Key('mcp_url'),
                  controller: _url,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Dirección del servidor',
                    hintText: 'http://192.168.1.20:3100',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('mcp_correo'),
                  controller: _correo,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo', isDense: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('mcp_clave'),
                  controller: _clave,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Clave', isDense: true),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('mcp_entrar'),
                    onPressed: _ocupado ? null : () => _ejecutar(_entrar),
                    child: const Text('Iniciar sesión en el servidor'),
                  ),
                ),
              ] else ...[
                _Dato('Servidor', a.urlServidor),
                _Dato('Sesión', '${sesion.nombre} (${sesion.rol})'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: a.salir, child: const Text('Cambiar de servidor o de usuario')),
                ),
              ],
            ],
          ),

          // 2. Dirección y token
          _Tarjeta(
            titulo: '2. Dirección y token',
            icono: Icons.key_outlined,
            children: [
              _Copiable(
                etiqueta: 'Dirección MCP',
                valor: a.urlMcp.isEmpty ? 'Escriba primero la dirección del servidor' : a.urlMcp,
                alCopiar: a.urlMcp.isEmpty ? null : () => _copiar(a.urlMcp, 'Dirección'),
              ),
              const SizedBox(height: 10),
              if (token == null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('mcp_generar_token'),
                    onPressed: (sesion == null || _ocupado) ? null : () => _ejecutar(a.generarTokenMcp),
                    icon: const Icon(Icons.vpn_key_outlined, size: 18),
                    label: Text(sesion == null ? 'Inicie sesión para generar el token' : 'Generar token MCP'),
                  ),
                )
              else ...[
                _Copiable(
                  key: const Key('mcp_token'),
                  etiqueta: 'Token (vence en ${token.vigencia})',
                  valor: token.token,
                  ocultar: true,
                  alCopiar: () => _copiar(token.token, 'Token'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'El token es una clave personal: no lo comparta. No se guarda en el celular; '
                  'si lo pierde, genere uno nuevo.',
                  style: TextStyle(fontSize: 11, color: AppColors.advertencia),
                ),
                const SizedBox(height: 10),
                _Copiable(
                  etiqueta: 'Comando para Claude Code',
                  valor: 'claude mcp add --transport http ptap ${a.urlMcp} '
                      '--header "Authorization: Bearer <token>"',
                  alCopiar: () => _copiar(
                    'claude mcp add --transport http ptap ${a.urlMcp} --header "Authorization: Bearer ${token.token}"',
                    'Comando',
                  ),
                ),
              ],
            ],
          ),

          // 3. Herramientas por rol
          _Tarjeta(
            titulo: '3. Herramientas disponibles',
            icono: Icons.build_outlined,
            children: [
              Text(
                sesion == null
                    ? 'Dependen del rol del usuario que genera el token.'
                    : 'Con el rol ${sesion.rol}, el asistente puede:',
                style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
              ),
              const SizedBox(height: 8),
              for (final (nombre, titulo, roles) in _herramientas)
                if (sesion == null || roles.contains(sesion.rol))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_rounded, size: 16, color: AppColors.exito),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: titulo,
                              style: const TextStyle(fontSize: 12, color: AppColors.textoPrincipal),
                              children: [
                                TextSpan(
                                  text: '  $nombre',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),

          if (_ocupado) const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_error!, key: const Key('mcp_error'), style: const TextStyle(color: AppColors.critico, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;

  const _Tarjeta({required this.titulo, required this.icono, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordes),
        boxShadow: AppColors.sombraSuave,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: AppColors.azulPrimario),
              const SizedBox(width: 8),
              Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  const _Dato(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          text: '$etiqueta: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
          children: [
            TextSpan(text: valor, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textoPrincipal)),
          ],
        ),
      ),
    );
  }
}

/// Valor con botón de copiar. Con [ocultar], solo se ven los primeros y últimos caracteres.
class _Copiable extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool ocultar;
  final VoidCallback? alCopiar;

  const _Copiable({super.key, required this.etiqueta, required this.valor, this.ocultar = false, this.alCopiar});

  @override
  Widget build(BuildContext context) {
    final visible = ocultar && valor.length > 16 ? '${valor.substring(0, 8)}…${valor.substring(valor.length - 6)}' : valor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
          decoration: BoxDecoration(color: AppColors.fondoGeneral, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  visible,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textoPrincipal),
                ),
              ),
              if (alCopiar != null)
                IconButton(
                  tooltip: 'Copiar',
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: alCopiar,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
