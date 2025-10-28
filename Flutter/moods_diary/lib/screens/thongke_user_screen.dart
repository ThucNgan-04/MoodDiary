import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:moods_diary/widgets/auto_text.dart';
import 'package:moods_diary/utils/date_ultils.dart'; 
import 'package:moods_diary/widgets/thong_ke_tuan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/constants.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

class ThongKeUserStatChart extends StatefulWidget {
  final int year;
  final int month;
  const ThongKeUserStatChart({super.key, required this.year, required this.month});

  @override
  State<ThongKeUserStatChart> createState() => _ThongKeUserStatChartState();
}

class _ThongKeUserStatChartState extends State<ThongKeUserStatChart> {
  bool isLoading = true;
  Map<String, dynamic> currentMonthTrendData = {}; // Dữ liệu tháng hiện tại

  List<Map<String, dynamic>> allMonthMoodEntries = [];
  // Logic theo tuần
  List<WeeklyData> weeks = [];
  WeeklyData? selectedWeek;
  Map<String, dynamic> selectedWeekMoods = {}; // Dữ liệu cảm xúc chỉ trong tuần được chọn
  List<Map<String, dynamic>> selectedWeekAllEntries = [];
  
  List<Map<String, dynamic>> _filterEntriesByWeek(WeeklyData week) {
    // Nếu không có dữ liệu tháng, trả về danh sách rỗng
    if (allMonthMoodEntries.isEmpty) return []; 
    
    final weekStartDay = week.dates.first.day;
    final weekEndDay = week.dates.last.day;

    return allMonthMoodEntries.where((entry) {
      final dateRaw = entry['date'];
      if (dateRaw is String) {
        try {
          final entryDateTime = DateTime.parse(dateRaw).toLocal(); 
          final entryDay = entryDateTime.day;
          
          // Chỉ lấy các bản ghi có ngày nằm trong phạm vi của tuần này
          return entryDay >= weekStartDay && entryDay <= weekEndDay;
        } catch (e) {
          debugPrint('Error parsing date during filtering: $e');
          return false;
        }
      }
      return false;
    }).toList();
  }

