// tạo các chủ đề giao diện, dựa trên SettingProvider
// lib/utils/app_themes.dart

import 'package:flutter/material.dart';
import '../providers/setting_provider.dart';

class AppThemes {
  static ThemeData getAppTheme(SettingProvider settings) {
    Color primaryColor = _hexToColor(settings.settings.colorTheme ?? '#FFC0CB');

    double baseFontSize = 14;
    switch (settings.settings.fontSize) {
      case 'small':
        baseFontSize = 12;
        break;
      case 'medium':
        baseFontSize = 14;
        break;
      case 'large':
        baseFontSize = 16;
        break;
      default:
        baseFontSize = 14;
    }

    Brightness brightness = Brightness.light;
    if (settings.settings.theme == 'dark') {
      brightness = Brightness.dark;
    }

    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor:
          brightness == Brightness.dark ? const Color.fromARGB(255, 89, 83, 83) : const Color(0xFFFFE4EC),
      colorScheme: ColorScheme.fromSwatch(primarySwatch: _toMaterialColor(primaryColor))
          .copyWith(secondary: primaryColor, brightness: brightness),
      textTheme: TextTheme(
        bodyMedium: TextStyle(fontSize: baseFontSize),
        bodyLarge: TextStyle(fontSize: baseFontSize * 1.2),
        titleMedium: TextStyle(fontSize: baseFontSize * 1.5, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        }),
        // ignore: deprecated_member_use
        trackColor: WidgetStateProperty.all<Color>(primaryColor.withOpacity(0.5)),
      ),
    );
  }

  static Color _hexToColor(String hexString) {
    if (hexString.startsWith('#')) {
      hexString = hexString.substring(1);
    }
    if (hexString.length == 6) {
      hexString = 'FF$hexString';
    }
    return Color(int.parse(hexString, radix: 16));
  }

  static MaterialColor _toMaterialColor(Color color) {
    List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    Map<int, Color> swatch = {};
    // ignore: deprecated_member_use
    final int r = color.red, g = color.green, b = color.blue;

    for (var i = 0; i < 10; i++) {
      final double strength = strengths[i];
      swatch[100 * (i + 1)] = Color.fromRGBO(
        r + ((255 - r) * strength).round(),
        g + ((255 - g) * strength).round(),
        b + ((255 - b) * strength).round(),
        1,
      );
    }
    // ignore: deprecated_member_use
    return MaterialColor(color.value, swatch);
  }
}