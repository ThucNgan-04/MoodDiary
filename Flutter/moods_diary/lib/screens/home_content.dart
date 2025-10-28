import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:moods_diary/utils/constants.dart';
import 'package:moods_diary/utils/thongbao_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/setting_provider.dart';
import '../widgets/auto_text.dart';
import '../widgets/user_sayhello.dart';
import '../widgets/user_avatar.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeContent> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  String username = '';
  String email = '';
  String avatarPath = '';
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(Constants.usernameKey) ?? '';
    final savedEmail = prefs.getString('email') ?? '';
    final savedAvatar = prefs.getString('avatarPath') ?? '';

    setState(() {
      username = savedName;
      email = savedEmail;
      avatarPath = savedAvatar;
      usernameController.text = savedName;
      emailController.text = savedEmail;
    });

    final provider = Provider.of<SettingProvider>(context, listen: false);
    provider.setUsername(savedName);
    provider.setAvatar(savedAvatar);
    
  }

  Color _hexToColor(String hexColor) {
    if (hexColor.startsWith('#')) hexColor = hexColor.substring(1);
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse(hexColor, radix: 16));
  }


  Future<void> _updateUsername() async {
    final newUsername = usernameController.text.trim();
    if (newUsername.isEmpty) {
      await showSnackBarAutoText(
        context,
        "Tên đăng nhập không được để trống!",
        isError: true,
      );
      return;
    }

    final result = await _authService.updateProfile(newUsername);
    if (result['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Constants.usernameKey, newUsername);

      if (mounted) {
        Provider.of<SettingProvider>(context, listen: false)
            .setUsername(newUsername);
        setState(() => username = newUsername);
        await showSnackBarAutoText(
          context,
          "Cập nhật tên đăng nhập thành công!",
        );
      }
    } else {
      if (mounted) {
        await showSnackBarAutoText(
          context,
          result['message'] ?? 'Lỗi khi cập nhật tên đăng nhập.',
          isError: true,
        );
      }
    }
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

  void _chooseAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      final String? resultUrl = await _userService.uploadAvatar(imageFile);

      if (resultUrl != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('avatarPath', resultUrl);

        if (mounted) {
          Provider.of<SettingProvider>(context, listen: false)
              .setAvatar(resultUrl);
          setState(() => avatarPath = resultUrl);

          await showSnackBarAutoText(
            context,
            'Cập nhật ảnh đại diện thành công!',
            isError: false,
          );
        }
      } else {
        if (mounted) {
          await showSnackBarAutoText(
            context,
            'Lỗi khi tải ảnh lên server.',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingProvider>(
      builder: (context, provider, child) {
        final displayName = provider.username ?? "Người dùng";
        final settings = provider.settings;

        final Color selectedColor = settings.colorTheme != null
            ? _hexToColor(settings.colorTheme!)
            : Theme.of(context).colorScheme.primary;
        final Color primaryColor = Theme.of(context).colorScheme.primary;

        return Scaffold(
          backgroundColor: selectedColor.withOpacity(0.2),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UserSayHello(),
                const SizedBox(height: 20),

                Center(
                  child: Column(
                    children: [
                      UserAvatar(
                        radius: 80,
                        onTap: _chooseAvatar,
                      ),
                      const SizedBox(height: 8),
                      const AutoText(
                        "Ảnh đại diện",
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: AutoText(
                          "Tên Đăng Nhập",
                          style: TextStyle(
                            color: selectedColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3), // Màu bóng
                              spreadRadius: 1, // Độ lan rộng nhẹ
                              blurRadius: 4, // Độ mờ
                              offset: const Offset(0, 2), // Đổ bóng xuống dưới
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: usernameController,
                          readOnly: false,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 17,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white, // Nền trắng của TextField
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.save, color: selectedColor),
                              tooltip: 'Lưu thay đổi',
                              onPressed: _updateUsername,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: AutoText(
                          "Email",
                          style: TextStyle(
                            color: selectedColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3), // Màu bóng
                              spreadRadius: 1, // Độ lan rộng nhẹ
                              blurRadius: 4, // Độ mờ
                              offset: const Offset(0, 2), // Đổ bóng xuống dưới
                            ),
                          ],
                        ),
                        child:  TextField(
                          controller: emailController,
                          readOnly: true,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 17,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
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
                              color: primaryColor.withOpacity(0.4), // Dùng màu chủ đạo để đổ bóng
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3), // Đổ bóng xuống dưới
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
                              color: primaryColor.withOpacity(0.4), // Dùng màu chủ đạo để đổ bóng
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3), // Đổ bóng xuống dưới
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
