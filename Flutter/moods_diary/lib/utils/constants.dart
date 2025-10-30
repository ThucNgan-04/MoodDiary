//lib/utils/constants.dart
// Tệp này chứa các ĐỊa chỉ kết nối

class Constants {
  static const String baseUrl = 'http://192.168.10.238:8000/api';
  // Đối với Android Emulator, dùng 10.0.2.2
  //điện thoại thật, dùng IP của máy tính

  //Base URL cho Public Assets/Storage (KHÔNG cần /api)
  static const String baseStorageUrl = 'http://192.168.10.238:8000';
  static const String apiUrl = baseUrl;
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String logoutEndpoint = '/logout';
  static const String changepasswordEndpoint = "/change-password";
  static const String settingsEndpoint = '/settings';

  //Các khóa mới cho cài đặt
  static const String tokenKey = 'token';
  static const String usernameKey = 'user_name';
  static const String languageKey = 'language';
  static const String themeKey = 'theme';
  static const String fontSizeKey = 'font_size';
  static const String colorThemeKey = 'color_theme';
  static const String avatarKey = 'avatarPath';
  static const String notifyDailyKey = 'notify_daily';
}