import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class NotificationsSettingsService extends ValueNotifier<bool> {
  static const String _key = 'app_notifications_enabled';

  static final NotificationsSettingsService _instance = NotificationsSettingsService._internal();
  static NotificationsSettingsService get instance => _instance;

  NotificationsSettingsService._internal() : super(true) {
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      value = prefs.getBool(_key) ?? true;
      await _applyNotificationPreference(value);
    } catch (e) {
      debugPrint("Error loading notification preferences: $e");
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    value = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, enabled);
      await _applyNotificationPreference(enabled);
    } catch (e) {
      debugPrint("Error saving notification preference: $e");
    }
  }

  Future<void> _applyNotificationPreference(bool enabled) async {
    if (enabled) {
      // Schedule all active reminders
      await NotificationService().scheduleDailyPrayerReminder();
      await NotificationService().scheduleSundayReminder();
      await NotificationService().scheduleMorningReminder();
    } else {
      // Cancel all reminders
      await NotificationService().cancelDailyPrayerReminder();
      await NotificationService().cancelSundayReminder();
      await NotificationService().cancelMorningReminder();
    }
  }
}
