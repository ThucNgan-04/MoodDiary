// File: widgets/thong_ke_tuan.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:moods_diary/utils/constants.dart';
import 'package:moods_diary/widgets/auto_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/date_ultils.dart'; // Import để dùng WeeklyData

// WIDGET 1: ThongKeWeeklySummary

class ThongKeWeeklySummary extends StatelessWidget {
  final WeeklyData weeklyData;
  final Map<String, dynamic> weekMoods; // {day: 'emotion'}
  final Function(String) isPositiveMood;

  // để so sánh với tuần trước
  final List<WeeklyData>? allWeeks;
  final Map<int, Map<String, dynamic>>? allWeekMoods;

  const ThongKeWeeklySummary({
    super.key,
    required this.weeklyData,
    required this.weekMoods,
    required this.isPositiveMood,
    this.allWeeks,
    this.allWeekMoods,
  });

  // -------------------- PHÂN TÍCH TUẦN HIỆN TẠI --------------------
  Map<String, int> _analyzeWeek() {
    int posCount = 0;
    int negCount = 0;
    int neuCount = 0;

    for (int day in weeklyData.days) {
      final emotion = weekMoods[day.toString()];
      if (emotion != null && emotion is String) {
        if (isPositiveMood(emotion)) {
          posCount++;
        } else {
          negCount++;
        }
      } else {
        neuCount++;
      }
    }

    return {'pos': posCount, 'neg': negCount, 'neu': neuCount};
  }

  // -------------------- TÌM TUẦN TRƯỚC GẦN NHẤT CÓ DỮ LIỆU --------------------
  WeeklyData? _findPreviousWeekWithData() {
    if (allWeeks == null || allWeekMoods == null) return null;
    final currentWeekNum = weeklyData.weekNumber;

    for (int i = currentWeekNum - 1; i >= 1; i--) {
      // find week object with weekNumber == i (if any)
      final matches = allWeeks!.where((w) => w.weekNumber == i).toList();
      if (matches.isEmpty) continue;
      final prev = matches.first;

      // get moods map for that week (may be null if key absent)
      final Map<String, dynamic>? moods = allWeekMoods![i];
      if (moods != null && moods.isNotEmpty) {
        // at least one recorded day exists — return this previous week
        return prev;
      }
    }
    return null;
  }

  // -------------------- PHÂN TÍCH TUẦN CỤ THỂ (CHO TUẦN TRƯỚC) --------------------
  Map<String, int> _analyzeCustomWeek(WeeklyData week, Map<String, dynamic> moods) {
    int posCount = 0;
    int negCount = 0;
    int neuCount = 0;

    for (int day in week.days) {
      final emotion = moods[day.toString()];
      if (emotion != null && emotion is String) {
        if (isPositiveMood(emotion)) {
          posCount++;
        } else {
          negCount++;
        }
      } else {
        neuCount++;
      }
    }
    return {'pos': posCount, 'neg': negCount, 'neu': neuCount};
  }

  // -------------------- SO SÁNH 2 TUẦN --------------------
  Map<String, int> _compareWithPreviousWeek(WeeklyData prevWeek) {
    final prevMoods = allWeekMoods![prevWeek.weekNumber] ?? {};
    final prevStats = _analyzeCustomWeek(prevWeek, prevMoods);
    final currStats = _analyzeWeek();

    return {
      'posDiff': currStats['pos']! - prevStats['pos']!,
      'negDiff': currStats['neg']! - prevStats['neg']!,
      'neuDiff': currStats['neu']! - prevStats['neu']!,
    };
  }

