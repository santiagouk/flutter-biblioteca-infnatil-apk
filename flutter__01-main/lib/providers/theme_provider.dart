import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Provider que gestiona el modo de tema (claro / oscuro / sistema) y
/// persiste la preferencia del usuario localmente con
/// [SharedPreferences], para que se mantenga entre sesiones.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadSavedTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(AppConstants.prefThemeMode);
    if (savedValue != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedValue,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeMode, mode.name);
  }

  /// Alterna rápidamente entre claro y oscuro (usado por el switch de
  /// la pantalla de Configuración).
  Future<void> toggleTheme() {
    return setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
