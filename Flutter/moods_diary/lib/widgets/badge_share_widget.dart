import 'package:flutter/material.dart';
import 'package:moods_diary/widgets/auto_text.dart';

class BadgeShareWidget extends StatelessWidget {
  final String name;
  final String description;
  final String aiQuote;
  final String backgroundImage;
  final String logo;

  const BadgeShareWidget({
    super.key,
    required this.name,
    required this.description,
    required this.aiQuote,
    required this.backgroundImage,
    required this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 900,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(logo, height: 150),
          const SizedBox(height: 30),
          AutoText(
            '🥳 Tôi vừa đạt huy hiệu 💐',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          AutoText(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 35,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: AutoText(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AutoText(
            '🌞 “$aiQuote”',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const Spacer(),
          const AutoText(
            '#MoodDiary #HuyHiệuCảmXúc',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
