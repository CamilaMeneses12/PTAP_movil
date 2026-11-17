import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Configuración de tema global unificado para PTAP basado en referencia.png
/// Aplica para todos los perfiles (Administrador, Operario y Consultor SIGA)
class AppTheme {
  static ThemeData get temaClaro {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.azulInstitucional,
        primary: AppColors.azulInstitucional,
        onPrimary: AppColors.blanco,
        secondary: AppColors.azulTecnologico,
        onSecondary: AppColors.blanco,
        tertiary: AppColors.turquesa,
        surface: AppColors.blanco,
        onSurface: AppColors.textoPrincipal,
        error: AppColors.error,
        onError: AppColors.blanco,
      ),
      scaffoldBackgroundColor: AppColors.fondoGeneral,

      // Tipografía institucional de alta legibilidad
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.4,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 17,
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
          fontWeight: FontWeight.bold,
        ),
      ),

      // Barra superior institucional unificada
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.azulMarino,
        foregroundColor: AppColors.blanco,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.blanco,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.blanco),
      ),

      // Botones principales elevados estilo referencia.png
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azulInstitucional,
          foregroundColor: AppColors.blanco,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Botones con contorno
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.azulInstitucional,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: const BorderSide(color: AppColors.azulTecnologico, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Botones de texto (enlaces interactivos)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.azulTecnologico,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Campos de entrada / Formularios estilo referencia.png
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blanco,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.bordes, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.bordes, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.azulTecnologico, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textoSecundario,
        ),
        hintStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFF8395A7),
        ),
        prefixIconColor: AppColors.azulTecnologico,
      ),

      // Tarjetas modernas estilo referencia.png
      cardTheme: CardThemeData(
        color: AppColors.blanco,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.bordes, width: 1.2),
        ),
      ),

      // Divisores
      dividerTheme: const DividerThemeData(
        color: AppColors.bordes,
        thickness: 1,
        space: 24,
      ),

      // Indicadores de pestañas
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.turquesa,
        labelColor: AppColors.blanco,
        unselectedLabelColor: Color(0xFFB0C7D8),
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.azulInstitucional,
        foregroundColor: AppColors.blanco,
        elevation: 2,
      ),
    );
  }
}
