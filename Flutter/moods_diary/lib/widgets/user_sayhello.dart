import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/setting_provider.dart';
import 'auto_text.dart';

class UserSayHello extends StatelessWidget {
  const UserSayHello({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingProvider>();
    final username = context.watch<SettingProvider>().username ?? "Người dùng";
    final avatarPath = settingsProvider.avatarPath; 
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    const defaultAssetImage = AssetImage('assets/images/avatar.png');

    ImageProvider avatarImage;

    //phân biệt đường dẫn trong máy, mạng hoặc mặc định
    if (avatarPath == null || avatarPath.isEmpty) {
      avatarImage = defaultAssetImage;
    } else if (avatarPath.startsWith('http')) {
      avatarImage = NetworkImage(avatarPath);
    } else {
      avatarImage = FileImage(File(avatarPath));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
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
                      style: TextStyle(
                        fontSize: settingsProvider.getScaledFontSize(10), 
                        color: const Color.fromARGB(102, 0, 0, 0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: avatarImage,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(width: 10),
            AutoText(
              "Xin Chào! $username",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontStyle: FontStyle.italic,
                    fontSize: double.infinity
              ),
            ),
            const SizedBox(width: 6),
          ],
        )
      ],
    );
  }
}