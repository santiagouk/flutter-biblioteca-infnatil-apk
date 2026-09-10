import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Construye el [TextTheme] de la aplicación.
///
/// Se usan dos familias tipográficas:
/// - Baloo 2: redondeada y juguetona, para títulos y elementos destacados.
/// - Nunito: alta legibilidad, para cuerpos de texto y lectura prolongada.
class AppTextTheme {
  AppTextTheme._();

  static TextTheme build(Color textColor) {
    final base = TextTheme(
      displayLarge: GoogleFonts.baloo2(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displayMedium: GoogleFonts.baloo2(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.baloo2(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.baloo2(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
    return base;
  }
}
