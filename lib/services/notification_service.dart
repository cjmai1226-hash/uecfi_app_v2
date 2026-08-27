import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint("Could not set local location, defaulting to Asia/Manila: $e");
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Manila'));
      } catch (_) {}
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    try {
      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
      );
      _isInitialized = true;
      debugPrint("✅ NotificationService initialized successfully");
    } catch (e) {
      debugPrint("❌ NotificationService initialization error: $e");
    }
  }

  Future<bool> requestPermissions() async {
    if (!_isInitialized) return false;
    try {
      if (Platform.isIOS) {
        final bool? result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return result ?? false;
      } else if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        final bool? result =
            await androidImplementation?.requestNotificationsPermission();
        return result ?? false;
      }
    } catch (e) {
      debugPrint("Error requesting notification permissions: $e");
    }
    return false;
  }

  Future<void> scheduleDailyPrayerReminder() async {
    if (!_isInitialized) return;
    // Request permissions just in case
    await requestPermissions();

    // Cancel any existing daily prayer reminder notification to prevent duplicates
    await _flutterLocalNotificationsPlugin.cancel(id: 0);

    final tz.TZDateTime scheduledDate = _nextInstanceOfFiveFiftyPM();

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: 0, // Notification ID
        title: 'Orasen ti Kararag', // Title
        body: 'Ayaten nga kakabsat orasen nga agkararag apagsipnget', // Body
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_prayer_reminder',
            'Daily Prayer Reminder',
            channelDescription: 'Daily reminder at 5:50 PM to pray',
            importance: Importance.max,
            priority: Priority.high,
            largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
            color: Color(0xFF1A73E8),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint(
        "🔔 Scheduled daily prayer notification for 17:50 (5:50 PM). Next occurrence: $scheduledDate",
      );
    } catch (e) {
      debugPrint("❌ Failed to schedule daily prayer reminder: $e");
    }
  }

  tz.TZDateTime _nextInstanceOfFiveFiftyPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 17, 50);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelDailyPrayerReminder() async {
    if (!_isInitialized) return;
    await _flutterLocalNotificationsPlugin.cancel(id: 0);
    debugPrint("🔔 Cancelled daily prayer notification reminder");
  }

  Future<void> scheduleSundayReminder() async {
    if (!_isInitialized) return;
    await requestPermissions();
    await _flutterLocalNotificationsPlugin.cancel(id: 1);

    final tz.TZDateTime scheduledDate = _nextInstanceOfSundayEightAM();

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: 1, // Sunday Reminder ID
        title: 'Orasen ti Panagdayaw', // Title
        body: 'Ayaten nga kakabsat, Domingo manen, orasen ti panagserbi ken panagdayaw iti Dios.', // Body
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'sunday_worship_reminder',
            'Sunday Worship Reminder',
            channelDescription: 'Weekly reminder on Sundays to worship and serve',
            importance: Importance.max,
            priority: Priority.high,
            largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
            color: Color(0xFF1A73E8),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      debugPrint(
        "🔔 Scheduled weekly Sunday worship notification. Next occurrence: $scheduledDate",
      );
    } catch (e) {
      debugPrint("❌ Failed to schedule Sunday reminder: $e");
    }
  }

  tz.TZDateTime _nextInstanceOfSundayEightAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 0);

    while (scheduledDate.weekday != DateTime.sunday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    return scheduledDate;
  }

  Future<void> cancelSundayReminder() async {
    if (!_isInitialized) return;
    await _flutterLocalNotificationsPlugin.cancel(id: 1);
    debugPrint("🔔 Cancelled Sunday worship reminder");
  }

  Future<void> showInstantNotification() async {
    if (!_isInitialized) return;
    await requestPermissions();
    await _flutterLocalNotificationsPlugin.show(
      id: 99,
      title: 'Orasen ti Kararag (Test)',
      body: 'Ayaten nga kakabsat orasen nga agkararag apagsipnget',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_prayer_reminder',
          'Daily Prayer Reminder',
          channelDescription: 'Daily reminder at 6:00 PM to pray',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
          color: Color(0xFF1A73E8),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    debugPrint("🔔 Triggered instant test notification");
  }

  Future<void> showInstantSundayNotification() async {
    if (!_isInitialized) return;
    await requestPermissions();
    await _flutterLocalNotificationsPlugin.show(
      id: 98,
      title: 'Orasen ti Panagdayaw (Test)',
      body: 'Ayaten nga kakabsat, Domingo manen, orasen ti panagserbi ken panagdayaw iti Dios.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'sunday_worship_reminder',
          'Sunday Worship Reminder',
          channelDescription: 'Weekly reminder on Sundays to worship and serve',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
          color: Color(0xFF1A73E8),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    debugPrint("🔔 Triggered instant Sunday test notification");
  }

  Future<void> scheduleMorningReminder() async {
    if (!_isInitialized) return;
    await requestPermissions();
    await _flutterLocalNotificationsPlugin.cancel(id: 2);

    final tz.TZDateTime scheduledDate = _nextInstanceOfSixAM();

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: 2, // Morning Reminder ID
        title: 'Kararag ti Bigat', // Title
        body: 'Ayaten nga kakabsat, umayen ti lawag ti bigat, orasen ti agkararag ken agyaman.', // Body
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_morning_prayer',
            'Daily Morning Prayer',
            channelDescription: 'Daily reminder at 6:00 AM to pray',
            importance: Importance.max,
            priority: Priority.high,
            largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
            color: Color(0xFF1A73E8),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint(
        "🔔 Scheduled daily morning prayer notification for 06:00 (6:00 AM). Next occurrence: $scheduledDate",
      );
    } catch (e) {
      debugPrint("❌ Failed to schedule daily morning prayer reminder: $e");
    }
  }

  tz.TZDateTime _nextInstanceOfSixAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 6, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelMorningReminder() async {
    if (!_isInitialized) return;
    await _flutterLocalNotificationsPlugin.cancel(id: 2);
    debugPrint("🔔 Cancelled daily morning prayer reminder");
  }

  Future<void> showInstantMorningNotification() async {
    if (!_isInitialized) return;
    await requestPermissions();
    await _flutterLocalNotificationsPlugin.show(
      id: 97,
      title: 'Kararag ti Bigat (Test)',
      body: 'Ayaten nga kakabsat, umayen ti lawag ti bigat, orasen ti agkararag ken agyaman.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_morning_prayer',
          'Daily Morning Prayer',
          channelDescription: 'Daily reminder at 6:00 AM to pray',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
          color: Color(0xFF1A73E8),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    debugPrint("🔔 Triggered instant morning test notification");
  }
}
