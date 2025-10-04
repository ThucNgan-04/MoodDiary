import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../models/setting_model.dart';

class SettingProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  SettingModel _settings = SettingModel(
    userId: 0,
    language: 'vi',
    theme: 'light',
    fontSize: 'medium',
    colorTheme: '#FFC0CB',
    notifyDaily: true,
  );

  String? _username;

  SettingModel get settings => _settings;
  String? get username => _username;

  SettingProvider() {
    _loadSettingsOnStartup();
  }

  // Phương thức mới để tải cài đặt khi khởi động ứng dụng
  Future<void> _loadSettingsOnStartup() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString(Constants.usernameKey);

    // Kiểm tra xem người dùng đã đăng nhập chưa
    if (prefs.getString(Constants.tokenKey) != null) {
      // Tải cài đặt từ server
      final serverSettings = await _authService.getSettings();
      if (serverSettings != null) {
        _settings = serverSettings;
      }
    } else {
      // Nếu chưa đăng nhập, tải từ bộ nhớ cục bộ
      await _loadLocalSettings();
    }
    notifyListeners();
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _settings = SettingModel(
      userId: 0,
      language: prefs.getString(Constants.languageKey) ?? 'vi',
      theme: prefs.getString(Constants.themeKey) ?? 'light',
      fontSize: prefs.getString(Constants.fontSizeKey) ?? 'medium',
      colorTheme: prefs.getString(Constants.colorThemeKey) ?? '#FFC0CB',
      notifyDaily: prefs.getBool(Constants.notifyDailyKey) ?? true,
    );
  }

  Future<void> _saveLocalAndRemoteSettings() async {
    // Lưu vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.languageKey, _settings.language);
    await prefs.setString(Constants.themeKey, _settings.theme);
    await prefs.setString(Constants.fontSizeKey, _settings.fontSize);
    await prefs.setString(Constants.colorThemeKey, _settings.colorTheme ?? '#FFC0CB');
    await prefs.setBool(Constants.notifyDailyKey, _settings.notifyDaily);

    // Lưu vào server nếu người dùng đã đăng nhập
    if (prefs.getString(Constants.tokenKey) != null) {
      await _authService.updateSettings(_settings);
    }
  }

  // Cập nhật cài đặt
  Future<void> updateSetting({
    String? language,
    String? theme,
    String? fontSize,
    String? colorTheme,
    bool? notifyDaily,
  }) async {
    _settings = _settings.copyWith(
      language: language,
      theme: theme,
      fontSize: fontSize,
      colorTheme: colorTheme,
      notifyDaily: notifyDaily,
    );
    notifyListeners();

    // Gọi hàm lưu cả cục bộ và từ xa
    await _saveLocalAndRemoteSettings();
  }

  Future<void> setUsername(String newUsername) async {
    _username = newUsername;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.usernameKey, newUsername);
    notifyListeners();
  }

  Future<void> clearUsername() async {
    _username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Constants.usernameKey);
    notifyListeners();
  }

  // phương thức này để tải lại cài đặt từ server
  Future<void> loadRemoteSettings() async {
    final serverSettings = await _authService.getSettings();
    if (serverSettings != null) {
      _settings = serverSettings;
      notifyListeners();
      // Tùy chọn: Lưu lại cài đặt từ server vào bộ nhớ cục bộ
      await _saveLocalAndRemoteSettings();
    }
  }
}
