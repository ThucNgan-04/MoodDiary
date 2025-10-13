class MoodModel {
  final int? id;
  final int? userId;
  final String emotion;
  final String tag;
  final String note;
  final DateTime createdAt;

  MoodModel({
    this.id,
    this.userId,
    required this.emotion,
    required this.tag,
    required this.note,
    required this.createdAt,
  });

  // Parse từ JSON trả về từ Laravel
  factory MoodModel.fromJson(Map<String, dynamic> json) {
    return MoodModel(
      id: json['id'],
      userId: json['user_id'],
      emotion: json['emotion'] ?? '',
      tag: json['tag'] ?? '',
      note: json['note'] ?? '',
      // Ưu tiên lấy created_at, fallback sang date
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : (json['date'] != null
              ? DateTime.parse(json['date']).toLocal()
              : DateTime.now()),
    );
  }

  // Dùng khi POST lên server
  Map<String, dynamic> toRequestBody() {
    return {
      'emotion': emotion,
      'tag': tag,
      'note': note,
      'date': createdAt.toIso8601String(), // gửi chuẩn ISO
    };
  }
}
