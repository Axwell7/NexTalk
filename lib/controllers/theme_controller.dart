import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeController() {
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark =
        prefs.getBool('darkMode') ?? false;

    _themeMode =
        isDark ? ThemeMode.dark : ThemeMode.light;

    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      'darkMode',
      value,
    );

    _themeMode =
        value ? ThemeMode.dark : ThemeMode.light;

    notifyListeners();
  }

  bool get isDark =>
      _themeMode == ThemeMode.dark;
}