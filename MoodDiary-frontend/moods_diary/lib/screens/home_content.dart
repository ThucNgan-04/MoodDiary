import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/setting_provider.dart';
import '../widgets/auto_text.dart';
import '../widgets/user_sayhello.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeContent> {
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
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  
  Widget build(BuildContext context) {
    return Consumer<SettingProvider>(
      builder: (context, provider, child) {
        final username = provider.username ?? "Người dùng";
        final settings = provider.settings;

        final Color selectedColor = settings.colorTheme != null
            ? _hexToColor(settings.colorTheme!)
            : Theme.of(context).colorScheme.primary;
        final Color primaryColor = Theme.of(context).colorScheme.primary;

        return Scaffold(
          // ignore: deprecated_member_use
          backgroundColor: selectedColor.withOpacity(0.2),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UserSayHello(),
                const SizedBox(height: 20),
                AutoText(
                  "Trang chủ",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: selectedColor,
                        fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Center(
                  child: Column(
                    children: [
                      // Ảnh đại diện
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      AutoText(
                        "Ảnh đại diện",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),

                      // Ô tên
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Tên',
                          labelStyle: TextStyle(
                              color: selectedColor,
                              fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        // SỬ DỤNG BIẾN USERNAME Ở ĐÂY
                        controller: TextEditingController(text: username), 
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),

                      // Ô email
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                              color: selectedColor,
                              fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        controller:
                            TextEditingController(text: "banana@gmail.com"),
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),

                      // Nút đăng xuất
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const AutoText("Đăng xuất"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Nút đổi mật khẩu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const AutoText("Đổi mật khẩu"),
                        ),
                      ),
                    ],
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
