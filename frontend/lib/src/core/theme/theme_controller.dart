import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appThemeProvider = StateNotifierProvider<AppThemeNotifier, ThemeMode>((ref) {
  return AppThemeNotifier();
});

class AppThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _kThemePrefKey = 'pratidnya_theme_mode';

  AppThemeNotifier() : super(ThemeMode.light) {
    _loadPersistedTheme();
  }

  Future<void> _loadPersistedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_kThemePrefKey);
      if (savedTheme == 'dark') {
        state = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        state = ThemeMode.light;
      }
    } catch (_) {
      // Fallback remains light
    }
  }

  Future<void> toggleTheme() async {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _persistTheme();
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _persistTheme();
  }

  Future<void> _persistTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemePrefKey, state == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }
}
