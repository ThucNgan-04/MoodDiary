import 'dart:io';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:moods_diary/screens/badge_note_screen.dart';
import 'package:moods_diary/widgets/badge_share_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/badge_provider.dart';
import '../widgets/auto_text.dart';

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  final ScreenshotController screenshotController = ScreenshotController();
  late BadgeProvider _badgeProvider;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _badgeProvider = Provider.of<BadgeProvider>(context, listen: false);
      _loadBadges();
    });
  }

  Future<void> _loadBadges() async {
    await _badgeProvider.loadBadges(context);
    
    // Xóa cờ thông báo sau khi người dùng vào màn hình này
    if (mounted) {
      await _badgeProvider.clearBadgeNotification();
    }
  }

  Future<void> _shareBadge(Map<String, dynamic> badge) async {
    final name = badge['badge_name'] ?? 'Huy hiệu bí ẩn';
    final description = badge['description'] ?? 'Đã kiên trì ghi lại cảm xúc.';
    final aiQuote =
        badge['ai_quote'] ?? 'Hãy tiếp tục hành trình chăm sóc tinh thần.';
    final imageUrl = badge['image_url'] ?? '';

    final image = await screenshotController.captureFromWidget(
      // Bọc Widget chia sẻ trong ScreenshotController
      Material(
        child: BadgeShareWidget(
          name: name,
          description: description,
          aiQuote: aiQuote,
          imageUrl: imageUrl, 
          backgroundImage: 'assets/images/share_bg.png', 
          logo: 'assets/images/7day.png', 
        ),
      ),
      delay: const Duration(milliseconds: 100), // Độ trễ để widget kịp render
    );

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = File('${directory.path}/badge_share.png');
    await imagePath.writeAsBytes(image);

    await Share.shareXFiles(
      [XFile(imagePath.path)],
      text: "🌞🌻 Tôi vừa đạt huy hiệu \"$name\" trên MoodDiary! 🏆🌟",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AutoText('HUY HIỆU CẢM XÚC 🏅'),
        centerTitle: true,
        backgroundColor: Colors.pink.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color.fromARGB(255, 232, 232, 232)), // Biểu tượng 'i'
            onPressed: () {
              // Điều hướng đến trang Note Huy Hiệu
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BadgeNoteScreen(), // <--- Gọi màn hình đã gộp
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<BadgeProvider>(
        builder: (context, badgeProvider, _) {
          final badges = badgeProvider.badges;
          final isLoading = badgeProvider.isLoading;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (badges.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadBadges,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return _buildBadgeCard(context, badge);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_border, size: 80, color: Colors.pinkAccent),
            const SizedBox(height: 20),
            const AutoText(
              'Hành trình vĩ đại bắt đầu từ những bước nhỏ! 🌱',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            AutoText(
              'Tiếp tục ghi nhật ký cảm xúc, bạn sẽ nhận được huy hiệu đầu tiên khi đạt cột mốc kiên trì!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, Map<String, dynamic> badge) {
    final name = badge['badge_name'] ?? 'Huy hiệu không tên';
    final imageUrl = badge['image_url'] ?? '';
    final description = badge['description'] ?? 'Đã đạt được thành tích đặc biệt.';
    final aiQuote = badge['ai_quote'] ?? 'Hãy tiếp tục hành trình chăm sóc tinh thần.';
    final earnedDate = _formatDate(badge['earned_date']);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60, // Kích thước cố định cho ảnh
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.pink.shade200, width: 2),
                    ),
                    child: ClipOval(
                      child: imageUrl.isNotEmpty 
                        ? Image.network(
                            imageUrl, 
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.stars, size: 30, color: Colors.amber), // Fallback
                          )
                        : const Icon(Icons.stars, size: 30, color: Colors.amber),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoText(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        AutoText(
                          'Đạt ngày: $earnedDate',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 25, color: Colors.grey),
              AutoText(
                'Thành tích: $description',
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AutoText(
                  '💡 “$aiQuote”',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFE91E63),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _shareBadge(badge),
                  icon: const Icon(Icons.share, size: 18),
                  label: const AutoText('Chia sẻ'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null || dateString.toString().isEmpty) {
      return 'Chưa xác định';
    }
    try {
      final date = DateTime.parse(dateString.toString()).toLocal();
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateString.toString();
    }
  }
}