import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../data/models/item_historial_modelo.dart';
import '../../../../data/models/umbral_alerta_modelo.dart';
import '../../../../data/models/usuario_perfil.dart';
import '../../../settings/providers/preferencias_provider.dart';
import '../../../settings/providers/umbrales_provider.dart';
import '../../providers/auth_provider.dart';

/// Piezas visuales compartidas por los tres perfiles (operario, administrador, consultor).

String inicialesDe(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) {
    return partes[0].substring(0, partes[0].length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
}

String formatoPorcentaje(double? valor) {
  if (valor == null) return '—';
  return '${NumberFormat('#,##0.#', 'es_CO').format(valor)} %';
}

class EstadisticaPerfil {
  final String valor;
  final String etiqueta;
  const EstadisticaPerfil(this.valor, this.etiqueta);
}

/// Tarjeta superior: avatar, nombre, chip de rol, planta y fila de estadísticas.
class EncabezadoPerfil extends StatelessWidget {
  final UsuarioPerfil perfil;
  final String textoRol;
  final Color colorRol;
  final Color fondoRol;
  final List<EstadisticaPerfil> estadisticas;

  const EncabezadoPerfil({
    super.key,
    required this.perfil,
    required this.textoRol,
    required this.colorRol,
    required this.fondoRol,
    required this.estadisticas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordes),
        boxShadow: AppColors.sombraSuave,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: fondoRol,
              shape: BoxShape.circle,
              border: Border.all(color: colorRol, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              inicialesDe(perfil.nombreCompleto),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colorRol),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            perfil.nombreCompleto,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
          ),
          const SizedBox(height: 8),
          Container(
            key: const Key('chip_rol'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: fondoRol, borderRadius: BorderRadius.circular(20)),
            child: Text(
              textoRol,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorRol),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.turquesa),
              const SizedBox(width: 4),
              Text(
                perfil.plantaNombre,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textoSecundario),
              ),
            ],
          ),
          if (estadisticas.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.fondoGeneral,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < estadisticas.length; i++) ...[
                    if (i > 0) Container(width: 1, height: 26, color: AppColors.bordes),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            estadisticas[i].valor,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textoPrincipal),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            estadisticas[i].etiqueta,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10, color: AppColors.textoSecundario),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Título en mayúsculas de cada sección, con acción opcional a la derecha.
class TituloSeccionPerfil extends StatelessWidget {
  final String texto;
  final String? textoAccion;
  final VoidCallback? alPulsarAccion;

  const TituloSeccionPerfil(this.texto, {super.key, this.textoAccion, this.alPulsarAccion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              texto.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textoSecundario,
                letterSpacing: 0.8,
              ),
            ),
          ),
          if (textoAccion != null)
            InkWell(
              onTap: alPulsarAccion,
              child: Text(
                textoAccion!,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.azulPrimario),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta blanca que agrupa filas separadas por divisores.
class TarjetaSeccionPerfil extends StatelessWidget {
  final List<Widget> hijos;
  const TarjetaSeccionPerfil({super.key, required this.hijos});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blanco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.bordes),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < hijos.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 52),
            hijos[i],
          ],
        ],
      ),
    );
  }
}

class FilaNavegacionPerfil extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? detalle;
  final Color color;
  final VoidCallback? alPulsar;

  const FilaNavegacionPerfil({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle,
    this.color = AppColors.textoSecundario,
    this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, size: 21, color: color == AppColors.textoSecundario ? AppColors.azulPrimario : color),
      title: Text(
        titulo,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color == AppColors.textoSecundario ? AppColors.textoPrincipal : color,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (detalle != null)
            Text(detalle!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textoSecundario)),
          if (alPulsar != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textoSecundario),
          ],
        ],
      ),
      onTap: alPulsar,
    );
  }
}

/// Interruptor ligado a una preferencia guardada en el dispositivo.
class SwitchPreferenciaPerfil extends StatelessWidget {
  final String clave;
  final String titulo;
  final String? subtitulo;
  final IconData icono;

