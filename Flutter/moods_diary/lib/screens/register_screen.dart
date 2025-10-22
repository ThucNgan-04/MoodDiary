import 'package:flutter/material.dart';
import 'package:moods_diary/utils/thongbao_snackbar.dart';
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
  final _formKey = GlobalKey<FormState>(); 
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return; // ktra email hợp lệ

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      final result = await AuthService().register(name, email, password);

      if (!mounted) return;

      if (result["success"] == true) {
        final token = result["token"];
        final user = result["user"];

        await AuthService().saveAuthData(token, user["name"], user["email"]);

        final settingProvider = Provider.of<SettingProvider>(context, listen: false);
        await settingProvider.setUsername(user["name"]);
        await settingProvider.loadRemoteSettings();

        await showSnackBarAutoText(
          context,
          "Đăng ký thành công! Vui lòng đăng nhập.",
        );

        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: AutoText(result["message"] ?? "Đăng ký thất bại.")),
        // );
        await showSnackBarAutoText(
          context,
          result['message'] ?? "Đăng ký thất bại.",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: AutoText("Có lỗi xảy ra: $e")),
      // );
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
      // ignore: deprecated_member_use
      backgroundColor: colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form( //bọc trong Form
            key: _formKey,
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
                        // ignore: deprecated_member_use
                        color: colorScheme.onBackground.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 32),

                _buildTextField(
                  controller: _nameController,
                  hintText: "Tên đăng nhập",
                  icon: Icons.person,
                  iconColor: const Color.fromARGB(255, 0, 0, 0),
                iconBackgroundColor: const Color.fromARGB(255, 59, 124, 255),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  hintText: "Email",
                  icon: Icons.email,
                  iconColor: const Color.fromARGB(255, 255, 190, 59),
                  iconBackgroundColor: const Color.fromARGB(223, 204, 129, 9),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _passwordController,
                  hintText: "Mật khẩu",
                  icon: Icons.lock,
                  isPassword: true,
                  iconColor: const Color.fromARGB(255, 230, 230, 230),
                  iconBackgroundColor: const Color.fromARGB(223, 186, 15, 208),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 55,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerUser,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), 
                      ),
                    ),
                    child: AutoText(
                      _isLoading ? "Đang xử lý..." : "ĐĂNG KÝ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AutoText(
                      "Bạn đã có tài khoản? ",
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: AutoText(
                        'Đăng nhập ngay',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 19, 119, 201),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    Color? iconColor, 
    Color? iconBackgroundColor,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField( 
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      validator: validator,
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