  // -------------------- TẠO NHẬN XÉT CHUYÊN SÂU (NO-AI) --------------------
  /// Sinh đoạn nhận xét ngắn (dựa trên số tuyệt đối và phần trăm)
  String _generateShiftAnalysis(Map<String, int> prevStats, Map<String, int> currStats) {
    final prevTotal = (prevStats['pos'] ?? 0) + (prevStats['neg'] ?? 0) + (prevStats['neu'] ?? 0);
    final currTotal = (currStats['pos'] ?? 0) + (currStats['neg'] ?? 0) + (currStats['neu'] ?? 0);

    String safePercentChange(int prev, int curr) {
      if (prev == 0) {
        if (curr == 0) return "0%";
        return "từ 0 lên ${((curr) * 100).toString()}% (không có dữ liệu trước đó)";
      }
      final change = ((curr - prev) / prev) * 100;
      return "${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}%";
    }

    final posPrev = prevStats['pos'] ?? 0;
    final negPrev = prevStats['neg'] ?? 0;
    final neuPrev = prevStats['neu'] ?? 0;

    final posCurr = currStats['pos'] ?? 0;
    final negCurr = currStats['neg'] ?? 0;
    final neuCurr = currStats['neu'] ?? 0;

    final posChange = posCurr - posPrev;
    final negChange = negCurr - negPrev;
    final neuChange = neuCurr - neuPrev;

    final posPct = safePercentChange(posPrev, posCurr);
    final negPct = safePercentChange(negPrev, negCurr);
    final neuPct = safePercentChange(neuPrev, neuCurr);

    // Build readable summary
    final buffer = StringBuffer();
    buffer.writeln("🔎 Tóm tắt dịch chuyển cảm xúc so với tuần trước:");
    buffer.writeln("- Tích cực: ${posChange >= 0 ? "tăng $posChange ngày" : "giảm ${posChange.abs()} ngày"} ($posPct).");
    buffer.writeln("- Tiêu cực: ${negChange >= 0 ? "tăng $negChange ngày" : "giảm ${negChange.abs()} ngày"} ($negPct).");
    buffer.writeln("- Trung tính/Chưa ghi: ${neuChange >= 0 ? "tăng $neuChange ngày" : "giảm ${neuChange.abs()} ngày"} ($neuPct).");

    // Một số nhận xét bổ sung dựa trên xu hướng
    // if (negChange < 0 && posChange > 0) {
    //   buffer.writeln("\n🟢 Xu hướng tích cực: Số ngày tiêu cực giảm trong khi số ngày tích cực tăng — dấu hiệu phục hồi cảm xúc.");
    // } else if (negChange > 0 && posChange < 0) {
    //   buffer.writeln("\n🔴 Cần chú ý: Tăng ngày tiêu cực và giảm ngày tích cực — người dùng có thể trải qua tuần căng thẳng.");
    // } else if (negChange == 0 && posChange == 0 && neuChange == 0) {
    //   buffer.writeln("\n⚖️ Ổn định: Không thay đổi đáng kể giữa hai tuần.");
    // } else {
    //   buffer.writeln("\nℹ️ Có biến động nhẹ; cân nhắc xem xét nhật ký chi tiết để hiểu nguyên nhân cụ thể (công việc, giấc ngủ, tương tác...).");
    // }
    buffer.writeln("\nNhấn nút 'Nhận Phân Tích Chuyên Sâu Từ MOODDIARY' để có đánh giá tâm lý chuyên nghiệp.");
    // Tối đa khoảng 4-6 câu — gọn và trực tiếp
    return buffer.toString();
  }

