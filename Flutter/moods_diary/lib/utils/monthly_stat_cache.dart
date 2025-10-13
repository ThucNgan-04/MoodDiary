import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MonthlyStatCache {
  static Future<void> saveStats(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadStats(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw != null) {
      return jsonDecode(raw);
    }
    return null;
  }

  static Future<void> clearStats(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}