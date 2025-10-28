// File: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'settings_screen.dart';
import 'thongke_screen.dart';
import 'diary_screen.dart';
import 'calendar_screen.dart';
import 'home_content.dart';
import '../providers/setting_provider.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  final TextEditingController oldPassController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();

  // Phương thức tiện ích để chuyển đổi mã hex thành đối tượng Color
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
    final List<Widget> screens = [
      const HomeContent(),
      const ThongKeScreen(),
      const DiaryScreen(),
      const CalendarScreen(),
      const SettingsScreen(),
    ];

    return Consumer<SettingProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;

        final Color selectedColor = settings.colorTheme != null
            ? _hexToColor(settings.colorTheme!)
            : Theme.of(context).colorScheme.primary; // Màu mặc định nếu chưa có

        return Scaffold(
          body: SafeArea(
            child: screens[selectedIndex],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: selectedColor.withOpacity(0.3), 
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              child: BottomNavigationBar(
                currentIndex: selectedIndex,
                onTap: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                selectedItemColor: selectedColor, 
                unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
                backgroundColor: Colors.white,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: "Cá nhân"),
                  BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Thống kê"),
                  BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "Nhật ký"),
                  BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Lịch"),
                  BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Cài đặt"),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}