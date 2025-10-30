import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:moods_diary/utils/constants.dart';
import 'package:moods_diary/widgets/auto_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/date_ultils.dart'; 

// WIDGET 1: ThongKeWeeklySummary
class ThongKeWeeklySummary extends StatelessWidget {
  final WeeklyData weeklyData;
  final Map<String, dynamic> weekMoods; 
  final List<Map<String, dynamic>> allWeeklyMoodEntries; 
  
  final List<Map<String, dynamic>> allPreviousWeeklyMoodEntries; 
  
  final Function(String) isPositiveMood;
  final int negToPosCount;
  final int posToNegCount;

  final List<WeeklyData>? allWeeks;
  final Map<int, Map<String, dynamic>>? allWeekMoods; 

  const ThongKeWeeklySummary({
    super.key,
    required this.weeklyData,
    required this.weekMoods,
    required this.allWeeklyMoodEntries, 
    required this.allPreviousWeeklyMoodEntries, 
    required this.isPositiveMood,
    required this.negToPosCount,
    required this.posToNegCount,
    this.allWeeks,
    this.allWeekMoods,
  });
  static const Set<String> negativeMoods = {'buồn', 'giận dữ'};

  // -------------------- PHÂN TÍCH TẤT CẢ BẢN GHI TRONG TUẦN HIỆN TẠI --------------------
  Map<String, int> _analyzeWeek({required List<Map<String, dynamic>> entries}) {
    int posCount = 0;
    int negCount = 0;
    int neuCount = 0; 
    int totalCount = entries.length; 
    
    for (final entry in entries) {
      final emotionRaw = entry['emotion']; 
      final String? emotion = emotionRaw is String ? emotionRaw.toLowerCase() : null;

      if (emotion != null ) {
        if (isPositiveMood(emotion)) {
          posCount++;
        } else if (negativeMoods.contains(emotion)){ 
          negCount++;
        } else {
          neuCount++; 
        }
      }
    }
    final calculatedTotal = posCount + negCount + neuCount;
    return {'pos': posCount, 'neg': negCount, 'neu': neuCount, 'totalEntries': totalCount};
  }

  // -------------------- HÀM SO SÁNH --------------------
  // Lấy kết quả phân tích tuần trước
  Map<String, int> _analyzePreviousWeek() {
      return _analyzeWeek(entries: allPreviousWeeklyMoodEntries);
  }

  Map<String, int> _compareWithPreviousWeek(Map<String, int> currStats, Map<String, int> prevStats) {
    return {
      'posDiff': currStats['pos']! - prevStats['pos']!,
      'negDiff': currStats['neg']! - prevStats['neg']!,
      'neuDiff': currStats['neu']! - prevStats['neu']!,
    };
  }
  
