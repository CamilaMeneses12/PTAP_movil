import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Configuración de tema global unificado para PTAP Monitor – Fiel al Figma
class AppTheme {
  static ThemeData get temaClaro {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto', // Modern sans-serif default on Flutter/Android
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.azulPrimario,
        primary: AppColors.azulPrimario,
        onPrimary: AppColors.blanco,
        secondary: AppColors.turquesa,
        onSecondary: AppColors.blanco,
        tertiary: AppColors.azulMarino,
        surface: AppColors.blanco,
        onSurface: AppColors.textoPrincipal,
        error: AppColors.critico,
        onError: AppColors.blanco,
      ),
      scaffoldBackgroundColor: AppColors.fondoGeneral,

      // Tipografía institucional de alta legibilidad
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 14,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textoSecundario,
          fontSize: 13,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Barra superior institucional
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fondoGeneral,
        foregroundColor: AppColors.textoPrincipal,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textoPrincipal,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.textoPrincipal),
      ),

      // Botones principales (Radio 12-14, azul primario)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azulPrimario,
          foregroundColor: AppColors.blanco,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Botones con contorno
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.azulPrimario,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: const BorderSide(color: AppColors.bordes, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.azulPrimario,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Campos de entrada / Formularios estilo Figma
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blanco,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bordes, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bordes, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.azulPrimario, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.critico, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.critico, width: 1.6),
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textoSecundario,
        ),
        hintStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFF94A3B8),
        ),
        prefixIconColor: AppColors.textoSecundario,
      ),

      // Tarjetas modernas estilo Figma (Radio 16, sin sombra pesada, borde sutil)
      cardTheme: CardThemeData(
        color: AppColors.blanco,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.bordes, width: 1.0),
        ),
      ),

      // Divisores sutiles
      dividerTheme: const DividerThemeData(
        color: AppColors.bordes,
        thickness: 1,
        space: 24,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.azulPrimario,
        foregroundColor: AppColors.blanco,
        elevation: 3,
      ),
    );
  }
}
