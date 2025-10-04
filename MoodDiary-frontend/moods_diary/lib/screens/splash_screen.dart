import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/setting_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ignore: unused_field
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(Constants.tokenKey);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    
    if (token != null) {
      final username = prefs.getString(Constants.usernameKey);
      if (username != null) {
        final settingProvider = Provider.of<SettingProvider>(context, listen: false);
        await settingProvider.setUsername(username);
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy màu chủ đạo từ theme của hệ thống
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud, size: 80, color: primaryColor), // Icon sử dụng màu chủ đạo
            const SizedBox(height: 12),
            Text(
              'MOODDIARY',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor, // Chữ sử dụng màu chủ đạo
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 30),
            CircularProgressIndicator(color: primaryColor), // Icon loading sử dụng màu chủ đạo
          ],
        ),
      ),
    );
  }
}
