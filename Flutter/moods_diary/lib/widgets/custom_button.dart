// lib/widgets/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String? fontFamily; 

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fontFamily, 
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: fontFamily, 
        ),
      ),
    );
  }
}