import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

class ThemeState {
  final ThemeMode mode;
  final AppThemeColor color;

  const ThemeState({
    this.mode = ThemeMode.system,
    this.color = AppThemeColor.electricViolet,
  });

  ThemeState copyWith({
    ThemeMode? mode,
    AppThemeColor? color,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      color: color ?? this.color,
    );
  }
}

class ThemeService extends ValueNotifier<ThemeState> {
  static const String _modeKey = 'theme_mode';
  static const String _colorKey = 'theme_color';

  static final ThemeService _instance = ThemeService._internal();
  static ThemeService get instance => _instance;

  ThemeService._internal() : super(const ThemeState()) {
    _loadTheme();
  }

  ThemeMode get themeMode => value.mode;
  AppThemeColor get themeColor => value.color;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_modeKey) ?? 'system';
    final colorStr = prefs.getString(_colorKey) ?? 'electricViolet';

    final mode = _parseThemeMode(modeStr);
    final color = _parseThemeColor(colorStr);

    value = ThemeState(mode: mode, color: color);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    value = value.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, _themeModeToString(mode));
  }

  Future<void> setThemeColor(AppThemeColor color) async {
    value = value.copyWith(color: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorKey, _themeColorToString(color));
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

  AppThemeColor _parseThemeColor(String colorStr) {
    switch (colorStr) {
      case 'googleAI':
        return AppThemeColor.googleAI;
      case 'electricViolet':
      default:
        return AppThemeColor.electricViolet;
    }
  }

  String _themeColorToString(AppThemeColor color) {
    switch (color) {
      case AppThemeColor.googleAI:
        return 'googleAI';
      case AppThemeColor.electricViolet:
        return 'electricViolet';
    }
  }
}

