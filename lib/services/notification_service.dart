import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'user_service.dart';
import 'notifications_settings_service.dart';

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
      final localTz = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = localTz.identifier;
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

      // Create Android Notification Channels explicitly with MAX importance
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'daily_prayer_reminder',
            'Daily Evening Prayer Reminder (6:00 PM)',
            description: 'Daily reminder at 6:00 PM to pray',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'daily_morning_prayer',
            'Daily Morning Prayer Reminder (6:00 AM)',
            description: 'Daily reminder at 6:00 AM to pray',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'sunday_worship_reminder',
            'Sunday Worship Reminder (8:00 AM)',
            description: 'Weekly reminder on Sundays to worship and serve',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'community_posts_channel',
            'Community Posts',
            description:
                'Notifications for new posts shared in the community feed',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

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
    await requestPermissions();
    await _flutterLocalNotificationsPlugin.cancel(id: 0);

    final tz.TZDateTime scheduledDate = _nextInstanceOfSixPM();

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: 0,
        title: 'Orasen ti Kararag',
        body: 'Ayaten nga kakabsat orasen nga agkararag apagsipnget',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_prayer_reminder',
            'Daily Evening Prayer Reminder (6:00 PM)',
            channelDescription: 'Daily reminder at 6:00 PM to pray',
            importance: Importance.max,
            priority: Priority.high,
            largeIcon: DrawableResourceAndroidBitmap('brand_mark'),
            color: Color(0xFF1A73E8),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint(
        "🔔 Scheduled daily evening prayer notification for 18:00 (6:00 PM). Next occurrence: $scheduledDate",
      );
    } catch (e) {
      debugPrint("❌ Failed to schedule daily evening prayer reminder: $e");
    }
  }

  tz.TZDateTime _nextInstanceOfSixPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 18, 0);
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
        id: 1,
        title: 'Orasen ti Panagdayaw',
        body:
            'Ayaten nga kakabsat, Domingo manen, orasen ti panagserbi ken panagdayaw iti Dios.',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'sunday_worship_reminder',
            'Sunday Worship Reminder (8:00 AM)',
            channelDescription:
                'Weekly reminder on Sundays to worship and serve',
            importance: Importance.max,
            priority: Priority.high,
            largeIcon: DrawableResourceAndroidBitmap('brand_mark'),
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
      debugPrint("❌ Failed to schedule Sunday worship reminder: $e");
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
          'Daily Evening Prayer Reminder (6:00 PM)',
          channelDescription: 'Daily reminder at 6:00 PM to pray',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: DrawableResourceAndroidBitmap('brand_mark'),
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
      body:
          'Ayaten nga kakabsat, Domingo manen, orasen ti panagserbi ken panagdayaw iti Dios.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'sunday_worship_reminder',
          'Sunday Worship Reminder (8:00 AM)',
          channelDescription: 'Weekly reminder on Sundays to worship and serve',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: DrawableResourceAndroidBitmap('brand_mark'),
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
        id: 2,
        title: 'Kararag ti Bigat',
        body:
            'Ayaten nga kakabsat, umayen ti lawag ti bigat, orasen ti agkararag ken agyaman.',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_morning_prayer',
            'Daily Morning Prayer Reminder (6:00 AM)',
            channelDescription: 'Daily reminder at 6:00 AM to pray',
            importance: Importance.max,
            priority: Priority.high,
            largeIcon: DrawableResourceAndroidBitmap('brand_mark'),
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
          largeIcon: DrawableResourceAndroidBitmap('brand_mark'),
          color: Color(0xFF1A73E8),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    debugPrint("🔔 Triggered instant morning test notification");
  }

  StreamSubscription? _postsSubscription;
  DateTime _listeningStartTime = DateTime.now();

  void startListeningToNewCommunityPosts() {
    _postsSubscription?.cancel();
    _listeningStartTime = DateTime.now();

    _postsSubscription = FirebaseFirestore.instance
        .collection('community_posts')
        .where('timestamp', isGreaterThan: _listeningStartTime)
        .snapshots()
        .listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data == null) continue;

            final authorEmail = (data['authorEmail'] as String?)?.trim() ?? '';
            final currentUserEmail = UserService.instance.value.email.trim();

            // Do not notify if the current user authored this post
            if (currentUserEmail.isNotEmpty &&
                authorEmail.isNotEmpty &&
                authorEmail.toLowerCase() == currentUserEmail.toLowerCase()) {
              continue;
            }

            final authorName = (data['author'] as String?)?.trim() ?? 'A member';
            final content = (data['content'] as String?)?.trim() ?? '';

            showNewPostNotification(
              author: authorName,
              content: content,
              postId: change.doc.id,
            );
          }
        }
      },
      onError: (e) {
        debugPrint("Error listening to new community posts: $e");
      },
    );
    debugPrint("🔔 Started listening to new community posts for notifications");
  }

  void stopListeningToNewCommunityPosts() {
    _postsSubscription?.cancel();
    _postsSubscription = null;
    debugPrint("🔔 Stopped listening to new community posts");
  }

  Future<void> showNewPostNotification({
    required String author,
    required String content,
    String? postId,
  }) async {
    if (!_isInitialized) return;
    if (!NotificationsSettingsService.instance.value) return;

    await requestPermissions();

    final cleanSnippet = content.trim().replaceAll('\n', ' ');
    final displayBody = cleanSnippet.length > 80
        ? '${cleanSnippet.substring(0, 80)}...'
        : cleanSnippet;

    final int notificationId =
        DateTime.now().millisecondsSinceEpoch % 100000 + 100;

    try {
      await _flutterLocalNotificationsPlugin.show(
        id: notificationId,
        title: '$author shared a new post',
        body: displayBody.isNotEmpty
            ? displayBody
            : 'Tap to view the new community post.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'community_posts_channel',
            'Community Posts',
            channelDescription:
                'Notifications for new posts shared in the community feed',
            importance: Importance.max,
            priority: Priority.high,
            largeIcon: DrawableResourceAndroidBitmap('brand_mark'),
            color: Color(0xFF1A73E8),
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      debugPrint("🔔 Triggered new post notification for post by $author");
    } catch (e) {
      debugPrint("❌ Failed to show new post notification: $e");
    }
  }
}
