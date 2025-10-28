import 'package:flutter/material.dart';

class BadgeShareWidget extends StatelessWidget {
  final String name;
  final String description;
  final String aiQuote;
  final String backgroundImage;
  final String logo; // Logo App (Asset)
  final String imageUrl; // Ảnh Huy hiệu (URL Network)

  const BadgeShareWidget({
    super.key,
    required this.name,
    required this.description,
    required this.aiQuote,
    required this.backgroundImage,
    required this.logo,
    required this.imageUrl,
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
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 40), 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 150,
            // Căn giữa theo chiều dọc
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 6),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15),
              ],
              color: Colors.white, 
            ),
            child: ClipOval(
              child: imageUrl.isNotEmpty 
                ? Image.network(
                    imageUrl, 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, size: 100, color: Colors.blueGrey),
                  )
                : const Icon(Icons.star, size: 100, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 10),

          Text(
            '🥳 Tôi vừa đạt huy hiệu 💐',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 35,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20, 
              ),
            ),
          ),
          
          const SizedBox(height: 15),

          Padding(
             padding: const EdgeInsets.symmetric(horizontal: 10.0),
             child: Text(
               '🌞 “$aiQuote”',
               textAlign: TextAlign.center,
               style: const TextStyle(
                 color: Colors.white,
                 fontSize: 20, 
                 fontStyle: FontStyle.italic,
                 height: 1.4,
               ),
             ),
           ),

          const Spacer(), 
          Image.asset(
            logo, 
            height: 80,
            errorBuilder: (context, error, stackTrace) {
               return const Text('MOODDIARY', style: TextStyle(color: Color.fromARGB(179, 212, 212, 212), fontSize: 19));
            }
          ),
          const SizedBox(height: 5),

          const Text(
            '#MoodDiary #HuyHiệuCảmXúc',
            style: TextStyle(
              color: Color.fromARGB(179, 212, 212, 212),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}