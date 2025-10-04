// Tạo model để xử lý dữ liệu cài đặt từ API.
//lib/models/setting_model.dart

class SettingModel {
  final int? id;
  final int userId;
  String language;
  String theme;
  String fontSize;
  String? colorTheme;
  bool notifyDaily;

  SettingModel({
    this.id,
    required this.userId,
    required this.language,
    required this.theme,
    required this.fontSize,
    this.colorTheme,
    required this.notifyDaily,
  });

  factory SettingModel.fromJson(Map<String, dynamic> json) {
    return SettingModel(
      id: json['id'],
      userId: json['user_id'],
      language: json['language'],
      theme: json['theme'],
      fontSize: json['font_size'],
      colorTheme: json['color_theme'],
      notifyDaily: json['notify_daily'] == 1 || json['notify_daily'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'theme': theme,
      'font_size': fontSize,
      'color_theme': colorTheme,
      'notify_daily': notifyDaily,
    };
  }

  SettingModel copyWith({
    String? language,
    String? theme,
    String? fontSize,
    String? colorTheme,
    bool? notifyDaily,
  }) {
    return SettingModel(
      id: id,
      userId: userId,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      colorTheme: colorTheme ?? this.colorTheme,
      notifyDaily: notifyDaily ?? this.notifyDaily,
    );
  }
}