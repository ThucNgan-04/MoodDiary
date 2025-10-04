import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import '../models/setting_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  //------------------- Đăng ký -------------------
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final result = await _api.post(Constants.registerEndpoint, {
        'name': name,
        'email': email,
        'password': password,
      });

      if (result['status'] == 201) {
        final data = result['data'];
        return {
          'success': true,
          'message': data['message'],
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': result['data']['error'] ??
              result['data']['message'] ??
              'Lỗi đăng ký không xác định',
        };
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Lỗi trong quá trình đăng ký: $e');
      return {'success': false, 'message': 'Không thể kết nối với máy chủ'};
    }
  }

  //------------------- Đăng nhập -------------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final result = await _api.post(Constants.loginEndpoint, {
        'email': email,
        'password': password,
      });

      if (result['status'] == 200) {
        final data = result['data'];
        return {
          'success': true,
          'message': data['message'],
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': result['data']['error'] ?? 'Sai email hoặc mật khẩu',
        };
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Lỗi trong quá trình đăng nhập: $e');
      return {'success': false, 'message': 'Không thể kết nối với máy chủ'};
    }
  }

  //------------------- Đăng xuất -------------------
  Future<bool> logout() async {
    try {
      final result = await _api.post(Constants.logoutEndpoint, {});
      if (result['status'] == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(Constants.tokenKey);
        await prefs.remove(Constants.usernameKey);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Lỗi trong quá trình đăng xuất: $e');
      return false;
    }
  }

  //------------------- Đổi MK -------------------
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${Constants.apiUrl}${Constants.changepasswordEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // cần token mới đổi được mật khẩu
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        // Nếu đổi mật khẩu thành công -> đăng xuất
        await prefs.remove(Constants.tokenKey);
        await prefs.remove(Constants.usernameKey);
        return true;
      } else {
        debugPrint('[changePassword] Error: ${response.body}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Lỗi đổi mật khẩu: $e');
      return false;
    }
  }

  //------------------- Lấy cài đặt -------------------
  Future<SettingModel?> getSettings() async {
    try {
      final result = await _api.get(Constants.settingsEndpoint);

      if (result['status'] == 200) {
        final responseData = result['data'];

        if (responseData != null && responseData['settings'] != null) {
          return SettingModel.fromJson(responseData['settings']);
        } else {
          if (kDebugMode) debugPrint("Không tìm thấy key 'settings' trong response");
          return null;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Lỗi trong quá trình lấy cài đặt: $e');
      return null;
    }
  }

  //------------------- Cập nhật cài đặt -------------------
  Future<bool> updateSettings(SettingModel settings) async {
    try {
      final result = await _api.put(Constants.settingsEndpoint, settings.toJson());
      return result['status'] == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('Lỗi trong quá trình cập nhật cài đặt: $e');
      return false;
    }
  }

  //------------------- Lưu token và username -------------------
  Future<void> saveAuthData(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.tokenKey, token);
    await prefs.setString(Constants.usernameKey, username);
  }
}
