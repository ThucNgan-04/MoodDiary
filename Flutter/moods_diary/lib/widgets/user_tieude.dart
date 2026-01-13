// ignore: unused_import
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/setting_provider.dart';
import '../screens/badge_screen.dart';
import 'auto_text.dart';

class UserTieude extends StatefulWidget {
  const UserTieude({super.key});

  @override
  State<UserTieude> createState() => _UserTieudeState();
}

class _UserTieudeState extends State<UserTieude> {

  //Hàm chuyển hướng Huy hiệu
  void _navigateToBadge() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BadgeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingProvider>();
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo + tên app (Vị trí bên trái)
            Row(
              children: [
                Icon(Icons.cloud, color: primaryColor, size: 50),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MOODDIARY",
                      style: TextStyle(
                        fontSize: settingsProvider.getScaledFontSize(25),
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(offset: const Offset(0, -1.5), color: Colors.white),
                          Shadow(offset: const Offset(0, 1.5), color: Colors.white),
                          Shadow(offset: const Offset(-1.5, 0), color: Colors.white),
                          Shadow(offset: const Offset(1.5, 0), color: Colors.white),
                        ],
                      ),
                    ),
                    AutoText(
                      "Nhật ký cảm xúc",
                      style: TextStyle(
                        fontSize: settingsProvider.getScaledFontSize(10),
                        color: const Color.fromARGB(102, 0, 0, 0),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: "Xem huy hiệu cảm xúc",
                  onPressed: _navigateToBadge,
                  icon: Icon(
                    Icons.emoji_events,
                    color: const Color.fromARGB(255, 255, 168, 18),
                    size: 40, 
                    shadows: [
                      Shadow(
                        offset: const Offset(1.0, 2.0),
                        blurRadius: 5.0,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),                
              ],
            ),
          ],
        ),
      ],
    );
  }
}