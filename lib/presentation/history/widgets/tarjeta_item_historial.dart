import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/item_historial_modelo.dart';

/// Tarjeta informativa para mostrar un registro individual en la lista de historial
class TarjetaItemHistorial extends StatelessWidget {
  final ItemHistorial item;

  const TarjetaItemHistorial({
    super.key,
    required this.item,
  });

  void _abrirDetalle(BuildContext context) {
    switch (item.tipo) {
      case TipoRegistroHistorial.fisicoquimico:
        context.push(AppRoutes.fisicoquimicoDetalle, extra: item.objetoOriginal);
        break;
      case TipoRegistroHistorial.medidores:
        context.push(AppRoutes.medidoresDetalle, extra: item.objetoOriginal);
        break;
      case TipoRegistroHistorial.caudal:
        context.push(AppRoutes.caudalDetalle, extra: item.objetoOriginal);
        break;
      case TipoRegistroHistorial.todos:
        break;
    }
  }

  Color _obtenerColorTipo() {
    switch (item.tipo) {
      case TipoRegistroHistorial.fisicoquimico:
        return AppColors.turquesa;
      case TipoRegistroHistorial.medidores:
        return AppColors.azulInstitucional;
      case TipoRegistroHistorial.caudal:
        return AppColors.azulTecnologico;
      case TipoRegistroHistorial.todos:
        return AppColors.azulMarino;
    }
  }

  IconData _obtenerIconoTipo() {
    switch (item.tipo) {
      case TipoRegistroHistorial.fisicoquimico:
        return Icons.science_outlined;
      case TipoRegistroHistorial.medidores:
        return Icons.speed_outlined;
      case TipoRegistroHistorial.caudal:
        return Icons.water_outlined;
      case TipoRegistroHistorial.todos:
        return Icons.list_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTipo = _obtenerColorTipo();
    final fechaFormateada = DateFormat('dd/MM/yyyy').format(item.fecha);

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.tieneAlerta
              ? AppColors.alerta.withAlpha(120)
              : AppColors.bordes,
          width: item.tieneAlerta ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _abrirDetalle(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Tipo, Fecha y Hora
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorTipo.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_obtenerIconoTipo(), size: 14, color: colorTipo),
                        const SizedBox(width: 4),
                        Text(
                          item.tipoTexto,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorTipo,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$fechaFormateada • ${item.hora}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Título y Chevron
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 4),

              // Subtítulo con valores clave
              Text(
                item.subtitulo,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textoSecundario,
                ),
              ),
              const SizedBox(height: 10),

              // Alerta destacada si aplica
              if (item.tieneAlerta && item.mensajeAlerta != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.alerta.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.alerta.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppColors.alerta),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.mensajeAlerta!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.alerta,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Pie: Responsable
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Operario: ${item.responsable}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
