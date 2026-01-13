import 'package:flutter/material.dart';
import 'package:moods_diary/providers/badge_provider.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'dart:io'; 

import 'providers/setting_provider.dart';
import 'providers/translation_provider.dart';
import 'services/emotion_tree_service.dart';

import 'utils/app_themes.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/thongke_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingProvider()),
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),

        ChangeNotifierProvider<EmotionTreeService>(create: (_) => EmotionTreeService()),
      ],
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingProvider, TranslationProvider>(
      builder: (context, settingsProvider, transProvider, _) {
        return MaterialApp(
          title: 'Mood Diary',
          theme: AppThemes.getAppTheme(settingsProvider),
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/stats': (context) => const ThongKeScreen(),
            '/calendar': (context) => const CalendarScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
