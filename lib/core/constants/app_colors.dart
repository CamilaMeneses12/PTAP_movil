import 'package:flutter/material.dart';

/// Identidad Visual Unificada Oficial de PTAP basada en referencia.png
/// Aplica para todos los perfiles (Administrador, Operario y Consultor SIGA)
/// garantizando coherencia, elegancia, modernidad y tecnología del agua.
class AppColors {
  // Paleta Principal Unificada (referencia.png)
  static const Color azulMarino = Color(0xFF093970);        // Encabezados, navegación y títulos principales
  static const Color azulInstitucional = Color(0xFF084C8D);  // Botones principales y acciones destacadas
  static const Color azulTecnologico = Color(0xFF0B58A2);    // Elementos interactivos, enlaces e iconos
  static const Color azulClaro = Color(0xFFEAF2FA);          // Fondos suaves, tarjetas secundarias y selecciones
  static const Color turquesa = Color(0xFF5E9DE8);           // Azul agua complementario (ondas de referencia.png)
  static const Color fondoGeneral = Color(0xFFF3F7FC);       // Fondo general de todas las pantallas
  static const Color blanco = Color(0xFFFFFFFF);             // Tarjetas, formularios y modales
  static const Color textoPrincipal = Color(0xFF092E58);     // Títulos y contenido de alta legibilidad
  static const Color textoSecundario = Color(0xFF5D7189);    // Subtítulos y descripciones (gris pizarra azulado)
  static const Color bordes = Color(0xFFDCE7F2);             // Separadores y contornos limpios de tarjetas

  // Estados y alertas normativas (Res. 2115 de 2007)
  static const Color verdeAmbiental = Color(0xFF2E7D32);     // Estado dentro de norma / éxito
  static const Color alerta = Color(0xFFF59E0B);             // Amarillo / Naranja advertencia normativa
  static const Color alertaFondo = Color(0xFFFFFBEB);        // Fondo suave de advertencia
  static const Color alertaBorde = Color(0xFFFDE68A);        // Borde suave de advertencia
  static const Color error = Color(0xFFEF4444);              // Rojo crítico / fuera de norma
  static const Color errorFondo = Color(0xFFFEF2F2);         // Fondo suave de error
  static const Color exito = Color(0xFF2E7D32);              // Verde éxito
  static const Color exitoFondo = Color(0xFFF0FDF4);         // Fondo éxito

  // Gradientes Institucionales de Alta Fidelidad
  static const LinearGradient gradienteAzul = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [azulMarino, azulInstitucional],
  );

  static const LinearGradient gradienteAgua = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [azulInstitucional, turquesa],
  );

  static const LinearGradient gradienteTecnologico = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [azulTecnologico, Color(0xFF89BFF5)],
  );

  static const LinearGradient gradienteTarjeta = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [blanco, Color(0xFFF8FAFC)],
  );

  // Sombras suaves modernas basadas en referencia.png
  static List<BoxShadow> get sombraSuave => [
    BoxShadow(
      color: azulMarino.withAlpha(14),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get sombraTarjeta => [
    BoxShadow(
      color: azulMarino.withAlpha(16),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get sombraElevada => [
    BoxShadow(
      color: azulInstitucional.withAlpha(25),
      blurRadius: 28,
      offset: const Offset(0, 8),
    ),
  ];

  // Aliases de compatibilidad unificados bajo la paleta PTAP
  static const Color senaVerde = azulInstitucional;
  static const Color senaVerdeOscuro = azulMarino;
  static const Color senaAzul = azulMarino;
  static const Color aguaPrimario = azulInstitucional;
  static const Color aguaSecundario = turquesa;
  static const Color aguaFondo = fondoGeneral;
  static const Color superficie = blanco;
  static const Color borde = bordes;
  static const Color neutroGris = textoSecundario;
}
