import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:moods_diary/utils/constants.dart';
import 'package:moods_diary/utils/thongbao_snackbar.dart';
import 'package:moods_diary/widgets/user_tieude.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/setting_provider.dart';
import '../widgets/auto_text.dart';
// ignore: unused_import
import '../widgets/user_sayhello.dart';
import '../widgets/user_avatar.dart';
import '../services/auth_service.dart';

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
                const UserTieude(),
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
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255), 
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------- Tên đăng nhập --------
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
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.save, color: selectedColor),
                              onPressed: _updateUsername,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // -------- Email --------
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
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: emailController,
                          readOnly: true,
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
