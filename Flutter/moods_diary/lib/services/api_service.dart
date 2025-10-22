//api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class ApiService {
  Future<Map<String, dynamic>> _sendRequest(
      String method, String path, Map<String, dynamic>? data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      final url = Uri.parse('${Constants.apiUrl}$path');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      if (kDebugMode) {
        debugPrint('[API] $method $url');
        // Tạo bản sao của data để in log, KHÔNG in mật khẩu
        Map<String, dynamic>? logData;
        if (data != null){
          logData = Map.from(data);
            if (logData.containsKey('password')) {
                logData['password'] = '***Bí mật nha!***'; // Ẩn mật khẩu
            }
            if (logData.containsKey('old_password')) {
                logData['old_password'] = '***Xem bị ma bắt đấy!***';
            }
            if (logData.containsKey('new_password')) {
                logData['new_password'] = '***Không xem được đâu à nha!***';
            }
        }
        if(logData != null) debugPrint('[API] Payload: $logData');
      }

      http.Response response;
      if (method == 'POST') {
        response = await http.post(url, headers: headers, body: jsonEncode(data));
      } else if (method == 'PUT') {
        response = await http.put(url, headers: headers, body: jsonEncode(data));
      } else {
        response = await http.get(url, headers: headers);
      }

      final responseData = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (kDebugMode) {
        debugPrint('[API] Status: ${response.statusCode}');

        //Ẩn Token khỏi Response log
        Map<String, dynamic>? logResponse;
        if (responseData.containsKey('token')) {
            logResponse = Map.from(responseData);
            logResponse['token'] = '***CENSORED_TOKEN***'; // Ẩn Token
        }
        debugPrint('[API] Response: ${logResponse ?? responseData}');
      }

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'status': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('API call error on $path: $e');
      }
      return {
        'success': false,
        'status': 500,
        'data': {'message': 'Lỗi không xác định khi gọi API.'},
      };
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    return _sendRequest('GET', path, null);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    return _sendRequest('POST', path, data);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> data) async {
    return _sendRequest('PUT', path, data);
  }
}