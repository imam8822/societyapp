import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _themePrefKey = 'theme_pref';

  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themePrefKey);
    if (savedTheme != null) {
      if (savedTheme == 'light') {
        state = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.system;
      }
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      await prefs.setString(_themePrefKey, 'light');
    } else if (mode == ThemeMode.dark) {
      await prefs.setString(_themePrefKey, 'dark');
    } else {
      await prefs.setString(_themePrefKey, 'system');
    }
  }

  Future<void> toggleTheme(BuildContext context) async {
    if (state == ThemeMode.light) {
      await setTheme(ThemeMode.dark);
    } else if (state == ThemeMode.dark) {
      await setTheme(ThemeMode.light);
    } else {
      // If system, switch to the opposite of current brightness
      final brightness = MediaQuery.of(context).platformBrightness;
      if (brightness == Brightness.dark) {
        await setTheme(ThemeMode.light);
      } else {
        await setTheme(ThemeMode.dark);
      }
    }
  }
}
