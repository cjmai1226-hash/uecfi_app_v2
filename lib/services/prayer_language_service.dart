import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerLanguageService extends ValueNotifier<String> {
  static const String _key = 'prayer_language';

  static final PrayerLanguageService _instance = PrayerLanguageService._internal();
  static PrayerLanguageService get instance => _instance;

  PrayerLanguageService._internal() : super('ILO') {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getString(_key) ?? 'ILO';
  }

  Future<void> setLanguage(String langCode) async {
    if (langCode != 'ILO' && langCode != 'TAG') return;
    value = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, langCode);
  }
}
