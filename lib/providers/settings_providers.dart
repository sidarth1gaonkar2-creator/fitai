import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'unit_system_provider.dart';

/// User-selected theme mode. Persisted via SharedPreferences.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs)
      : super(_loadFromPrefs(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'theme_mode';

  static ThemeMode _loadFromPrefs(SharedPreferences prefs) {
    final value = prefs.getString(_key);
    if (value == 'light') return ThemeMode.light;
    return ThemeMode.dark; // default
  }

  void toggle(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    _prefs.setString(_key, isDark ? 'dark' : 'light');
  }
}
