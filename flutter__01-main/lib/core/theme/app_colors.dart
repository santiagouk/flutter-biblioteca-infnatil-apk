import 'package:flutter/material.dart';

/// Paleta de colores de la Biblioteca Infantil.
///
/// Pensada para un público infantil: colores saturados, alegres y con
/// buen contraste, evitando combinaciones que resulten agresivas a la
/// vista. Cada color de marca cuenta con una variante para modo oscuro.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------
  // Colores de marca (comunes a ambos modos)
  // ---------------------------------------------------------------------
  static const Color primary = Color(0xFFFF6B6B); // Coral vibrante
  static const Color secondary = Color(0xFF4ECDC4); // Turquesa
  static const Color accentYellow = Color(0xFFFFD93D); // Amarillo sol
  static const Color accentPurple = Color(0xFF9B5DE5); // Púrpura mágico
  static const Color accentBlue = Color(0xFF4A6FE5); // Azul cielo
  static const Color accentGreen = Color(0xFF06D6A0); // Verde menta
  static const Color accentOrange = Color(0xFFFF9F1C); // Naranja

  static const Color success = Color(0xFF06D6A0);
  static const Color error = Color(0xFFEF476F);
  static const Color warning = Color(0xFFFFD93D);

  // Colores usados para asignar automáticamente a categorías sin color
  // definido, rotando por índice.
  static const List<Color> categoryPalette = [
    accentBlue,
    accentPurple,
    accentGreen,
    accentOrange,
    primary,
    secondary,
  ];

  // ---------------------------------------------------------------------
  // Modo claro
  // ---------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFFFFBF5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3F0FF);
  static const Color lightTextPrimary = Color(0xFF2D2A32);
  static const Color lightTextSecondary = Color(0xFF6E6A75);
  static const Color lightBorder = Color(0xFFEAE6F5);

  // ---------------------------------------------------------------------
  // Modo oscuro
  // ---------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF15131C);
  static const Color darkSurface = Color(0xFF201C29);
  static const Color darkSurfaceVariant = Color(0xFF2A2534);
  static const Color darkTextPrimary = Color(0xFFF5F3FA);
  static const Color darkTextSecondary = Color(0xFFB2ADC2);
  static const Color darkBorder = Color(0xFF383151);

  /// Devuelve un color de la paleta de categorías según un índice,
  /// repitiendo el ciclo si el índice excede el tamaño de la lista.
  static Color categoryColorFor(int index) {
    return categoryPalette[index % categoryPalette.length];
  }
}
