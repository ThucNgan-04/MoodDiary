// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:moods_diary/screens/dieukhoan_screen.dart';

import 'login_screen.dart';
import '../services/auth_service.dart';
import 'change_password_screen.dart';
import 'package:moods_diary/utils/thongbao_snackbar.dart';
import 'package:provider/provider.dart';
import '../providers/setting_provider.dart';
// ignore: unused_import
import '../widgets/user_sayhello.dart';
import '../widgets/auto_text.dart';
import '../widgets/setting_options.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  Color _hexToColor(String hexColor) {
    if (hexColor.startsWith('#')) {
      hexColor = hexColor.substring(1);
    }
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Provider.of<SettingProvider>(context, listen: false).clearUsername();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        final Color selectedColor = settings.colorTheme != null
            ? _hexToColor(settings.colorTheme!)
            : Theme.of(context).colorScheme.primary;
        
        final Color primaryColor = selectedColor;
        
        final bool isDarkMode = settings.theme == 'dark';

        final Color backgroundColor = isDarkMode
          ? selectedColor.withOpacity(0.2)
          : Colors.white;
        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UserSayHello(),
                const SizedBox(height: 20),
                Text(
                  "Cài đặt ⚙️",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                // Gọi các phương thức tĩnh để hiển thị từng tùy chọn
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8), 
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gọi các phương thức tĩnh để hiển thị từng tùy chọn
                      SettingOptions.buildLanguageSelector(context),
                      SettingOptions.buildColorSelector(context),
                      SettingOptions.buildThemeSwitch(context),
                      SettingOptions.buildFontSizeSlider(context),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await showSnackBarAutoText(
                        context,
                        "Đã lưu cài đặt",
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedColor,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: AutoText(
                      "Lưu cài đặt",
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nút đăng xuất
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4), 
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3), 
                            ),
                          ],
                        ),
                        child:  SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const AutoText("Đăng xuất",
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Nút đổi mật khẩu
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4), 
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3), 
                            ),
                          ],
                        ),
                        child:  SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChangePasswordScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const AutoText(
                              "Đổi mật khẩu",
                              style: TextStyle(color: Colors.white), ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                Container(
                  width: 650,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: GestureDetector( 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DieukhoanScreen(
                            title: "Điều khoản và Dịch vụ",
                            contentKey: 'dieukhoan', // Key để lấy nội dung Điều khoản
                          ),
                        ),
                      );
                    }, 
                    child: Padding( 
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align( 
                        alignment: Alignment.centerLeft,
                        child: AutoText(
                          "Điều khoản và dịch vụ",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 19,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                Container(
                  width: 650,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: GestureDetector( 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DieukhoanScreen(
                            title: "Chính sách Bảo mật",
                            contentKey: 'chinhsach', // Key để lấy nội dung Chính sách
                          ),
                        ),
                      );
                    }, 
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoText(
                          "Chính sách bảo mật",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 10, 155, 0), 
                            fontSize: 19,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}