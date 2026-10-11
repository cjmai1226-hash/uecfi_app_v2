import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final ThemeMode mode;

  const ThemeState({
    this.mode = ThemeMode.system,
  });

  ThemeState copyWith({
    ThemeMode? mode,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
    );
  }
}

class ThemeService extends ValueNotifier<ThemeState> {
  static const String _modeKey = 'theme_mode';

  static final ThemeService _instance = ThemeService._internal();
  static ThemeService get instance => _instance;

  ThemeService._internal() : super(const ThemeState()) {
    _loadTheme();
  }

  ThemeMode get themeMode => value.mode;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_modeKey) ?? 'system';
    final mode = _parseThemeMode(modeStr);

    value = ThemeState(mode: mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    value = value.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, _themeModeToString(mode));
  }

  ThemeMode _parseThemeMode(String modeStr) {
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
