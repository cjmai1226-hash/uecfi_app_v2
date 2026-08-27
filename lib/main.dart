import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/theme.dart';
import 'screens/main/splash_screen.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'services/notifications_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDHNEkSimuzWaMiL_DKPJmY_pVTGoewaOw',
      appId: '1:741354382245:android:0c24175a97055e80a1be4c',
      messagingSenderId: '741354382245',
      projectId: 'uecfi-zaoqsg',
      storageBucket: 'uecfi-zaoqsg.firebasestorage.app',
    ),
  );

  // Initialize notification service
  await NotificationService().init();
  // Load settings preference and schedule notifications accordingly
  final _ = NotificationsSettingsService.instance;

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'UECFI APP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
