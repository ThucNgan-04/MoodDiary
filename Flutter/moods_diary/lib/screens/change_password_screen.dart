import 'package:flutter/material.dart';
import 'package:moods_diary/services/auth_service.dart';
import 'package:moods_diary/utils/thongbao_snackbar.dart';
import '../widgets/auto_text.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleChangePassword() async {
    setState(() => _isLoading = true);

    final success =
        await AuthService().changePassword(oldCtrl.text, newCtrl.text);

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      await showSnackBarAutoText(
        context,
        "Đổi mật khẩu thành công! Vui lòng đăng nhập lại.",
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      await showSnackBarAutoText(
        context,
        "Mật khẩu cũ không đúng hoặc có lỗi xảy ra.",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AutoText("Đổi mật khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu cũ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleChangePassword,
                style: ElevatedButton.styleFrom(
                  //backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const AutoText("Đổi mật khẩu"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
