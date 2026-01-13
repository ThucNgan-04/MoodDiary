import 'package:flutter/material.dart';
import 'dart:math';

// ----------------------------------------------------
// 1. CustomPainter: Vẽ hiệu ứng Lấp Lánh (Sparks)
// ----------------------------------------------------
class SparkPainter extends CustomPainter {
  final Animation<double> animation;
  final String emotionDominance; // Dùng để đổi màu lấp lánh

  SparkPainter(this.animation, this.emotionDominance) : super(repaint: animation);

  // Chọn màu sắc dựa trên cảm xúc chủ đạo
  Color _getSparkColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'vui':
      case 'happy':
      case 'hạnh phúc':
        return Colors.amber.shade400;
      case 'buồn':
      case 'sad':
        return Colors.blue.shade300;
      case 'giận dữ':
      case 'angry':
        return Colors.red.shade400;
      case 'lo lắng':
      case 'anxiety':
        return Colors.purple.shade300;
      default:
        return Colors.greenAccent.shade400;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sparkColor = _getSparkColor(emotionDominance);
    // Vị trí gốc của cây (giữa canvas, hơi dịch xuống dưới)
    final Offset center = Offset(size.width / 2, size.height * 0.9);

    // Vẽ 10 hạt lấp lánh
    for (int i = 0; i < 10; i++) {
      // Góc và bán kính di chuyển ngẫu nhiên theo thời gian
      double angle = (i * 36.0 + animation.value * 360) * pi / 180;
      double radius = size.width * 0.1 + (sin(animation.value * 2 * pi) * 10);
      
      // Vị trí X và Y của hạt
      double x = center.dx + cos(angle) * radius;
      double y = center.dy - size.height * 0.2 - sin(angle) * radius * 0.5;

      // Độ mờ hạt (fade in/out)
      double opacity = sin(animation.value * 2 * pi + i * 0.5) * 0.5 + 0.5;
      
      final Paint sparkPaint = Paint()
        ..color = sparkColor.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;
        
      // Vẽ hình ngôi sao/hạt lấp lánh đơn giản
      canvas.drawCircle(Offset(x, y), 2.0 + (opacity * 2), sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SparkPainter oldDelegate) => true;
}

// ----------------------------------------------------
// 2. Widget Cây Có Animation
// ----------------------------------------------------
class AnimatedTree extends StatefulWidget {
  final String treeAssetPath;
  final String emotionDominance; // Truyền cảm xúc để đổi màu lấp lánh

  const AnimatedTree({
    required this.treeAssetPath,
    required this.emotionDominance,
    super.key,
  });

  @override
  State<AnimatedTree> createState() => _AnimatedTreeState();
}

class _AnimatedTreeState extends State<AnimatedTree> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true); 

    // Hiệu ứng nhấp nhô nhẹ (Scale 1.0 -> 1.04)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.easeInOut)),
    );

    // Hiệu ứng nghiêng nhẹ (Rotate -0.01 rad -> 0.01 rad)
    _tiltAnimation = Tween<double>(begin: -0.01, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.easeInOutSine)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Hiệu ứng Lấp Lánh (Vẽ bằng CustomPaint)
              // Đảm bảo CustomPaint có kích thước lớn hơn ảnh cây để hạt lấp lánh bay ra ngoài
              CustomPaint(
                size: const Size(600, 600), // Kích thước cố định hoặc dựa trên bố cục
                painter: SparkPainter(_controller, widget.emotionDominance),
              ),

              // 2. Hình Ảnh Cây (Có Animation)
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _tiltAnimation.value,
                  alignment: const Alignment(0.0, 0.8), // Xoay từ gốc cây (dưới)
                  child: Image.asset(
                    widget.treeAssetPath,
                    // Dùng BoxFit.contain để đảm bảo ảnh cây vừa với Expanded
                    fit: BoxFit.contain, 
                    errorBuilder: (context, error, stackTrace) {
                       return Container(
                          color: Colors.yellow.shade100,
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            'LỖI TẢI ẢNH CÂY: Cần tìm: ${widget.treeAssetPath}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                       );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}