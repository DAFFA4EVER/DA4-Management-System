import 'package:flutter/material.dart';

class ThemeDataSetting {
  static ThemeMode _currentTheme = ThemeMode.system;


  void setThemeMode(ThemeMode inputThemeMode) {
    _currentTheme = inputThemeMode;
  }

  ThemeMode getThemeMode() {
    return _currentTheme;
  }
}
