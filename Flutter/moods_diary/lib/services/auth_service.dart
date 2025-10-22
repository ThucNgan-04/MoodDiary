import 'dart:io';
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

        final user = data['user'];
        final String? avatarFilename = user['avatar'];
        String? fullAvatarUrl;

        if (avatarFilename != null) {
          fullAvatarUrl = '${Constants.apiUrl}/storage/avatars/$avatarFilename'; 
        } 
        await saveAuthData(
          data['token'],
          user['name'] ?? user['username'] ?? 'Người dùng',
          user['email'],
          fullAvatarUrl,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', user['id']); // ✅ Lưu user_id để dùng cho huy hiệu


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
        
        final String? avatarFilename = data['user']['avatar'];
        String? fullAvatarUrl;

        if (avatarFilename != null) {
          final baseUrl = Constants.apiUrl.replaceAll('/api', '');
          fullAvatarUrl = '$baseUrl/storage/avatars/$avatarFilename';
        }

        await saveAuthData(
          data['token'],
          data['user']['name'] ?? data['user']['username'] ?? 'Người dùng',
          data['user']['email'],
          fullAvatarUrl,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', data['user']['id']); // ✅ lưu user_id


        if (kDebugMode) {
          debugPrint('>>> Toàn bộ dữ liệu login trả về: ${jsonEncode(data)}');
          debugPrint('>>> Dữ liệu user: ${jsonEncode(data['user'])}');
        }

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
        await prefs.remove('cached_moods');
        await prefs.remove('user_id');
        await prefs.remove('cached_badges');
        debugPrint('Đã xóa toàn bộ dữ liệu SharedPreferences khi logout');
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
  Future<void> saveAuthData(String token, String username, String email, [String? avatarUrl]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.tokenKey, token);
    await prefs.setString(Constants.usernameKey, username);
    await prefs.setString('email', email);
    if (avatarUrl != null) {
      await prefs.setString('avatarPath', avatarUrl);
    }else {
      await prefs.remove('avatarPath');
    }
    if (kDebugMode) {
      debugPrint("Đã lưu username: $username - email: $email - avatar: $avatarUrl");
    }
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  //--------------- cập nhật tên người dùng---------------
  Future<Map<String, dynamic>> updateProfile(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(Constants.tokenKey);

    if (token == null) {
      return {
        'success': false,
        'message': 'Không tìm thấy token. Vui lòng đăng nhập lại.'
      };
    }

    final url = Uri.parse('${Constants.baseUrl}/user/profile');

    try {
      final response = await http.put(url,
        headers: {'Authorization': 'Bearer $token','Accept': 'application/json',},
        body: {'name': newName,},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Cập nhật thành công
        // Lưu lại tên mới vào SharedPreferences luôn cho đồng bộ
        await prefs.setString(Constants.usernameKey, data['user']['name']);
        return {
          'success': true,
          'message': data['message'],
          'user': data['user']
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Lỗi cập nhật hồ sơ.'
        };
      }
    } catch (e) {
      debugPrint('Lỗi khi cập nhật hồ sơ: $e');
      return {'success': false, 'message': 'Không thể kết nối đến server.'};
    }
  }
}

//----------avatar-------------
class UserService {
  Future<String?> uploadAvatar(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(Constants.tokenKey);

    final uri = Uri.parse('${Constants.apiUrl}/user/avatar');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      print("Upload OK: $respStr");

      try {
        final data = jsonDecode(respStr);
        return data['avatar_url'] as String?;
      } catch (e) {
        if (kDebugMode) debugPrint('Không thể giải mã JSON avatar: $e');
        return null;
      }
    } else {
      print("Upload lỗi: ${response.statusCode}");
      return null;
    }
  }
}