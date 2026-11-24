import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/modelo_celular_service.dart';
import '../../../domain/asistente/asistente_logica.dart';
import '../../auth/providers/auth_provider.dart';
import '../../history/providers/historial_provider.dart';
import '../../settings/providers/umbrales_provider.dart';
import '../providers/asistente_provider.dart';

/// Chat del Asistente PTAP: en línea (servidor con nube + modelo local) o dentro del celular.
class AsistenteScreen extends StatefulWidget {
  const AsistenteScreen({super.key});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  final _texto = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AsistenteProvider>().cargar();
      final historial = context.read<HistorialProvider>();
      if (historial.todosLosItems.isEmpty && !historial.cargando) historial.cargarHistorial();
    });
  }

  @override
  void dispose() {
    _texto.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _texto.text;
    if (texto.trim().isEmpty) return;
    _texto.clear();
    final asistente = context.read<AsistenteProvider>();
    final envio = asistente.enviar(
      texto,
      perfil: context.read<SesionUsuarioProvider>().perfil,
      registros: context.read<HistorialProvider>().todosLosItems,
      umbrales: context.read<UmbralesProvider>().umbrales,
    );
    _bajar();
    await envio;
    _bajar();
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AsistenteProvider>();
    final necesitaServidor = a.modo == ModoAsistente.enLinea && a.sesion == null;
    final necesitaModelo = a.modo == ModoAsistente.enCelular && !a.modeloInstalado;
    final autoSinNada = a.modo == ModoAsistente.automatico && a.sesion == null && !a.modeloInstalado;

    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        backgroundColor: AppColors.azulMarino,
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: const Text('Asistente PTAP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Borrar conversación',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: a.mensajes.isEmpty ? null : a.limpiarConversacion,
          ),
          IconButton(
            key: const Key('ajustes_asistente'),
            tooltip: 'Servidor y modelo',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _mostrarAjustes(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.blanco,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ModoAsistente>(
                    key: const Key('selector_modo'),
                    segments: const [
                      ButtonSegment(value: ModoAsistente.automatico, label: Text('Automático'), icon: Icon(Icons.auto_mode_rounded, size: 16)),
                      ButtonSegment(value: ModoAsistente.enLinea, label: Text('En línea'), icon: Icon(Icons.cloud_outlined, size: 16)),
                      ButtonSegment(value: ModoAsistente.enCelular, label: Text('Celular'), icon: Icon(Icons.phone_android_rounded, size: 16)),
                    ],
                    selected: {a.modo},
                    showSelectedIcon: false,
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    onSelectionChanged: (s) => a.cambiarModo(s.first),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Estado(
                      ok: a.sesion != null && a.servidorDisponible == true,
                      texto: a.sesion != null
                          ? (a.servidorDisponible == true ? 'Servidor: ${a.sesion!.nombre}' : 'Servidor sin conexión')
                          : 'Servidor: sin sesión',
                    ),
                    const SizedBox(width: 8),
                    _Estado(
                      ok: a.modeloInstalado,
                      texto: a.modeloInstalado ? 'Modelo del celular listo' : 'Modelo del celular no descargado',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tarjetas y conversación en una sola lista: en pantallas pequeñas o con el teclado abierto se desplaza.
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                if (necesitaServidor || autoSinNada) _TarjetaServidor(compacta: autoSinNada),
                if (necesitaModelo || autoSinNada) const _TarjetaModelo(),
                if (a.mensajes.isEmpty)
                  const _Bienvenida()
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Column(children: [for (final m in a.mensajes) _Burbuja(mensaje: m)]),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: AppColors.blanco,
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('campo_pregunta'),
                      controller: _texto,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(),
                      decoration: const InputDecoration(hintText: 'Pregunte sobre la planta o sus registros', counterText: '', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    key: const Key('enviar_pregunta'),
                    onPressed: a.enviando ? null : _enviar,
                    icon: a.enviando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarAjustes(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blanco,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Servidor y modelo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              SizedBox(height: 12),
              _TarjetaServidor(compacta: false, mostrarSiempre: true),
              _TarjetaModelo(mostrarSiempre: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _Estado extends StatelessWidget {
  final bool ok;
  final String texto;
  const _Estado({required this.ok, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 14, color: ok ? AppColors.exito : AppColors.textoSecundario),
          const SizedBox(width: 4),
          Expanded(
            child: Text(texto,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
          ),
        ],
      ),
    );
  }
}

class _Bienvenida extends StatelessWidget {
  const _Bienvenida();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined, size: 48, color: AppColors.azulPrimario),
            SizedBox(height: 12),
            Text('Pregúnteme por los rangos normativos o por sus registros', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textoPrincipal)),
            SizedBox(height: 6),
            Text(
              'Ej.: "¿Mi último registro tiene algo fuera de rango?" o "¿Cuál es el rango del cloro residual?"\n'
              'Solo verá los registros que su rol le permite consultar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  final MensajeAsistente mensaje;
  const _Burbuja({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final propio = mensaje.esUsuario;
    final color = propio ? AppColors.azulPrimario : (mensaje.error ? AppColors.criticoFondo : AppColors.blanco);
    final tinta = propio ? Colors.white : (mensaje.error ? AppColors.critico : AppColors.textoPrincipal);
    return Align(
      alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: propio ? null : Border.all(color: AppColors.bordes),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mensaje.escribiendo && mensaje.texto.isEmpty)
              const Text('Pensando…', style: TextStyle(fontSize: 13, color: AppColors.textoSecundario, fontStyle: FontStyle.italic))
            else
              SelectableText(mensaje.texto, style: TextStyle(fontSize: 14, color: tinta, height: 1.35)),
            if (mensaje.fuente != null) ...[
              const SizedBox(height: 4),
              Text(mensaje.fuente!, style: const TextStyle(fontSize: 10, color: AppColors.textoSecundario)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Conexión con el servidor del asistente (servidor_ia en el PC de la planta).
class _TarjetaServidor extends StatefulWidget {
  final bool compacta;
  final bool mostrarSiempre;
  const _TarjetaServidor({required this.compacta, this.mostrarSiempre = false});

  @override
  State<_TarjetaServidor> createState() => _TarjetaServidorState();
}

class _TarjetaServidorState extends State<_TarjetaServidor> {
  final _url = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  String? _error;
  bool _entrando = false;

  @override
  void initState() {
    super.initState();
    _url.text = context.read<AsistenteProvider>().urlServidor;
    _correo.text = context.read<SesionUsuarioProvider>().perfil?.correo ?? '';
  }

  @override
  void dispose() {
    _url.dispose();
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final a = context.read<AsistenteProvider>();
    setState(() {
      _entrando = true;
      _error = null;
    });
    if (_url.text.trim() != a.urlServidor) await a.cambiarUrl(_url.text);
    final error = await a.entrar(_correo.text, _clave.text);
    if (!mounted) return;
    setState(() {
      _entrando = false;
      _error = error;
    });
    if (error == null) _clave.clear();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AsistenteProvider>();
    if (a.sesion != null) {
      if (!widget.mostrarSiempre) return const SizedBox.shrink();
      return _Caja(
        icono: Icons.dns_outlined,
        titulo: 'Servidor del asistente',
        hijos: [
          Text('${a.urlServidor}\nSesión: ${a.sesion!.nombre} (${a.sesion!.rol})', style: const TextStyle(fontSize: 12)),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: a.salir, child: const Text('Cerrar sesión del asistente'))),
        ],
      );
    }
    return _Caja(
      icono: Icons.dns_outlined,
      titulo: widget.compacta ? 'Usar el servidor (nube + modelo local)' : 'Conectarse al servidor del asistente',
      hijos: [
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'Dirección del servidor', hintText: 'http://192.168.1.20:3100', isDense: true),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _correo,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Correo', isDense: true),
        ),
        const SizedBox(height: 8),
        TextField(controller: _clave, obscureText: true, decoration: const InputDecoration(labelText: 'Clave del asistente', isDense: true)),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.critico))),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            key: const Key('entrar_asistente'),
            onPressed: _entrando ? null : _entrar,
            child: Text(_entrando ? 'Conectando…' : 'Entrar'),
          ),
        ),
      ],
    );
  }
}

/// Descarga del modelo que corre dentro del celular.
class _TarjetaModelo extends StatelessWidget {
  final bool mostrarSiempre;
  const _TarjetaModelo({this.mostrarSiempre = false});

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AsistenteProvider>();
    if (a.modeloInstalado && !mostrarSiempre) return const SizedBox.shrink();
    return _Caja(
      icono: Icons.phone_android_rounded,
      titulo: 'Modelo dentro del celular (${ModeloCelularService.nombre})',
      hijos: [
        Text(
          a.modeloInstalado
              ? 'Descargado. Responde sin internet con los registros guardados en este celular.'
              : 'Descárguelo una sola vez (unos 0,5 GB, con Wi-Fi). Después responde sin internet.',
          style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
        ),
        if (a.descargando) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: a.progresoDescarga / 100),
          Text('${a.progresoDescarga} %', style: const TextStyle(fontSize: 11)),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: a.modeloInstalado
              ? TextButton(onPressed: a.eliminarModelo, child: const Text('Eliminar del celular'))
              : ElevatedButton.icon(
                  key: const Key('descargar_modelo'),
                  onPressed: a.descargando
                      ? null
                      : () async {
                          final error = await a.descargarModelo();
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                          }
                        },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(a.descargando ? 'Descargando…' : 'Descargar modelo'),
                ),
        ),
      ],
    );
  }
}

class _Caja extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final List<Widget> hijos;
  const _Caja({required this.icono, required this.titulo, required this.hijos});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordes),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(icono, size: 18, color: AppColors.azulPrimario),
            const SizedBox(width: 6),
            Expanded(child: Text(titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 8),
          ...hijos,
        ],
      ),
    );
  }
}
