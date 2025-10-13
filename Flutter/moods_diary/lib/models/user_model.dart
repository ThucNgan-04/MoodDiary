// Tạo model để xử lý dữ liệu người dùng từ API.
//lib/models/user_model.dart

import 'setting_model.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final SettingModel? setting;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.setting,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      setting: json['setting'] != null ? SettingModel.fromJson(json['setting']) : null,
    );
  }
}