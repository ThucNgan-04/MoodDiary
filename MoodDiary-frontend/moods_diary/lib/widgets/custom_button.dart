// lib/widgets/custom_button.dart

import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String? fontFamily; // Đã bỏ 'required' nếu bạn không sử dụng

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fontFamily, // Đã bỏ 'required' nếu bạn không sử dụng
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: fontFamily, // Dùng fontFamily nếu có
        ),
      ),
    );
  }
}