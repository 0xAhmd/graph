// lib/core/themes/theme_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  ThemeCubit() : super(ThemeMode.system) {
    _loadTheme();
  }

  // Load saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeKey);

      if (savedThemeIndex != null) {
        final themeMode = ThemeMode.values[savedThemeIndex];
        emit(themeMode);
      } else {
        // If no saved preference, use system default
        emit(ThemeMode.system);
      }
    } catch (e) {
      // If there's an error, fallback to system theme
      emit(ThemeMode.system);
    }
  }

  // Save theme to SharedPreferences
  Future<void> _saveTheme(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeMode.index);
    } catch (e) {
      // Handle error silently or log it

    }
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    emit(themeMode);
    await _saveTheme(themeMode);
  }

  // Getters for convenience
  bool get isDark => state == ThemeMode.dark;
  bool get isLight => state == ThemeMode.light;
  bool get isSystem => state == ThemeMode.system;

  ThemeMode get themeMode => state;
}
