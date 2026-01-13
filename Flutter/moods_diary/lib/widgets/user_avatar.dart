// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/setting_provider.dart';
// import '../utils/constants.dart';

// class UserAvatar extends StatelessWidget {
//   final double radius;
//   final VoidCallback? onTap;

//   const UserAvatar({
//     super.key,
//     this.radius = 60,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final settingsProvider = context.watch<SettingProvider>();
//     final avatarPath = settingsProvider.avatarPath;
//     const defaultAssetImage = AssetImage('assets/images/avatar.png');

//     ImageProvider avatarImage;

//     if (avatarPath == null || avatarPath.isEmpty) {
//       avatarImage = defaultAssetImage;
//     } 
//     else if (avatarPath.startsWith('http')) {
//       avatarImage = NetworkImage(avatarPath);
//     } 
//     else {
//       avatarImage = FileImage(File(avatarPath));
//     }

//     return GestureDetector(
//       onTap: onTap,
//       child: CircleAvatar(
//         radius: radius,
//         backgroundImage: avatarImage,
//         backgroundColor: Colors.grey[200],
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/setting_provider.dart';
import '../utils/constants.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.radius = 60,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingProvider>();
    final avatarPath = settingsProvider.avatarPath;
    const defaultAssetImage = AssetImage('assets/images/avatar.png');

    ImageProvider avatarImage;

    if (avatarPath == null || avatarPath.isEmpty) {
      avatarImage = defaultAssetImage;
    } 
    else if (avatarPath.startsWith('http')) {
      String fixedUrl = avatarPath;
      final oldIpRegex = RegExp(r'http://192\.168\.\d+\.\d+(:\d+)?');
      //final oldIpRegex = RegExp(r'http://10\.0\.2\.2(:\d+)?');
      fixedUrl = fixedUrl.replaceFirst(oldIpRegex, Constants.baseStorageUrl);

      avatarImage = NetworkImage(
        "$fixedUrl?cacheBust=${DateTime.now().millisecondsSinceEpoch}", 
      );
    } 
    else {
      avatarImage = FileImage(File(avatarPath));
    }

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundImage: avatarImage,
        backgroundColor: Colors.grey[200],
      ),
    );
  }
}