  const SwitchPreferenciaPerfil({
    super.key,
    required this.clave,
    required this.titulo,
    required this.icono,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferenciasProvider>();
    return SwitchListTile(
      activeTrackColor: AppColors.turquesa,
      secondary: Icon(icono, color: AppColors.azulPrimario),
      title: Text(titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: subtitulo == null
          ? null
          : Text(subtitulo!, style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
      value: prefs.valor(clave),
      onChanged: (v) => prefs.cambiar(clave, v),
    );
  }
}

IconData _iconoUmbral(UmbralAlerta u) {
  switch (u.parametro) {
    case 'caudal_entrada':
      return Icons.arrow_downward_rounded;
    case 'nivel_tanque':
      return Icons.storage_rounded;
    case 'ph':
      return Icons.science_outlined;
    case 'cloro_residual':
      return Icons.sanitizer_outlined;
    case 'turbidez':
      return Icons.blur_on_rounded;
    default:
      return Icons.palette_outlined;
  }
}

/// Lista de umbrales de alerta. Solo el administrador puede editarlos.
class SeccionUmbralesPerfil extends StatelessWidget {
  final bool editable;
  const SeccionUmbralesPerfil({super.key, required this.editable});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UmbralesProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloSeccionPerfil(editable ? 'Umbrales de alerta · editables' : 'Umbrales de alerta · solo lectura'),
        if (prov.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(prov.error!, style: const TextStyle(fontSize: 11, color: AppColors.critico)),
          ),
        TarjetaSeccionPerfil(
          hijos: [
            for (final u in prov.umbrales)
              FilaNavegacionPerfil(
                key: Key('umbral_${u.clave}'),
                icono: _iconoUmbral(u),
                titulo: u.nombre,
                detalle: u.rangoTexto,
                alPulsar: editable ? () => _editar(context, u) : null,
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _editar(BuildContext context, UmbralAlerta u) async {
    final f = NumberFormat('#.##', 'es_CO');
    final minCtrl = TextEditingController(text: u.minimo == null ? '' : f.format(u.minimo));
    final maxCtrl = TextEditingController(text: u.maximo == null ? '' : f.format(u.maximo));
    final formato = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    double? leer(String t) => t.trim().isEmpty ? null : double.tryParse(t.trim().replaceAll(',', '.'));

    final resultado = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        String? error;
        var guardando = false;
        return StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            title: Text(u.nombre),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!u.soloMaximo)
                  TextField(
                    key: const Key('umbral_min'),
                    controller: minCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: formato,
                    decoration: InputDecoration(labelText: 'Mínimo', suffixText: u.unidad),
                  ),
                if (!u.soloMinimo) ...[
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('umbral_max'),
                    controller: maxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: formato,
                    decoration: InputDecoration(labelText: 'Máximo', suffixText: u.unidad),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(fontSize: 12, color: AppColors.critico)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: guardando
                    ? null
                    : () async {
                        final min = u.soloMaximo ? u.minimo : leer(minCtrl.text);
                        final max = u.soloMinimo ? null : leer(maxCtrl.text);
                        if ((!u.soloMaximo && min == null) || (!u.soloMinimo && max == null)) {
                          setStateDialog(() => error = 'Ingrese un número válido.');
                          return;
                        }
                        setStateDialog(() => guardando = true);
                        final msg = await ctx.read<UmbralesProvider>().actualizar(u, minimo: min, maximo: max);
                        if (!ctx.mounted) return;
                        if (msg != null) {
                          setStateDialog(() {
                            error = msg;
                            guardando = false;
                          });
                        } else {
                          Navigator.pop(ctx, 'ok');
                        }
                      },
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );
    minCtrl.dispose();
    maxCtrl.dispose();
    if (resultado == 'ok' && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Umbral de ${u.nombre} actualizado.')),
      );
    }
  }
}

/// Sección de cuenta común: seguridad, ayuda y cierre de sesión.
class SeccionCuentaPerfil extends StatelessWidget {
  const SeccionCuentaPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccionPerfil('Cuenta'),
        TarjetaSeccionPerfil(
          hijos: [
            FilaNavegacionPerfil(
              icono: Icons.lock_outline_rounded,
              titulo: 'Seguridad y configuración',
              alPulsar: () => context.push(AppRoutes.configuracion),
            ),
            FilaNavegacionPerfil(
              key: const Key('abrir_mcp'),
              icono: Icons.hub_outlined,
              titulo: 'Servidor MCP (asistentes de IA)',
              alPulsar: () => context.push(AppRoutes.mcp),
            ),
            FilaNavegacionPerfil(
              icono: Icons.help_outline_rounded,
              titulo: 'Centro de ayuda y soporte',
              alPulsar: () => context.push(AppRoutes.ayuda),
            ),
            FilaNavegacionPerfil(
              key: const Key('cerrar_sesion'),
              icono: Icons.logout_rounded,
              titulo: 'Cerrar sesión',
              color: AppColors.critico,
              alPulsar: () => _confirmarCerrarSesion(context),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'PTAP Monitor · Versión 1.0.0',
            style: TextStyle(fontSize: 10, color: AppColors.textoSecundario),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas salir de PTAP Monitor?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<SesionUsuarioProvider>().cerrarSesion();
              if (context.mounted) context.go(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.critico),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

/// Contenedor para secciones que dependen de datos remotos: carga, error o vacío.
class EstadoSeccionPerfil extends StatelessWidget {
  final bool cargando;
  final String? error;
  final bool vacio;
  final String textoVacio;
  final VoidCallback? alReintentar;
  final Widget hijo;

  const EstadoSeccionPerfil({
    super.key,
    required this.cargando,
    required this.error,
    required this.vacio,
    required this.textoVacio,
    required this.hijo,
    this.alReintentar,
  });

  @override
  Widget build(BuildContext context) {
    Widget caja(Widget contenido) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.blanco,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.bordes),
          ),
          child: contenido,
        );

    if (cargando) {
      return caja(const Center(
        child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
      ));
    }
    if (error != null) {
      return caja(Column(
        children: [
          Text(error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.critico)),
          if (alReintentar != null)
            TextButton.icon(
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
            ),
        ],
      ));
    }
    if (vacio) {
      return caja(Text(
        textoVacio,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
      ));
    }
    return hijo;
  }
}

/// Fila de un registro del historial, con chip si quedó fuera de rango.
class FilaRegistroPerfil extends StatelessWidget {
  final ItemHistorial item;
  final bool mostrarResponsable;

  const FilaRegistroPerfil({super.key, required this.item, this.mostrarResponsable = false});

  IconData get _icono {
    switch (item.tipo) {
      case TipoRegistroHistorial.medidores:
        return Icons.speed_outlined;
      case TipoRegistroHistorial.caudal:
        return Icons.waves_rounded;
      default:
        return Icons.science_outlined;
    }
  }

  void _abrir(BuildContext context) {
    switch (item.tipo) {
      case TipoRegistroHistorial.fisicoquimico:
        context.push(AppRoutes.fisicoquimicoDetalle, extra: item.objetoOriginal);
      case TipoRegistroHistorial.medidores:
        context.push(AppRoutes.medidoresDetalle, extra: item.objetoOriginal);
      case TipoRegistroHistorial.caudal:
        context.push(AppRoutes.caudalDetalle, extra: item.objetoOriginal);
      case TipoRegistroHistorial.todos:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat('dd/MM/yyyy').format(item.fecha);
    final linea = mostrarResponsable ? '${item.responsable} · $fecha ${item.hora}' : '$fecha · ${item.hora}';
    return ListTile(
      leading: Icon(_icono, size: 21, color: AppColors.azulPrimario),
      title: Text(
        item.titulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textoPrincipal),
      ),
      subtitle: Text(
        linea,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
      ),
      trailing: item.tieneAlerta
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.criticoFondo, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'Fuera de rango',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.critico),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textoSecundario),
      onTap: () => _abrir(context),
    );
  }
}

/// Barra horizontal de cumplimiento (verde ≥ 90 %, naranja ≥ 70 %, rojo por debajo).
class BarraCumplimientoPerfil extends StatelessWidget {
  final String nombre;
  final double? porcentaje;
  final String detalle;

  const BarraCumplimientoPerfil({super.key, required this.nombre, required this.porcentaje, required this.detalle});

  @override
  Widget build(BuildContext context) {
    final p = porcentaje;
    final color = p == null
        ? AppColors.textoSecundario
        : p >= 90
            ? AppColors.exito
            : p >= 70
                ? AppColors.advertencia
                : AppColors.critico;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textoPrincipal)),
              ),
              Text(formatoPorcentaje(p), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p == null ? 0 : p / 100,
              minHeight: 6,
              backgroundColor: AppColors.bordes,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(detalle, style: const TextStyle(fontSize: 10, color: AppColors.textoSecundario)),
        ],
      ),
    );
  }
}
