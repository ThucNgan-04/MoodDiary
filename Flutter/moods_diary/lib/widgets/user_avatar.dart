import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  final String? imageUrl;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.radius = 60,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, 
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.blueAccent,
        backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
            ? NetworkImage(imageUrl!)
            : null,
        child: imageUrl == null || imageUrl!.isEmpty
            ? const Icon(Icons.person, size: 80, color: Colors.white)
            : null,
      ),
    );
  }
}