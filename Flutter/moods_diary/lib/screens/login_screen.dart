import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:moods_diary/utils/thongbao_snackbar.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/setting_provider.dart';
import '../widgets/auto_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // ignore: unused_field
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      await showSnackBarAutoText(
        context,
        "Vui lòng nhập đầy đủ email và mật khẩu.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService().login(email, password);

      if (!mounted) return;
      if (result["success"] == true) {
        final user = result["user"];

        final prefs = await SharedPreferences.getInstance();
        prefs.setString(Constants.tokenKey, result["token"]);
        prefs.setInt('user_id', user["id"]);

        // Gọi SettingProvider để tải cài đặt từ server
        final settingProvider = Provider.of<SettingProvider>(context, listen: false);
        await settingProvider.setUsername(user["name"]);
        await settingProvider.loadRemoteSettings();

        settingProvider.loadLocalUserData();

        await showSnackBarAutoText(
          context,
          "Đăng nhập thành công! Xin chào ${user["name"]}",
        );

        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        final message = result["message"] ?? "Đăng nhập thất bại.";
        await showSnackBarAutoText(
          context,
          message,
          isError: true,
        );      
      }
    } catch (e) {
      if (!mounted) return;
      await showSnackBarAutoText(
        context,
        "Có lỗi xảy ra: $e",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Icon(Icons.cloud, size: 110, color: colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                'MOODDIARY',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  shadows: [
                          // Viền trên
                          Shadow(offset: const Offset(0, -1.5), color: Colors.white), 
                          // Viền dưới
                          Shadow(offset: const Offset(0, 1.5), color: Colors.white), 
                          // Viền trái
                          Shadow(offset: const Offset(-1.5, 0), color: Colors.white), 
                          // Viền phải
                          Shadow(offset: const Offset(1.5, 0), color: Colors.white),
                          // Viền chéo (tùy chọn để làm viền dày hơn)
                          Shadow(offset: const Offset(1, 1), color: Colors.white),
                          Shadow(offset: const Offset(-1, -1), color: Colors.white),
                  ],
                ),
              ),
              AutoText(
                "Nhật ký cảm xúc",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                context: context,
                controller: _emailController,
                hintText: "Email",
                icon: Icons.email,
                iconColor: const Color.fromARGB(255, 255, 190, 59),
                iconBackgroundColor: const Color.fromARGB(223, 204, 129, 9),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                context: context,
                controller: _passwordController,
                hintText: "Mật khẩu",
                icon: Icons.lock,
                isPassword: true,
                iconColor: const Color.fromARGB(255, 230, 230, 230),
                iconBackgroundColor: const Color.fromARGB(223, 186, 15, 208),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 55,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginUser,
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), 
                    ),
                  ),
                  child: AutoText(
                    _isLoading ? "Đang xử lý..." : "ĐĂNG NHẬP",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4, // Khoảng cách giữa các phần tử trên cùng một dòng
                runSpacing: 4, // Khoảng cách giữa các dòng
                children: [
                  const AutoText("Bạn chưa có tài khoản? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: AutoText(
                      'Đăng ký ngay',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 19, 119, 201),
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    Color? iconColor, 
    Color? iconBackgroundColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconBackgroundColor ?? colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? colorScheme.onPrimary, size: 22),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: colorScheme.onSurface,
                ),
                onPressed: () {
                  setState(() => _obscureText = !_obscureText);
                },
              )
            : null,
          border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}