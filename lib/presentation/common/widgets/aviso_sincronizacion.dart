import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/sincronizacion_provider.dart';

/// Aviso de registros guardados en el celular que aún no se suben a Supabase.
/// No muestra nada si todo está sincronizado.
class AvisoSincronizacion extends StatelessWidget {
  const AvisoSincronizacion({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SincronizacionProvider?>();
    if (sync == null) return const SizedBox.shrink();

    if (sync.modoLocal) {
      return const _Caja(
        color: AppColors.informacion,
        fondo: AppColors.informacionFondo,
        icono: Icons.phone_android_rounded,
        texto: 'Modo local: los registros se guardan solo en este celular.',
      );
    }
    if (sync.pendientes == 0) return const SizedBox.shrink();

    final n = sync.pendientes;
    return _Caja(
      key: const Key('aviso_pendientes'),
      color: AppColors.advertencia,
      fondo: AppColors.advertenciaFondo,
      icono: Icons.cloud_off_rounded,
      texto: '$n ${n == 1 ? 'registro guardado' : 'registros guardados'} en el celular sin subir. '
          'Se suben solos cuando vuelve la conexión.',
      detalle: sync.ultimoError == null ? null : 'Último intento: ${sync.ultimoError}',
      accion: sync.sincronizando
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : TextButton(
              key: const Key('sincronizar_ahora'),
              onPressed: sync.sincronizar,
              child: const Text('Sincronizar ahora', style: TextStyle(fontSize: 12)),
            ),
    );
  }
}

class _Caja extends StatelessWidget {
  final Color color;
  final Color fondo;
  final IconData icono;
  final String texto;
  final String? detalle;
  final Widget? accion;

  const _Caja({super.key, required this.color, required this.fondo, required this.icono, required this.texto, this.detalle, this.accion});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texto, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                if (detalle != null)
                  Text(
                    detalle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.textoSecundario),
                  ),
              ],
            ),
          ),
          ?accion,
        ],
      ),
    );
  }
}
