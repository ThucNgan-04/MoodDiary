// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
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
          backgroundColor: selectedColor.withOpacity(0.1),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UserSayHello(),
                const SizedBox(height: 20),

                AutoText(
                  "Cài đặt",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: selectedColor,
                  ),
                ),
                const SizedBox(height: 10),

                // Gọi các phương thức tĩnh để hiển thị từng tùy chọn
                SettingOptions.buildLanguageSelector(context),
                Divider(color: selectedColor),
                SettingOptions.buildColorSelector(context),
                Divider(color: selectedColor),
                SettingOptions.buildThemeSwitch(context),
                Divider(color: selectedColor),
                SettingOptions.buildFontSizeSlider(context),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: AutoText("Đã lưu cài đặt")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedColor,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const AutoText("Lưu cài đặt"),
                  ),
                ),
                const SizedBox(height: 20),

                ListTile(
                  title: AutoText(
                    "Điều khoản và dịch vụ",
                    style: TextStyle(
                      color: selectedColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () => debugPrint("Điều khoản và dịch vụ"),
                ),
                ListTile(
                  title: AutoText(
                    "Chính sách bảo mật",
                    style: TextStyle(
                      color: selectedColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () => debugPrint("Chính sách bảo mật"),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
