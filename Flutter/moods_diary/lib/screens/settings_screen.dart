// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:moods_diary/screens/dieukhoan_screen.dart';
import 'package:moods_diary/utils/thongbao_snackbar.dart';
import 'package:provider/provider.dart';
import '../providers/setting_provider.dart';
import '../widgets/user_sayhello.dart';
import '../widgets/auto_text.dart';
import '../widgets/setting_options.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  Color _hexToColor(String hexColor) {
    if (hexColor.startsWith('#')) {
      hexColor = hexColor.substring(1);
    }
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        final Color selectedColor = settings.colorTheme != null
            ? _hexToColor(settings.colorTheme!)
            : Theme.of(context).colorScheme.primary;

        return Scaffold(
          // ignore: deprecated_member_use
          backgroundColor: selectedColor.withOpacity(0.2),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UserSayHello(),
                const SizedBox(height: 15),

                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, // Căn giữa Row
                        mainAxisSize: MainAxisSize.min, // Giới hạn kích thước Row theo nội dung
                        children: [
                          AutoText(
                            "CÀI ĐẶT",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(width: 5), // Khoảng cách giữa Icon và Text
                          Icon(
                            Icons.settings, 
                            size: 30, 
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                
                // Gọi các phương thức tĩnh để hiển thị từng tùy chọn
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white, // Background màu trắng
                    borderRadius: BorderRadius.circular(8), // Bo góc
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