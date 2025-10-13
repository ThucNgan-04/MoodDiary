import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../models/setting_model.dart';

class SettingProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  double _fontSizeScale = 0.0; // Biến để lưu tỉ lệ phóng to thu nhỏ font

  SettingModel _settings = SettingModel(
    userId: 0,
    language: 'vi',
    theme: 'light',
    fontSize: 'medium',
    colorTheme: '#FFC0CB',
    notifyDaily: true,
  );

  String? _username;
  String? _avatarPath;

  SettingModel get settings => _settings;
  String? get username => _username;
  String? get avatarPath => _avatarPath;

  

  double get fontSizeScale => _fontSizeScale;

  SettingProvider() {
    _loadSettingsOnStartup();
  }

  // Phương thức mới để tải cài đặt khi khởi động ứng dụng
  Future<void> _loadSettingsOnStartup() async {
    final prefs = await SharedPreferences.getInstance();
    
    //Tải dữ liệu người dùng Local (Avatar, Username)
    await loadLocalUserData(); 

    //Tải cài đặt (SettingsModel)
    if (prefs.getString(Constants.tokenKey) != null) {
      // Đã đăng nhập -> Tải từ Server
      final serverSettings = await _authService.getSettings();
      if (serverSettings != null) {
        _settings = serverSettings;
        // Tùy chọn: Lưu lại cài đặt server vào Local
        await _saveLocalSettings(); 
      }
    } else {
      // Chưa đăng nhập -> Tải cài đặt Local
      await _loadLocalSettings();
    }
    
    notifyListeners();
  }

Future<void> loadLocalUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    _username = prefs.getString(Constants.usernameKey);
    _avatarPath = prefs.getString('avatarPath');

    debugPrint(" Đọc SharedPreferences: username=$_username, avatar=$_avatarPath");
    notifyListeners(); 
  }
  
  // Phương thức tải cài đặt model (ngôn ngữ, theme...) từ local
  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final savedFontSizeString = prefs.getString(Constants.fontSizeKey) ?? 'medium';
    _fontSizeScale = _stringToScale(savedFontSizeString);
    
    _settings = SettingModel(
      userId: 0,
      language: prefs.getString(Constants.languageKey) ?? 'vi',
      theme: prefs.getString(Constants.themeKey) ?? 'light',
      fontSize: prefs.getString(Constants.fontSizeKey) ?? 'medium',
      colorTheme: prefs.getString(Constants.colorThemeKey) ?? '#FFC0CB',
      notifyDaily: prefs.getBool(Constants.notifyDailyKey) ?? true,
    );
  }

  double _stringToScale(String fontSize) {
    switch (fontSize) {
      case 'small':
        return -1.0;
      case 'large':
        return 1.0;
      case 'medium':
      default:
        return 0.0;
    }
  }

  // ignore: unused_element
  String _scaleToString(double scale) {
    if (scale < 0) return 'small';
    if (scale > 0) return 'large';
    return 'medium';
  }

  Future<void> _saveLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.languageKey, _settings.language);
    await prefs.setString(Constants.themeKey, _settings.theme);
    await prefs.setString(Constants.fontSizeKey, _settings.fontSize);
    await prefs.setString(Constants.colorThemeKey, _settings.colorTheme ?? '#FFC0CB');
    await prefs.setBool(Constants.notifyDailyKey, _settings.notifyDaily);
  }

  // Cập nhật avatar và lưu vào bộ nhớ
  Future<void> setAvatar(String path) async {
    _avatarPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatarPath', path);
    notifyListeners();
  }

  // Xóa avatar (về mặc định)
  Future<void> clearAvatar() async {
    _avatarPath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('avatarPath');
    notifyListeners();
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

    if (fontSize != null) {
      _fontSizeScale = _stringToScale(fontSize);
    }
    
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

  Future<void> setUsername(String? name) async {
    _username = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      await prefs.setString(Constants.usernameKey, name);
    }
    debugPrint("setUsername: $name");
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

  double getScaledFontSize(double baseSize) {
    // Độ lệch cỡ chữ cho mỗi bước (ví dụ: 4.0 điểm)
    const double sizeStep = 4.0; 
    return baseSize + (_fontSizeScale * sizeStep);
  }
}
