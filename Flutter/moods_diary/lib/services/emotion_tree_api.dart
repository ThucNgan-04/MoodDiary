import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emotion_tree_model.dart';
import '../utils/constants.dart';

// Class chuyên trách nhiệm vụ gọi API (stateless)
class EmotionTreeApi {
  final String _baseUrl = Constants.apiUrl;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(Constants.tokenKey) ?? 'DUMMY_TOKEN_PLEASE_LOGIN'; 
    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<EmotionTree> getTreeStatus() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/tree/status'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    final treeData = jsonResponse['data'];
      return EmotionTree.fromJson(treeData); 
    } else {
       if (response.statusCode == 401) {
          throw Exception('Lỗi xác thực. Vui lòng đăng nhập lại.');
       }
       throw Exception('Không thể tải trạng thái cây: ${response.statusCode}');
    }
  }

   // 2. API Trồng cây (POST /api/tree/plant)
  Future<EmotionTree> plantTree({required String seedType}) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/tree/plant'),
      headers: headers,
      body: json.encode({'seed_type': seedType}),
    );    
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
       final treeStatus = jsonResponse['tree_status'];
       return EmotionTree.fromJson(treeStatus); 
    } else {
        if (response.statusCode == 401) {
          throw Exception('Lỗi xác thực. Vui lòng đăng nhập lại.');
      }
      throw Exception('Lỗi khi trồng cây: ${response.statusCode} - ${response.body}');
     }
   }

   Future<EmotionTree> logDiary({required String emotionType}) async {
    final headers = await _getHeaders();
    final response = await http.post(
       Uri.parse('$_baseUrl/tree/log'),
      headers: headers,
      body: json.encode({'emotion_type': emotionType}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final treeStatus = jsonResponse['tree_status'];
      return EmotionTree.fromJson(treeStatus);
    } else {
        if (response.statusCode == 401) {
        throw Exception('Lỗi xác thực. Vui lòng đăng nhập lại.');
      }
      throw Exception('Lỗi khi ghi nhật ký: ${response.statusCode} - ${response.body}');
    }
  }
}