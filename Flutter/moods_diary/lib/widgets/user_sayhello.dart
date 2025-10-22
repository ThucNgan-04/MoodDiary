import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/setting_provider.dart';
import '../screens/badge_screen.dart';
import 'auto_text.dart';

class UserSayHello extends StatefulWidget {
  const UserSayHello({super.key});

  @override
  State<UserSayHello> createState() => _UserSayHelloState();
}

class _UserSayHelloState extends State<UserSayHello> {

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingProvider>();
    final username = context.watch<SettingProvider>().username ?? "Người dùng";
    final avatarPath = settingsProvider.avatarPath;
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    const defaultAssetImage = AssetImage('assets/images/avatar.png');
    ImageProvider avatarImage;

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
            // Logo + tên app
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

            // ===== Icon huy hiệu góc phải + chấm đỏ =====
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: "Xem huy hiệu cảm xúc",
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BadgeScreen()),
                    );
                  },
                  icon: Icon(
                    Icons.emoji_events,
                    color: const Color.fromARGB(255, 255, 168, 18),
                    size: 40,
                    shadows: [
                        Shadow(
                          offset: const Offset(1.0, 2.0), // Đổ bóng nhẹ xuống dưới và sang phải
                          blurRadius: 5.0,
                          color: Colors.black.withOpacity(0.6),
                        ),
                    ],
                  ),
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
              "Xin chào, $username !",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
