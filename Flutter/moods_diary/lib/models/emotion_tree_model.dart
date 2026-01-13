class EmotionTree {
  final int level;
  final String emotionType; // Cảm xúc nhật ký gần nhất (Dùng cho màu sắc tức thời)
  final int growthPoint;
  final String emotionDominance; // Cảm xúc chiếm ưu thế (Dùng cho hình ảnh/trạng thái cây chính)
  final int daysSinceLastEntry; // Số ngày chưa ghi nhật ký (Logic héo)
  final bool needsPlanting;
  final List<WaterTask> waterTasks;

  EmotionTree({
    required this.level,
    required this.emotionType,
    required this.growthPoint,
    required this.emotionDominance,
    required this.daysSinceLastEntry,
    required this.needsPlanting,
    required this.waterTasks,
  });

  factory EmotionTree.fromJson(Map<String, dynamic> json) {
    // API trả về 'data' chứa tree_status, hoặc trực tiếp tree_status
    final data = json['data'] ?? json['tree_status'] ?? json;
    final List<dynamic> taskList = json['water_tasks'] ?? [];
    
    return EmotionTree(
      level: data['level'] as int,
      emotionType: data['emotion_type'] as String,
      growthPoint: data['growth_point'] as int,
      emotionDominance: data['emotion_dominance'] as String,
      daysSinceLastEntry: data['days_since_last_entry'] as int,
      needsPlanting: data['needs_planting'] as bool,
      waterTasks: taskList.map((t) => WaterTask.fromJson(t)).toList(),
    );
  }
}
class WaterTask {
  final String title;
  final String progress; // Ví dụ: "3/7"
  final String reward; // Ví dụ: "+7 nước"
  final bool isDone;
  
  WaterTask({required this.title, required this.progress, required this.reward, required this.isDone});

  factory WaterTask.fromJson(Map<String, dynamic> json) {
    return WaterTask(
      title: json['title'] as String,
      progress: json['progress'] as String,
      reward: json['reward'] as String,
      isDone: json['is_done'] as bool,
    );
  }
}