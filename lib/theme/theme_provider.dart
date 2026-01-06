import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider class for managing theme state (dark mode/light mode)
class ThemeProvider extends ChangeNotifier {
  static const String _themePreferenceKey = 'theme_mode_preference';

  ThemeMode _themeMode = ThemeMode.dark;
  bool _isDarkMode = true;

  ThemeProvider() {
    _loadThemeFromPreferences();
  }

  /// Gets the current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Gets whether dark mode is currently active
  bool get isDarkMode => _isDarkMode;

  /// Loads the saved theme preference from SharedPreferences
  Future<void> _loadThemeFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themePreferenceKey);

      if (savedThemeIndex != null) {
        _themeMode = ThemeMode.values[savedThemeIndex];
        _isDarkMode = _themeMode == ThemeMode.dark;
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, keep default dark mode
      debugPrint('Error loading theme preference: $e');
    }
  }

  /// Toggles between dark and light mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;

    await _saveThemeToPreferences();
    notifyListeners();
  }

  /// Sets the theme mode explicitly
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      _isDarkMode = mode == ThemeMode.dark;

      notifyListeners();
      await _saveThemeToPreferences();
    }
  }

  /// Saves the current theme preference to SharedPreferences
  Future<void> _saveThemeToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePreferenceKey, _themeMode.index);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}
