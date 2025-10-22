import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ShareBadgeCard extends StatefulWidget {
  final String badgeName;
  final String achievement;
  final String quote;

  const ShareBadgeCard({
    super.key,
    required this.badgeName,
    required this.achievement,
    required this.quote,
  });

  @override
  State<ShareBadgeCard> createState() => _ShareBadgeCardState();
}

class _ShareBadgeCardState extends State<ShareBadgeCard> {
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _shareImage() async {
    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/badge_share.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Chia sẻ thành tích của tôi!');
    } catch (e) {
      debugPrint("Lỗi khi tạo ảnh chia sẻ: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(
          key: _globalKey,
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/share_bg.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Image.asset('assets/icons/badge_icon.png', height: 80),
                const SizedBox(height: 12),
                Text(
                  '🎉 Tôi vừa đạt huy hiệu "${widget.badgeName}"!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.achievement,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.quote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '#MoodDiary  #HuyHiệuCảmXúc',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _shareImage,
          icon: const Icon(Icons.share),
          label: const Text('Chia sẻ'),
        ),
      ],
    );
  }
}
