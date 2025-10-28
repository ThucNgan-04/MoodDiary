import 'package:flutter/material.dart';
import 'package:moods_diary/widgets/auto_text.dart';

// Hàm hiển thị Popup chúc mừng
Future<void> showCelebrationPopup(BuildContext context, String badgeName, String aiQuote, String imageUrl) async {
  await showDialog(
    context: context,
    barrierDismissible: false, //Ngăn người dùng chạm ra ngoài để đóng
    barrierColor: Colors.black54, 
    builder: (context) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "🏆 ĐÃ ĐẠT HUY HIỆU MỚI! 🌟",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              //Ảnh huy hiệu
              Container(
                width: 80, 
                height: 80,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 3),
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, size: 50, color: Colors.amber),
                      )
                    : const Icon(Icons.star, size: 50, color: Colors.amber),
                ),
              ),
              AutoText(
                badgeName, 
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              AutoText(
                aiQuote,
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Đã hiểu', 
                    style: TextStyle(
                      color: Color(0xFFE91E63),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    )
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}