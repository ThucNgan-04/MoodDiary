import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/badge_service.dart';

class BadgeProvider with ChangeNotifier {
  bool _hasNewBadge = false;
  bool _isLoading = false; // ✅ thêm để fix lỗi getter
  List<Map<String, dynamic>> _newBadges = [];
  List<Map<String, dynamic>> _badges = [];
  final BadgeService _badgeService = BadgeService();

  bool get hasNewBadge => _hasNewBadge;
  bool get isLoading => _isLoading; // ✅ getter mới
  List<Map<String, dynamic>> get newBadges => _newBadges;
  List<Map<String, dynamic>> get badges => _badges;

  // ---- Cài đặt SharedPreferences ----
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

  // ---- Quản lý danh sách huy hiệu ----
  Future<void> loadBadges(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final badges = await _badgeService.getUserBadges(context);
      _badges = badges ;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Lỗi load huy hiệu: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBadges(BuildContext context) async {
    await loadBadges(context);
  }
}
