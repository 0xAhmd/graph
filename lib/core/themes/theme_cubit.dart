import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/core/themes/dark_mode.dart';
import 'package:ig_mate/core/themes/light_mode.dart';

class ThemeCubit extends Cubit<ThemeData> {
  bool _isDark = true;

  ThemeCubit() : super(darkMode);

  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark; // Correctly toggle the value
    if (_isDark) {
      emit(darkMode);
    } else {
      emit(lightMode);
    }
  }
}
