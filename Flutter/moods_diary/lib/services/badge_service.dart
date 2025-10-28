import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/badge_popup_utils.dart'; 
// ignore: unused_import
import 'package:provider/provider.dart';
// ignore: unused_import
import '../providers/badge_provider.dart';

class BadgeService {
  final String baseUrl = Constants.apiUrl;

  Future<Map<String, dynamic>> checkAndGetBadges(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(Constants.tokenKey);

    if (token == null) {
      debugPrint('[BadgeService] Không tìm thấy token.');
      return {'badges': [], 'revoked_badge_names': [], 'new_badge': null};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/badges/check'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('GET /badges/check => ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final List<Map<String, dynamic>> badges = List<Map<String, dynamic>>.from(data['badges'] ?? []);
        final List<String> revokedNames = List<String>.from(data['revoked_badge_names'] ?? []);
        final newBadge = data['new_badge'] != null ? Map<String, dynamic>.from(data['new_badge']) : null;
        
        final processedBadges = badges.map((badge) {
          badge['ai_quote'] ??= 'Bạn đã đạt được thành tựu đáng nhớ! ✨';
          return badge;
        }).toList();

        // Xử lý hiển thị popup nếu API này trả về huy hiệu mới
        if (newBadge != null) {
          final badgeName = newBadge['badge_name'] ?? 'Huy hiệu mới';
          final aiQuote = newBadge['ai_quote'] ?? 'Một thành tựu đáng nhớ!';
          final imageUrl = newBadge['image_url'] ?? '';

          showCelebrationPopup(context, badgeName, aiQuote, imageUrl); 
          
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

        return {
          'badges': processedBadges,
          'revoked_badge_names': revokedNames,
          'new_badge': newBadge,
        };

      } else {
        debugPrint('Lỗi khi gọi /badges/check: ${response.body}');
        throw Exception('Failed to check badges. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[BadgeService] Lỗi khi kiểm tra huy hiệu: $e');
      throw Exception('Lỗi khi kiểm tra huy hiệu: $e');
    }
  }

  Future<bool> revokeBadge(String badgeName, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(Constants.tokenKey);

    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/badges/revoke'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'badge_name': badgeName}),
      );

      debugPrint('POST /badges/revoke => ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[BadgeService] Lỗi khi thu hồi huy hiệu $badgeName: $e');
      return false;
    }
  }

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
}