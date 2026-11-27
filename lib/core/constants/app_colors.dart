import 'package:flutter/material.dart';

/// Paleta Oficial PTAP Monitor – Fiel al diseño de Figma (App Móvil SENA)
/// ESTRICTAMENTE SIN AMARILLO. Las advertencias usan naranja (#EA7A12).
class AppColors {
  // Paleta Principal Oficial Figma
  static const Color azulMarino = Color(0xFF0B3B7A);        // Encabezados, títulos, ícono y texto activo de navbar
  static const Color azulPrimario = Color(0xFF1565C0);      // Botones, barras principales, línea "Entrada"
  static const Color azulInstitucional = Color(0xFF1565C0);  // Alias coherente para acciones principales
  static const Color azulClaro = Color(0xFFE3EEFB);          // Píldora activa de barra inferior y selecciones suaves
  static const Color turquesa = Color(0xFF14B8A6);           // Chip "Operativa", gauges
  static const Color turquesaFondo = Color(0xFFE6F7F5);
  static const Color turquesaTexto = Color(0xFF0D9488);      // Texto sobre fondo turquesa (chips, rol Consultor)      // Fondo suave chip "Operativa"
  static const Color fondoGeneral = Color(0xFFF2F2F2);       // Fondo general de todas las pantallas: el mismo gris del video de bienvenida
  static const Color fondoIntro = fondoGeneral;              // Fondo del video (animacion.mp4); igual en Android (@color/fondo_intro)
  static const Color blanco = Color(0xFFFFFFFF);             // Tarjetas, modales y formularios
  static const Color superficie = Color(0xFFFFFFFF);         // Superficie de tarjetas
  static const Color textoPrincipal = Color(0xFF0F1E3D);     // Títulos y valores grandes de alta legibilidad
  static const Color textoSecundario = Color(0xFF6B7A90);    // Etiquetas, subtítulos y gris azulado
  static const Color bordes = Color(0xFFE3E9F1);             // Bordes sutiles y separadores

  // Estados y alertas normativas (Res. 2115 de 2007) - CERO AMARILLO
  static const Color critico = Color(0xFFE53935);            // Crítico / Error / Fuera de rango
  static const Color criticoFondo = Color(0xFFFDECEC);       // Fondo suave crítico / fila fuera de rango
  static const Color error = Color(0xFFE53935);              // Alias error
  static const Color errorFondo = Color(0xFFFDECEC);         // Fondo suave error

  static const Color advertencia = Color(0xFFEA7A12);        // Advertencia / Mantenimiento (Naranja estricto)
  static const Color advertenciaFondo = Color(0xFFFDF0E4);   // Fondo suave advertencia / mantenimiento
  static const Color advertenciaBorde = Color(0xFFFAD1AB);   // Borde suave naranja advertencia
  static const Color alerta = Color(0xFFEA7A12);             // Alias alerta -> Naranja (NO amarillo)
  static const Color alertaFondo = Color(0xFFFDF0E4);        // Fondo alerta naranja
  static const Color alertaBorde = Color(0xFFFAD1AB);        // Borde alerta naranja

  static const Color informacion = Color(0xFF1E6FD9);        // Información normativa y técnica
  static const Color informacionFondo = Color(0xFFE8F1FC);   // Fondo suave información
  static const Color azulTecnologico = Color(0xFF1E6FD9);    // Elementos tecnológicos e interactivos

  static const Color exito = Color(0xFF16A34A);              // Conforme / variación positiva / éxito
  static const Color exitoFondo = Color(0xFFE6F7F5);         // Fondo suave éxito
  static const Color verdeAmbiental = Color(0xFF16A34A);     // Verde normativo Res. 2115

  // Gradientes Institucionales de Alta Fidelidad
  static const LinearGradient gradienteAzul = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [azulMarino, azulPrimario],
  );

  static const LinearGradient gradienteBanner = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B3B7A), Color(0xFF082D60)],
  );

  static const LinearGradient gradienteAgua = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [azulPrimario, turquesa],
  );

  static const LinearGradient gradienteTarjeta = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [blanco, Color(0xFFF8FAFD)],
  );

  // Sombras ultra suaves fieles a Figma
  static List<BoxShadow> get sombraSuave => [
    BoxShadow(
      color: const Color(0xFF0B3B7A).withAlpha(10),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get sombraTarjeta => [
    BoxShadow(
      color: const Color(0xFF0B3B7A).withAlpha(12),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get sombraElevada => [
    BoxShadow(
      color: const Color(0xFF0B3B7A).withAlpha(20),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Aliases de compatibilidad
  static const Color senaVerde = azulPrimario;
  static const Color senaVerdeOscuro = azulMarino;
  static const Color senaAzul = azulMarino;
  static const Color aguaPrimario = azulPrimario;
  static const Color aguaSecundario = turquesa;
  static const Color aguaFondo = fondoGeneral;
  static const Color borde = bordes;
  static const Color neutroGris = textoSecundario;
}
