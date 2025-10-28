import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/badge_service.dart';

class BadgeProvider with ChangeNotifier {
  bool _hasNewBadge = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _newBadges = [];
  List<Map<String, dynamic>> _badges = [];
  final BadgeService _badgeService = BadgeService();

  bool get hasNewBadge => _hasNewBadge;
  bool get isLoading => _isLoading;
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
  //XÓA HUY HIỆU TRÊN SERVER VÀ CẬP NHẬT LOCAL
  Future<void> _deleteBadgeOnServer(String badgeName, BuildContext context) async {
    try {
      final success = await _badgeService.revokeBadge(badgeName, context);
      if (success) {
        // Xóa khỏi danh sách local ngay lập tức
        _badges.removeWhere((badge) => badge['badge_name'] == badgeName);
        notifyListeners();
        if (kDebugMode) {
          print("Đã xóa huy hiệu thu hồi: $badgeName");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Lỗi xóa huy hiệu '$badgeName' trên server: $e");
      }
    }
  }

  void _showRevokedBadgeAlert(BuildContext context, List<String> revokedNames) {
    if (revokedNames.isEmpty) return;
    
    final message = 'Bạn đã mất huy hiệu sau:\n${revokedNames.join(', ')}\n\n'
                    'Lý do: Không duy trì được điều kiện đạt huy hiệu. \n'
                    '(Hãy bấm i để xem chi tiết đạt huy hiệu)';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('🚨 Huy hiệu bị thu hồi!'),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đã hiểu', style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // API XÓA TỪNG HUY HIỆU SAU KHI CLICK OK
                for (var name in revokedNames) {
                  _deleteBadgeOnServer(name, context);
                }
              },
            ),
          ],
        );
      },
    );
  }
  
  // ---- Quản lý danh sách huy hiệu (Sửa đổi) ----
  Future<void> loadBadges(BuildContext context) async {
    if (_isLoading) return;
    
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _badgeService.checkAndGetBadges(context);
      
      _badges = result['badges'] ?? [];
      final List<String> revokedNames = List<String>.from(result['revoked_badge_names'] ?? []);
      
      //Xử lý huy hiệu mới (nếu có)
      final newBadge = result['new_badge'];
      if (newBadge != null) {
        _newBadges = [Map<String, dynamic>.from(newBadge)];
        await setHasNewBadge(true);
      }
      
      if (revokedNames.isNotEmpty) {
        Future.microtask(() => _showRevokedBadgeAlert(context, revokedNames));
      }

    } catch (e) {
      if (kDebugMode) {
        print("Lỗi load/check huy hiệu: $e");
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