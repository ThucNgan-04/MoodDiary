//lib/utils/constants.dart
// Tệp này chứa các ĐỊa chỉ kết nối

class Constants {
  // static const String baseUrl = 'http://172.20.10.4:8000/api';
  // // Đối với Android Emulator, dùng 10.0.2.2
  // //điện thoại thật, dùng IP của máy tính

  // //Base URL cho Public Assets/Storage (KHÔNG cần /api)
  // static const String baseStorageUrl = 'http://172.20.10.4:8000';

  //static const String _defaultUrl = 'http://10.0.2.2:8000/api'; 
  static const String _defaultUrl = 'http://192.168.100.23:8000/api'; 


  // Lấy BASE_URL được truyền vào, hoặc dùng giá trị mặc định
  static const String baseUrl = 
      String.fromEnvironment('BASE_URL', defaultValue: _defaultUrl);

  // Base Storage URL KHÔNG cần /api
  static const String baseStorageUrl = 
      //String.fromEnvironment('BASE_URL_STORAGE', defaultValue: 'http://10.0.2.2:8000');
      String.fromEnvironment('BASE_URL_STORAGE', defaultValue: 'http://192.168.100.23:8000');

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