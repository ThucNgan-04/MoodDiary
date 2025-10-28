import 'package:flutter/material.dart';
import '../widgets/auto_text.dart';

Future<void> showSnackBarAutoText(
  BuildContext context,
  String message, {
  bool isError = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  messenger.clearSnackBars(); // Xóa snack bar cũ nếu có

  final snackBar = SnackBar(
    backgroundColor: isError ? const Color.fromARGB(255, 192, 14, 14) : const Color.fromARGB(255, 0, 0, 0),
    behavior: SnackBarBehavior.floating,
    content: Builder(
      builder: (context) {
        return AutoText(
          message,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        );
      },
    ),
    duration: const Duration(seconds: 2),
  );

  messenger.showSnackBar(snackBar);
}