  // Dữ liệu cho phân tích chuyển đổi trong tuần
  int negToPosCount = 0;
  int posToNegCount = 0;
  int totalDaysRecordedInWeek = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didUpdateWidget(covariant ThongKeUserStatChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      _initializeData();
    }
  }
  
  // Hàm khởi tạo dữ liệu
  void _initializeData() {
    setState(() {
      isLoading = true;
      weeks = getWeeksInMonth(widget.year, widget.month);
      selectedWeek = weeks.isNotEmpty ? weeks.first : null;
    }); 

    // Chờ cả 2 API gọi xong
    Future.wait([
      fetchTrend(),
      fetchAllEntriesForMonth(),
    ]).then((_) {
      _updateWeeklyData();

      setState(() {
        isLoading = false;
      });
    });
  }
  // Cập nhật dữ liệu khi chọn tuần mới
  void _updateWeeklyData() {
    if (selectedWeek == null) {
      setState(() {
        selectedWeekMoods = {};
        selectedWeekAllEntries = [];
        totalDaysRecordedInWeek = 0;
        negToPosCount = 0;
        posToNegCount = 0;
      });
      return;
    }

    selectedWeekMoods = {};
    selectedWeekAllEntries = [];
    
    for (DateTime date in selectedWeek!.dates) {
      final dayKey = date.day.toString();
      if (currentMonthTrendData.containsKey(dayKey)) {
        selectedWeekMoods[dayKey] = currentMonthTrendData[dayKey];
      }
    }
    
    for (final entry in allMonthMoodEntries) {
        final dateRaw = entry['date'];
        if (dateRaw is String) {
            try {
                final entryDateTime = DateTime.parse(dateRaw); 
                final entryDateOnlyLocal = DateTime(
                    entryDateTime.toLocal().year, 
                    entryDateTime.toLocal().month, 
                    entryDateTime.toLocal().day
                );
                final isCurrentWeekMatch = selectedWeek!.dates.any((weekDate) =>
                  weekDate.isAtSameMomentAs(entryDateOnlyLocal)
                );
                if (isCurrentWeekMatch) {
                    selectedWeekAllEntries.add(entry);
                }
            } catch (e) {
                debugPrint('Error parsing date $dateRaw for entry: $e');
            }
        }
    }
    totalDaysRecordedInWeek = selectedWeekAllEntries.length;
    analyzeTransitions(); // Phân tích chuyển đổi theo tuần
    setState(() {
      debugPrint('DEBUG: selectedWeekAllEntries count AFTER FIX: ${selectedWeekAllEntries.length}');
      debugPrint('DEBUG: selectedWeekMoods count: ${selectedWeekMoods.length}');
    });
  }

  Future<void> fetchTrend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);
      final url = "${Constants.baseUrl}/mood-daily-trend/${widget.year}/${widget.month}";

      final res = await http.get(
        Uri.parse(url),
          headers: {
           "Authorization": "Bearer $token",
           "Accept": "application/json",
          },
        );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data.isNotEmpty) {
          currentMonthTrendData = data;
          return;
        }
      }
      currentMonthTrendData = {};
    } catch (e) {
      debugPrint("Error fetching trend for ${widget.month}/${widget.year}: $e");
      currentMonthTrendData = {};
    }
  }

  Future<void> fetchAllEntriesForMonth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);
      
      // Tính toán ngày đầu và ngày cuối của tháng
      final startDate = DateTime(widget.year, widget.month, 1);
      final endDate = DateTime(widget.year, widget.month + 1, 0);
      
      final startDateStr = formatDateForApi(startDate); 
      final endDateStr = formatDateForApi(endDate);
      final url = "${Constants.baseUrl}/mood-all-entries/$startDateStr/$endDateStr";

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          allMonthMoodEntries = data.cast<Map<String, dynamic>>();
          return;
        }
      }
      allMonthMoodEntries = [];
    } catch (e) {
      debugPrint("Error fetching all entries for ${widget.month}/${widget.year}: $e");
      allMonthMoodEntries = [];
    }
  }
  
  bool isPositiveMood(String emotion) {
    switch (emotion.toLowerCase()) {
      case "hạnh phúc":
      case "vui":
      case "đang yêu":
        return true;
      case "buồn":
      case "giận dữ":
        return false;
      default:
        return false;
    }
  }
  
  // Phân tích chuyển đổi (áp dụng cho tuần)
  void analyzeTransitions() {
    int nToP = 0;
    int pToN = 0;
    
    final sortedDays = selectedWeekMoods.keys.map((k) => int.parse(k)).toList()..sort();

    if (sortedDays.length < 2) {
      negToPosCount = 0;
      posToNegCount = 0;
      return;
    }

    for (int i = 0; i < sortedDays.length - 1; i++) {
      final currentDay = sortedDays[i].toString();
      final nextDay = sortedDays[i + 1].toString();
      
      // Đảm bảo là ngày liên tiếp (để tính chuyển đổi)
      if (sortedDays[i+1] != sortedDays[i] + 1) continue;

      final currentEmotion = selectedWeekMoods[currentDay] as String;
      final nextEmotion = selectedWeekMoods[nextDay] as String;

      final isCurrentPositive = isPositiveMood(currentEmotion);
      final isNextPositive = isPositiveMood(nextEmotion);

      if (!isCurrentPositive && isNextPositive) {
        nToP++; // Tiêu cực -> Tích cực
      } 
      else if (isCurrentPositive && !isNextPositive) {
        pToN++; // Tích cực -> Tiêu cực
      }
    }

    setState(() {
      negToPosCount = nToP;
      posToNegCount = pToN;
    });
  }

  Color getColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case "vui": return const Color.fromARGB(212, 235, 230, 63);
      case "hạnh phúc": return const Color.fromARGB(234, 3, 160, 8);
      case "buồn": return const Color.fromARGB(228, 113, 82, 225);
      case "giận dữ": return Colors.red;
      case "đang yêu": return const Color.fromARGB(143, 232, 112, 152);
      default: return Colors.grey;
    }
  }

  String getIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case "vui": return "assets/icons/fun.png";
      case "giận dữ": return "assets/icons/angry.png";
      case "buồn": return "assets/icons/sad.png";
      case "đang yêu": return "assets/icons/love.png";
      case "hạnh phúc": return "assets/icons/happy.png";
      default: return "assets/icons/love.png";
    }
  }

  double getMoodValue(String emotion) {
    switch (emotion.toLowerCase()) {
      case "buồn": return 1;
      case "giận dữ": return 2;
      case "đang yêu": return 3;
      case "vui": return 4;
      case "hạnh phúc": return 5;
      default: return 0;
    }
  }

  String getMoodLabel(double value) {
    switch (value.toInt()) {
      case 1: return "Buồn";
      case 2: return "Giận Dữ";
      case 3: return "Đang Yêu";
      case 4: return "Vui";
      case 5: return "Hạnh Phúc";
      default: return "";
    }
  }

  // Hàm gom dữ liệu cảm xúc của tất cả các tuần trong tháng
Map<int, Map<String, dynamic>> _buildAllWeekMoods() {
  final Map<int, Map<String, dynamic>> result = {};

  for (final week in weeks) {
    final Map<String, dynamic> moods = {};
    for (DateTime date in week.dates) {
      final dayKey = date.day.toString();
      if (currentMonthTrendData.containsKey(dayKey)) {
        moods[dayKey] = currentMonthTrendData[dayKey];
      }
    }
    result[week.weekNumber] = moods;
  }
  return result;
}

