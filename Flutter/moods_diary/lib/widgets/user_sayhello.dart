import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/setting_provider.dart';
// ignore: unused_import
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
