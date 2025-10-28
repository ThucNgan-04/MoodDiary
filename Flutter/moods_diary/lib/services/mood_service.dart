import 'dart:convert';
import 'package:flutter/material.dart'; 
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/mood_model.dart';
// Import các hàm UI từ file Utils mới
import '../utils/badge_popup_utils.dart'; 

class MoodService {
  // Thêm BuildContext vào saveMood để hiển thị popup/snackbar
  Future<Map<String, dynamic>?> saveMood(BuildContext context, String moodType, String tag, String note, {String? date}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      if (token == null) {
        return {'success': false, 'message': 'Người dùng chưa đăng nhập.'};
      }

      final body = {
        'emotion': moodType,
        'tag': tag,
        'note': note,
      };

      if (date != null) body['date'] = date; 

      final response = await http.post(
        Uri.parse('${Constants.apiUrl}/moods'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('[MoodService] Status: ${response.statusCode}');
      print('[MoodService] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // --- Xử lý Huy hiệu mới ---
        final newBadge = data['new_badge'];
        if (newBadge != null) {
          final badgeName = newBadge['badge_name'] ?? 'Huy hiệu mới';
          final aiQuote = newBadge['ai_quote'] ?? 'Một thành tựu đáng nhớ!';
          final imageUrl = newBadge['image_url'] ?? '';
          //Hiển thị Popup chúc mừng
          showCelebrationPopup(context, badgeName, aiQuote, imageUrl);
        }

        // Xử lý suggestion
        final suggestionData = data['suggestion'];
        String? suggestion;
        if (suggestionData is String) {
          suggestion = suggestionData;
        } else if (suggestionData is Map && suggestionData.containsKey('content')) {
          suggestion = suggestionData['content'];
        }

        return {
          'success': true,
          'data': MoodModel.fromJson(data['data']),
          'suggestion': suggestion,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Lưu nhật ký thất bại. Vui lòng thử lại.'
        };
      }
    } catch (e) {
      print('[MoodService] Lỗi: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  Future<List<MoodModel>> getMoodsByDate(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${Constants.apiUrl}/moods?date=$date'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[MoodService] Fetch moods by date: $date');
      print('[MoodService] Status: ${response.statusCode}');
      print('[MoodService] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> moodsJson = data['data'];
        return moodsJson.map((json) => MoodModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('[MoodService] Lỗi getMoodsByDate: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> deleteMood(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);
      if (token == null) {
        return {'success': false, 'message': 'Người dùng chưa đăng nhập.'};
      }

      final response = await http.delete(
        Uri.parse('${Constants.apiUrl}/moods/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[MoodService] Delete Mood Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Xóa thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  Future<List<MoodModel>> getAllMoods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${Constants.apiUrl}/moods'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[MoodService] Fetch all moods');
      print('[MoodService] Status: ${response.statusCode}');
      print('[MoodService] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('data') && data['data'] is List) {
          final List<dynamic> moodsJson = data['data'];
          return moodsJson.map((json) => MoodModel.fromJson(json)).toList();
        } else {
          print("[MoodService] API không trả về data hợp lệ");
        }
      }
      return [];
    } catch (e) {
      print('[MoodService] Lỗi getAllMoods: $e');
      return [];
    }
  }

  Future<String?> analyzeStats(List<Map<String, dynamic>> stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      final body = {"stats": stats};

      final res = await http.post(
        Uri.parse("${Constants.apiUrl}/ai/analyze-stats"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      print("[MoodService] analyzeStats Status: ${res.statusCode}");
      print("[MoodService] analyzeStats Body: ${res.body}");

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return json['suggestion'] ?? "Không có gợi ý";
      } else {
        print("[MoodService] Lỗi: ${res.body}");
      }
    } catch (e) {
      print("Error analyzeStats: $e");
    }
    return null;
  }
}