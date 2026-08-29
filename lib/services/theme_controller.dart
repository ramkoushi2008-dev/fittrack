import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app-wide light/dark preference. Dark remains the default,
/// matching the app's original design.
class ThemeController extends ChangeNotifier {
  static ThemeController? _instance;
  static ThemeController get instance => _instance ??= ThemeController._();
  ThemeController._();

  static const _prefKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'light') {
        _themeMode = ThemeMode.light;
        notifyListeners();
      }
    } catch (_) {
      // Fall back to the default (dark) if prefs aren't available.
    }
  }

  Future<void> setDark(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, dark ? 'dark' : 'light');
    } catch (_) {}
  }

  Future<void> toggle() => setDark(!isDark);
}
