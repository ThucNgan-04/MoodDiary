import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/badge_provider.dart';
import '../utils/constants.dart';
import 'package:flutter/material.dart';

class BadgeService {
  final String baseUrl = Constants.apiUrl;

  // Kiểm tra & cập nhật huy hiệu cho user hiện tại
  Future<List<Map<String, dynamic>>> checkBadges(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      if (token == null) {
        debugPrint('[BadgeService] Không tìm thấy token — có thể chưa đăng nhập.');
        return [];
      }

      final response = await http.post(
        Uri.parse('$baseUrl/badges/check'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('POST /badges/check => ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List newBadges = data['new_badges'] ?? data['badges'] ?? [];

        if (newBadges.isNotEmpty) {
          final badgeProvider = Provider.of<BadgeProvider>(context, listen: false);

          // Lưu danh sách huy hiệu mới vào provider
          badgeProvider.setNewBadges(List<Map<String, dynamic>>.from(newBadges));

          // 🎉 Hiển thị chúc mừng huy hiệu mới
          final firstBadge = newBadges.first;
          final badgeName = firstBadge['badge_name'] ?? 'Huy hiệu mới';
          showCelebrationPopup(context, badgeName);

          // 🩷 Hiện thêm snackbar nhẹ nhàng ở dưới màn hình
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "🎉 Chúc mừng bạn đã đạt huy hiệu \"$badgeName\"! 🌈",
                style: const TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.pinkAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );

        }

        return List<Map<String, dynamic>>.from(newBadges);
      } else {
        debugPrint('Lỗi khi gọi /badges/check: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('[BadgeService] Lỗi khi kiểm tra huy hiệu: $e');
      return [];
    }
  }

  //Lấy danh sách huy hiệu hiện tại của user
  Future<List<Map<String, dynamic>>> getUserBadges(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/badges/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📡 GET /badges/me => ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['badges'] is List) {
          List<Map<String, dynamic>> badges =
              List<Map<String, dynamic>>.from(data['badges']);

          return badges.map((badge) {
            badge['icon'] = _getBadgeIcon(badge['badge_name']);
            badge['ai_quote'] ??= 'Bạn đã đạt được thành tựu đáng nhớ! ✨';
            return badge;
          }).toList();
        }
      }

      debugPrint("Không có dữ liệu huy hiệu: ${response.body}");
      return [];
    } catch (e) {
      debugPrint("[BadgeService] Lỗi khi tải huy hiệu: $e");
      return [];
    }
  }

  // Lấy tiến trình chuỗi ngày (tùy backend)
  Future<Map<String, int>?> getStreakProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/badges/streak-info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['current_streak'] != null && data['max_streak'] != null) {
          return {
            'current_streak': data['current_streak'] as int,
            'max_streak': data['max_streak'] as int,
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi khi tải tiến trình chuỗi: $e");
      return null;
    }
  }

  String _getBadgeIcon(String? badgeName) {
    final name = badgeName?.toLowerCase() ?? '';

    if (name.contains('thử thách 3 ngày')) {
      return '🥉';
    } else if (name.contains('7 ngày')) {
      return '🎖️';
    } else if (name.contains('bền bỉ')) {
      return '💪';
    } else if (name.contains('tia nắng')) {
      return '☀️';
    } else if (name.contains('lạc quan')) {
      return '🥳';
    } else if (name.contains('tâm hồn tích cực')) {
      return "🌻";
    } else if (name.contains('ghi chép tập sự')) {
      return '🎓';
    } else if (name.contains('sử học cảm xúc')) {
      return '🏆';
    } else if (name.contains('vượt khó')) {
      return '🔥';
    } else if (name.contains('nhật ký chăm chỉ')) {
      return '✍️';
    } else {
      return '👑';
    }
  }
}
void showCelebrationPopup(BuildContext context, String badgeName) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    builder: (context) => Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "🎉 Chúc mừng bạn! 🌈",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Bạn vừa đạt huy hiệu: $badgeName 🏆",
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  // Tự đóng sau 3 giây
  Future.delayed(const Duration(seconds: 3), () {
    if (Navigator.canPop(context)) Navigator.pop(context);
  });
}