  // -------------------- Ô HIỂN THỊ SO SÁNH --------------------
  Widget _buildComparisonRow(String label, int diff) {
    String text;
    Color color;
    if (diff > 0) {
      text = "Tăng $diff ngày";
      color = Colors.green.shade600;
    } else if (diff < 0) {
      text = "Giảm ${diff.abs()} ngày";
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

  // Hàm tạo ô tiêu đề
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

  // Hàm tạo ô dữ liệu
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

  // Hàm tạo thanh tiến trình
  Widget _buildMoodBar(String label, int count, int total, Color color) {
    double percent = total > 0 ? count / total : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoText(
            '$label: $count ngày (${(percent * 100).toStringAsFixed(0)}%)',
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
    final analysis = _analyzeWeek();
    final pos = analysis['pos']!;
    final neg = analysis['neg']!;
    final neu = analysis['neu']!;
    final total = pos + neg + neu;

    final prevWeek = _findPreviousWeekWithData();
    final diff = prevWeek != null ? _compareWithPreviousWeek(prevWeek) : null;

    // If previous week found, build previous stats for detailed analysis
    Map<String, int>? prevStats;
    String? deepAnalysis;
    if (prevWeek != null && allWeekMoods != null) {
      final prevMoods = allWeekMoods![prevWeek.weekNumber] ?? {};
      prevStats = _analyzeCustomWeek(prevWeek, prevMoods);
      deepAnalysis = _generateShiftAnalysis(prevStats, analysis);
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
                  _buildHeaderCell("Trạng thái", flex: 1.5),
                  _buildHeaderCell("Số ngày"),
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
              // Hàng Dữ liệu Trung tính
              TableRow(
                children: [
                  _buildDataCell("Trung tính/Chưa ghi 😐", isBold: true),
                  _buildDataCell("$neu", color: Colors.grey.shade600, isBold: true),
                ],
              ),
              // Hàng Tổng cộng
              TableRow(
                children: [
                  _buildHeaderCell("TỔNG NGÀY", flex: 1.5),
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
          _buildMoodBar("Trung tính/Chưa ghi", neu, total, Colors.blueGrey),

          if (prevWeek != null) ...[
            const SizedBox(height: 24),
            AutoText(
              "📊 So sánh với Tuần ${prevWeek.weekNumber} (${prevWeek.dateRange}):",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade800,
              ),
            ),
            const SizedBox(height: 8),
            _buildComparisonRow("Tích cực 🌟", diff!['posDiff']!),
            _buildComparisonRow("Tiêu cực ⚠️", diff['negDiff']!),
            _buildComparisonRow("Trung tính 😐", diff['neuDiff']!),
            const SizedBox(height: 20),
            //PHÂN TÍCH AI
            ThongKeWeeklyAIAnalysis(
              currStats: analysis, // Dữ liệu tuần hiện tại
              prevStats: prevStats!, // Dữ liệu tuần trước (đã kiểm tra null)
              currDateRange: weeklyData.dateRange,
              prevDateRange: prevWeek.dateRange,
            ),
          ],
        ],
      ),
    );
  }
}

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
  // Giả định API endpoint mới
  final String apiEndpoint = "${Constants.baseUrl}/ai/mood-shift-analysis"; 
  final String tokenKey = Constants.tokenKey;

  // Hàm gọi API đến Server Laravel
  Future<void> _fetchAIAnalysis() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
      aiAnalysis = "Mood Diary đang phân tích dữ liệu tuần này...";
    });
    
    // Chuẩn bị payload
    final payload = {
      'curr_stats': widget.currStats,
      'prev_stats': widget.prevStats,
      'curr_date_range': widget.currDateRange,
      'prev_date_range': widget.prevDateRange,
    };
    debugPrint('DEBUG AI WEEKLY PAYLOAD: ${json.encode(payload)}');
    
    // Lấy token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    debugPrint('DEBUG: Token Flutter: $token');

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
        
        // Kiểm tra lỗi 429 hoặc lỗi chung
        if (response.statusCode == 429) {
             setState(() {
                aiAnalysis = data['analysis'] ?? 'AI đang tạm nghỉ để nạp năng lượng 😅. Hãy thử lại sau ít phút nhé!';
            });
        } else if (response.statusCode != 200) {
            // Lỗi Server/Lỗi API Gemini từ Server
             setState(() {
                aiAnalysis = data['analysis'] ?? "Lỗi server ${response.statusCode}. Không thể phân tích AI.";
            });
        } else {
            // Thành công
            final resultAnalysis = data['analysis'] ?? "Phân tích AI thất bại, nhưng bạn đang làm rất tốt!";
            setState(() {
                aiAnalysis = resultAnalysis;
            });
        }
    } catch (e) {
        // Lỗi mạng hoặc exception
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