// -------------------- HÀM BUILD --------------------
  @override
  Widget build(BuildContext context) {
    final previousWeek = selectedWeek != null
    ? weeks.firstWhereOrNull((w) => w.weekNumber == selectedWeek!.weekNumber - 1)
    : null;

    final List<Map<String, dynamic>> previousWeekEntries = 
        previousWeek != null 
            ? _filterEntriesByWeek(previousWeek) 
            : [];

    debugPrint('DEBUG: Previous Week Entries for Summary: ${previousWeekEntries.length}');
    
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final List<FlSpot> spots = [];
    //lấy dữ liệu từ tuần đã chọn để vẽ biểu đồ
    if (selectedWeek != null) {
      for (DateTime date in selectedWeek!.dates) { 
        final day = date.day; 
        final dayKey = day.toString();
        if (currentMonthTrendData.containsKey(dayKey)) {
          final emotion = currentMonthTrendData[dayKey];
          final y = getMoodValue(emotion);
          spots.add(FlSpot(day.toDouble(), y)); 
        }
      }
    }
    
    if (currentMonthTrendData.isEmpty && allMonthMoodEntries.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6)
          ],
        ),
        child: const Center(child: AutoText("Chưa có dữ liệu cảm xúc trong tháng này để phân tích.")),
      );
    }
    
    final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;
    final emotionSet = currentMonthTrendData.values.toSet().cast<String>().toList();
    final yAxisValues = [1.0, 2.0, 3.0, 4.0, 5.0];
    
    return Column(
      children: [
        // BIỂU ĐỒ ĐƯỜNG VÀ DROPDOWN CHỌN TUẦN
      Container(
        width: 600,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [
            BoxShadow(
                color: Colors.pink.withOpacity(0.1), 
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: AutoText(
                "Biểu đồ đường cảm xúc của",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 114, 53, 102)), 
              ),
            ),
            const SizedBox(height: 10),

            // DROP DOWN CHỌN TUẦN
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.pink.shade50.withOpacity(0.7), 
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.pink.shade300, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<WeeklyData>(
                  value: selectedWeek,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.pink.shade700),
                  isExpanded: true,
                  hint: const AutoText("Chọn tuần để xem", style: TextStyle(color: Colors.grey)),
                  onChanged: (WeeklyData? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedWeek = newValue;
                      });
                      _updateWeeklyData();
                    }
                  },
                  items: weeks.map<DropdownMenuItem<WeeklyData>>((WeeklyData week) {
                    return DropdownMenuItem<WeeklyData>(
                      value: week,
                      child: Center( 
                        child: AutoText(
                          "Tuần ${week.weekNumber} (${week.dateRange})",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Biểu đồ đường FLChart
            AspectRatio(
              aspectRatio: 1.6,
              child: LineChart(
                LineChartData(
                  // Giới hạn trục X theo ngày của tuần được chọn
                  minX: selectedWeek?.dates.first.day.toDouble() ?? 1, 
                  maxX: selectedWeek?.dates.last.day.toDouble() ?? daysInMonth.toDouble(),
                  minY: 1,
                  maxY: 5,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final emotionLabel = getMoodLabel(touchedSpot.y);
                          final emotionColor = getColor(emotionLabel); 
                          
                          return LineTooltipItem(
                            'Ngày ${touchedSpot.x.toInt()}: $emotionLabel',
                            TextStyle(
                                color: emotionColor, 
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.3), width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: false, 
                      color: const Color.fromARGB(255, 232, 112, 152), 
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
                        final emotion = getMoodLabel(spot.y);
                        final color = getColor(emotion);
                        return FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      }),
                      spots: spots,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromARGB(255, 232, 112, 152)
                                .withOpacity(0.3),
                            const Color.fromARGB(255, 232, 112, 152)
                                .withOpacity(0.01)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text("Trục X: Ngày trong tháng",
                          style: TextStyle(fontSize: 15, color: Colors.grey)),
                      axisNameSize: 20,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        // Hiển thị tất cả các ngày trong tuần được chọn
                        interval: 1, 
                        getTitlesWidget: (value, meta) {
                          int day = value.toInt();
                          if (selectedWeek != null && selectedWeek!.dates.any((d) => d.day == day)) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '$day',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35, 
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (yAxisValues.contains(value)) {
                            final label = getMoodLabel(value);
                            final iconPath = getIcon(label);
                            
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8.0,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0), 
                                child: Image.asset(iconPath, width: 20, height: 20), 
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      if (yAxisValues.contains(value)) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      }
                      return FlLine(color: Colors.transparent);
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

              // Legend (Chú thích cảm xúc)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: emotionSet.map((emotion) {
                    final color = getColor(emotion);
                    final iconPath = getIcon(emotion);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(iconPath, width: 23, height: 23),
                        const SizedBox(width: 3),
                        AutoText(
                          emotion,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // BẢNG THỐNG KÊ TUẦN (MỚI)
        if (selectedWeek != null) 
          ThongKeWeeklySummary(
            key: ValueKey(selectedWeek),
            weeklyData: selectedWeek!,
            weekMoods: selectedWeekMoods,
            allWeeklyMoodEntries: selectedWeekAllEntries,
            allWeeks: weeks,
            allWeekMoods: _buildAllWeekMoods(),
            isPositiveMood: isPositiveMood,
            negToPosCount: negToPosCount,
            posToNegCount: posToNegCount,
            allPreviousWeeklyMoodEntries: previousWeekEntries, 
          ),
      ],
    );
  }
}
