import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: unused_import
import '../utils/constants.dart';

class BadgeProvider with ChangeNotifier {
  bool _hasNewBadge = false;
  List<Map<String, dynamic>> _newBadges = [];

  bool get hasNewBadge => _hasNewBadge;
  List<Map<String, dynamic>> get newBadges => _newBadges;

  Future<void> setHasNewBadge(bool value) async {
    _hasNewBadge = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_new_badge', value);
    notifyListeners();
  }

  void setNewBadges(List<Map<String, dynamic>> badges) {
    _newBadges = badges;
    notifyListeners();
  }

  Future<void> clearBadgeNotification() async {
    _hasNewBadge = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_new_badge', false);
    notifyListeners();
  }
}
