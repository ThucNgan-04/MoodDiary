import 'package:flutter/material.dart';
import 'package:moods_diary/widgets/auto_text.dart';

class BadgeModel {
  final String key;
  final String name;
  final String description;
  final String imageAsset;
  final String type;

  BadgeModel({
    required this.key,
    required this.name,
    required this.description,
    required this.imageAsset,
    required this.type,
  });
}

//p/khớp với khai báo const BADGES trong Laravel
final List<BadgeModel> allBadges = [
  BadgeModel(
    key: 'KIEN_TRI_3',
    name: 'Thử Thách 3 Ngày 🥉',
    description: 'Hoàn thành 3 ngày liên tiếp ghi nhật ký.',
    imageAsset: 'assets/images/3day.png',
    type: 'streak',
  ),
  BadgeModel(
    key: 'KIEN_TRI_7',
    name: 'Người Kiên Trì 7 Ngày 💪',
    description: 'Viết nhật ký cảm xúc 7 ngày liên tiếp.',
    imageAsset: 'assets/images/7day.png',
    type: 'streak',
  ),
  BadgeModel( 
    key: 'KIEN_TRI_30',
    name: 'Nhà Cảm Xúc Bền Bỉ 🌟',
    description: 'Viết nhật ký cảm xúc 30 ngày liên tiếp.',
    imageAsset: 'assets/images/30day.png',
    type: 'streak',
  ),
  BadgeModel(
    key: 'TICH_CUC_DE',
    name: 'Tia Nắng Sớm ☀️',
    description: 'Đạt 70% log tích cực trong 7 ngày gần nhất.',
    imageAsset: 'assets/images/sun.png',
    type: 'condition',
  ),
  BadgeModel(
    key: 'TICH_CUC_KHO',
    name: 'Tinh Thần Lạc Quan ✨',
    description: 'Duy trì tỷ lệ 80% log tích cực trong 30 ngày.',
    imageAsset: 'assets/images/lacquan30.png',
    type: 'condition',
  ),
  BadgeModel(
    key: 'TICH_CUC_CHINH',
    name: 'Tâm hồn tích cực 🌈',
    description: 'Chia sẻ cảm xúc tích cực thường xuyên (trên 60% tổng thể).',
    imageAsset: 'assets/images/tichcuc60%.png',
    type: 'condition',
  ),
  BadgeModel(
    key: 'COT_MOC_10',
    name: 'Người Ghi Chép Tập Sự',
    description: 'Hoàn thành 10 lần ghi nhật ký đầu tiên.',
    imageAsset: 'assets/images/vuotkho.png',
    type: 'permanent',
  ),
  BadgeModel(
    key: 'COT_MOC_100',
    name: 'Nhà Sử Học Cảm Xúc',
    description: 'Hoàn thành 100 lần ghi nhật ký.',
    imageAsset: 'assets/images/moc100.png',
    type: 'permanent',
  ),
  BadgeModel(
    key: 'VUOT_KHO_5',
    name: 'Bậc Thầy Vượt Khó 🏆',
    description: 'Ghi nhận được sự cải thiện sau giai đoạn cảm xúc tiêu cực kéo dài.',
    imageAsset: 'assets/images/vuotkho.png',
    type: 'permanent',
  ),
  BadgeModel(
    key: 'NHAT_KY_CHAM_CHI',
    name: 'Nhật Ký Chăm Chỉ ✍️',
    description: 'Ghi lại 3 cảm xúc trong cùng một ngày.',
    imageAsset: 'assets/images/chamchi.png',
    type: 'permanent',
  ),
];
//screen hh
class BadgeNoteScreen extends StatelessWidget {
  const BadgeNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Ghi Chú Huy Hiệu'),
        backgroundColor: Colors.pink.shade100,
        foregroundColor: const Color.fromARGB(255, 0, 0, 0), //icon quay lại
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: allBadges.length,
        itemBuilder: (context, index) {
          final badge = allBadges[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.asset(
                        badge.imageAsset,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error_outline, size: 40, color: Colors.grey);
                        },
                      ),
                    ),
                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoText(
                            badge.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AutoText(
                            badge.description,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                //cách dòng
                Container( 
                  height: 1,
                  margin: const EdgeInsets.only(right: 10),
                  color: Colors.pink.withOpacity(0.2),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}