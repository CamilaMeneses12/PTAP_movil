import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../domain/normatividad/normas_agua.dart';

/// Enlace "Ver norma" que abre la pantalla de Normatividad en la norma indicada.
class BotonVerNorma extends StatelessWidget {
  final String normaId;

  const BotonVerNorma({super.key, this.normaId = NormasAgua.res2115});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.push(AppRoutes.normatividad, extra: normaId),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppColors.azulPrimario,
      ),
      icon: const Icon(Icons.menu_book_outlined, size: 16),
      label: const Text('Ver norma', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