  // -------------------- CÁC HÀM XÂY DỰNG UI --------------------
  Widget _buildComparisonRow(String label, int diff, {String unit = 'lần'}) {
    String text;
    Color color;
    if (diff > 0) {
      text = "Tăng $diff $unit";
      color = Colors.green.shade600;
    } else if (diff < 0) {
      text = "Giảm ${diff.abs()} $unit";
      color = Colors.red.shade600;
    } else {
      text = "Không đổi";
      color = Colors.grey.shade600;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AutoText(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          AutoText(text, style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {double flex = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: AutoText(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.pink.shade800,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {Color? color, bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: AutoText(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: color ?? Colors.black87,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMoodBar(String label, int count, int total, Color color) {
    double percent = total > 0 ? count / total : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoText(
            '$label: $count lần ghi nhận (${(percent * 100).toStringAsFixed(0)}%)', 
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  // -------------------- BUILD --------------------
  @override
  Widget build(BuildContext context) {
    // Phân tích tuần hiện tại
    final currStats = _analyzeWeek(entries: allWeeklyMoodEntries);
    final pos = currStats['pos']!;
    final neg = currStats['neg']!;
    final neu = currStats['neu']!;
    final total = currStats['totalEntries']!; 

    // Phân tích tuần trước 
    final prevStats = _analyzePreviousWeek();
    final prevTotal = prevStats['totalEntries']!;
    
    // SO SÁNH
    Map<String, int>? diff;
    if (prevTotal > 0) {
      diff = _compareWithPreviousWeek(currStats, prevStats);
    }
    
    return Container(
      width: 600,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoText(
            "Tóm tắt Tuần ${weeklyData.weekNumber} (${weeklyData.dateRange})",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 114, 53, 102),
            ),
          ),
          AutoText(
            "(Dựa trên $total lần ghi nhận)",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const Divider(height: 20, color: Colors.grey),

          // Bảng chi tiết
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Hàng Tiêu đề
              TableRow(
                children: [
                  _buildHeaderCell("Tâm trạng", flex: 1.5),
                  _buildHeaderCell("Số Emotion"),
                ],
              ),
              // Hàng Dữ liệu Tích cực
              TableRow(
                children: [
                  _buildDataCell("Tích cực (Pos) 🌟", isBold: true),
                  _buildDataCell("$pos", color: Colors.green.shade600, isBold: true),
                ],
              ),
              // Hàng Dữ liệu Tiêu cực
              TableRow(
                children: [
                  _buildDataCell("Tiêu cực (Neg) ⚠️", isBold: true),
                  _buildDataCell("$neg", color: Colors.red.shade600, isBold: true),
                ],
              ),
              // Hàng Dữ liệu Trung lập
              TableRow(
                children: [
                  _buildDataCell("Ngày chưa ghi 😐", isBold: true), 
                  _buildDataCell("$neu", color: Colors.grey.shade600, isBold: true),
                ],
              ),
              // Hàng Tổng cộng
              TableRow(
                children: [
                  _buildHeaderCell("TỔNG EMOTION", flex: 1.5),
                  _buildHeaderCell("$total"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          AutoText(
            "Phân bố Cảm xúc:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),

          // Thanh tiến trình
          _buildMoodBar("Tích cực", pos, total, Colors.green),
          _buildMoodBar("Tiêu cực", neg, total, Colors.red),
          _buildMoodBar("Ngày chưa ghi", neu, total, Colors.blueGrey),

          if (prevTotal > 0 && diff != null) ...[
            const SizedBox(height: 24),
            AutoText(
              "So sánh (theo SỐ LẦN GHI NHẬN) với Tuần trước:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade800,
              ),
            ),
            AutoText(
               "(Tuần trước có $prevTotal lần ghi nhận)",
               style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            _buildComparisonRow("Tích cực 🌟", diff['posDiff']!, unit: 'lần'),
            _buildComparisonRow("Tiêu cực ⚠️", diff['negDiff']!, unit: 'lần'),
            _buildComparisonRow("Khác 😐", diff['neuDiff']!, unit: 'lần'),
            const SizedBox(height: 20),
            
            // PHÂN TÍCH AI 
            ThongKeWeeklyAIAnalysis(
              currStats: currStats, 
              prevStats: prevStats, 
              currDateRange: weeklyData.dateRange,
              prevDateRange: allWeeks != null && weeklyData.weekNumber > 1 
                  ? allWeeks!.firstWhere((w) => w.weekNumber == weeklyData.weekNumber - 1).dateRange
                  : "Tuần trước", 
            ),
          ],
        ],
      ),
    );
  }
}
//--------------HÀM HTHI PHÂN TÍCH AI----------------
class ThongKeWeeklyAIAnalysis extends StatefulWidget {
  final Map<String, int> currStats; 
  final Map<String, int> prevStats;
  final String currDateRange;
  final String prevDateRange;

  const ThongKeWeeklyAIAnalysis({
    super.key,
    required this.currStats,
    required this.prevStats,
    required this.currDateRange,
    required this.prevDateRange,
  });

  @override
  State<ThongKeWeeklyAIAnalysis> createState() => _ThongKeWeeklyAIAnalysisState();
}

class _ThongKeWeeklyAIAnalysisState extends State<ThongKeWeeklyAIAnalysis> {
  String aiAnalysis = "Bấm vào nút bên dưới để Mood Diary phân tích chuyên sâu.";
  bool isLoading = false;
  final String apiEndpoint = "${Constants.baseUrl}/ai/mood-shift-analysis"; 
  final String tokenKey = Constants.tokenKey;

  Future<void> _fetchAIAnalysis() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
      aiAnalysis = "Mood Diary đang phân tích dữ liệu tuần này...";
    });
    final payload = {// Chuẩn bị payload
      'curr_stats': widget.currStats, 
      'prev_stats': widget.prevStats,
      'curr_date_range': widget.currDateRange,
      'prev_date_range': widget.prevDateRange,
    };
    final prefs = await SharedPreferences.getInstance();// Lấy token
    final token = prefs.getString(tokenKey);
    if (token == null) {
        setState(() {
            aiAnalysis = "Lỗi: Không tìm thấy Token người dùng.";
            isLoading = false;
        });
        return;
    }
    try {
        final response = await http.post(
            Uri.parse(apiEndpoint), 
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
            },
            body: json.encode(payload),
        );
        final data = json.decode(utf8.decode(response.bodyBytes));  
        if (response.statusCode == 429) {
             setState(() {
                 aiAnalysis = data['analysis'] ?? 'AI đang tạm nghỉ để nạp năng lượng 😅. Hãy thử lại sau ít phút nhé!';
             });
        } else if (response.statusCode != 200) {
             setState(() {
                 aiAnalysis = data['analysis'] ?? "Lỗi server ${response.statusCode}. Không thể phân tích AI.";
             });
        } else {
             final resultAnalysis = data['analysis'] ?? "Phân tích AI thất bại, nhưng bạn đang làm rất tốt!";
             setState(() {
                 aiAnalysis = resultAnalysis;
             });
        }
    } catch (e) {
        setState(() {
            aiAnalysis = "Lỗi mạng hoặc kết nối. Hãy thử lại.";
        });
        debugPrint('AI Analysis Error: $e');
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoText(
              "MOODDIARY phân tích sự biến đổi:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: AutoText(
            aiAnalysis,
            style: TextStyle(fontSize: 14, color: Colors.blue.shade900, height: 1.5),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _fetchAIAnalysis,
            icon: const Icon(Icons.psychology_alt),
            label: AutoText(isLoading ? "Đang phân tích..." : "Phân Tích Từ MOODDIARY"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}