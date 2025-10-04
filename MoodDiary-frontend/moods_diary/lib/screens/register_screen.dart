import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/setting_provider.dart';
import '../widgets/auto_text.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AutoText('Vui lòng nhập đầy đủ thông tin.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService().register(name, email, password);

      if (!mounted) return;

      if (result["success"] == true) {
        final token = result["token"];
        final user = result["user"];

        // Lưu token + tên người dùng
        await AuthService().saveAuthData(token, user["name"]);

        //Gọi SettingProvider để load cài đặt
        final settingProvider = Provider.of<SettingProvider>(context, listen: false);
        await settingProvider.setUsername(user["name"]);
        await settingProvider.loadRemoteSettings();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AutoText("Đăng ký thành công! Xin chào ${user["name"]}")),
        );

        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AutoText(result["message"] ?? "Đăng ký thất bại.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AutoText("Có lỗi xảy ra: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // ignore: deprecated_member_use
      backgroundColor: colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Icon(Icons.cloud, size: 90, color: colorScheme.primary),
              const SizedBox(height: 12),
              AutoText(
                'MOODDIARY',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
              ),
              AutoText(
                "Nhật ký cảm xúc",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      // ignore: deprecated_member_use
                      color: colorScheme.onBackground.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 32),

              // Tên đăng nhập
              _buildTextField(
                controller: _nameController,
                hintText: "Tên đăng nhập",
                icon: Icons.person,
              ),
              const SizedBox(height: 16),

              // Email
              _buildTextField(
                controller: _emailController,
                hintText: "Email",
                icon: Icons.email,
              ),
              const SizedBox(height: 16),

              // Mật khẩu
              _buildTextField(
                controller: _passwordController,
                hintText: "Mật khẩu",
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 24),

              // Nút đăng ký
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  child: AutoText(
                    _isLoading ? "Đang xử lý..." : "ĐĂNG KÝ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Đã có tài khoản
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AutoText("Bạn đã có tài khoản? "),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: AutoText(
                      'Đăng nhập ngay',
                      style: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
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
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.onPrimary, size: 22),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: colorScheme.onSurface,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
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
