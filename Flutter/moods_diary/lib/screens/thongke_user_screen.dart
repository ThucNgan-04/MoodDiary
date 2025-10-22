import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:moods_diary/widgets/phantich_chuyendoimood.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/constants.dart';

class ThongKeUserStatChart extends StatefulWidget {
  final int year;
  final int month;
  const ThongKeUserStatChart({super.key, required this.year, required this.month});

  @override
  State<ThongKeUserStatChart> createState() => _ThongKeUserStatChartState();
}

class _ThongKeUserStatChartState extends State<ThongKeUserStatChart> {
  bool isLoading = true;
  Map<String, dynamic> trendData = {};

  int negToPosCount = 0; // Tiêu cực -> Tích cực
  int posToNegCount = 0; // Tích cực -> Tiêu cực

  @override
  void initState() {
    super.initState();
    fetchTrend();
  }

  @override
  void didUpdateWidget(covariant ThongKeUserStatChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      setState(() {
        isLoading = true;
        trendData = {};
        negToPosCount = 0;
        posToNegCount = 0;
      });
      fetchTrend();
    }
  }

  Future<void> fetchTrend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);

      final res = await http.get(
        Uri.parse("${Constants.baseUrl}/mood-daily-trend/${widget.year}/${widget.month}"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );
      debugPrint("Trend API response: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data.isNotEmpty) {
          setState(() {
            trendData = data;
            isLoading = false;
          });
          analyzeTransitions(); 
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching trend: $e");
      setState(() => isLoading = false);
    }
  }

// -------------------- LOGIC PHÂN TÍCH --------------------

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

  void analyzeTransitions() {
    int nToP = 0;
    int pToN = 0;
    
    final sortedDays = trendData.keys.map((k) => int.parse(k)).toList()..sort();

    if (sortedDays.length < 2) {
      setState(() {
        negToPosCount = 0;
        posToNegCount = 0;
      });
      return;
    }

    for (int i = 0; i < sortedDays.length - 1; i++) {
      final currentDay = sortedDays[i].toString();
      final nextDay = sortedDays[i + 1].toString();
      
      if (!trendData.containsKey(currentDay) || !trendData.containsKey(nextDay)) continue;

      final currentEmotion = trendData[currentDay] as String;
      final nextEmotion = trendData[nextDay] as String;

      final isCurrentPositive = isPositiveMood(currentEmotion);
      final isNextPositive = isPositiveMood(nextEmotion);

      if (!isCurrentPositive && isNextPositive) {
        nToP++;
      } 
      else if (isCurrentPositive && !isNextPositive) {
        pToN++;
      }
    }

    setState(() {
      negToPosCount = nToP;
      posToNegCount = pToN;
    });
  }

// -------------------- HÀM HỖ TRỢ HIỂN THỊ --------------------

  Color getColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case "vui":
        return const Color.fromARGB(212, 235, 230, 63);
      case "hạnh phúc":
        return const Color.fromARGB(234, 3, 160, 8);
      case "buồn":
        return const Color.fromARGB(228, 113, 82, 225);
      case "giận dữ":
        return Colors.red;
      case "đang yêu":
        return const Color.fromARGB(143, 232, 112, 152);
      default:
        return Colors.grey;
    }
  }

  String getIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case "vui":
        return "assets/icons/fun.png";
      case "giận dữ":
        return "assets/icons/angry.png";
      case "buồn":
        return "assets/icons/sad.png";
      case "đang yêu":
        return "assets/icons/love.png";
      case "hạnh phúc":
        return "assets/icons/happy.png";
      default:
        return "assets/icons/love.png";
    }
  }

  double getMoodValue(String emotion) {
    switch (emotion.toLowerCase()) {
      case "buồn":
        return 1;
      case "giận dữ":
        return 2;
      case "đang yêu":
        return 3;
      case "vui":
        return 4;
      case "hạnh phúc":
        return 5;
      default:
        return 0;
    }
  }

  String getMoodLabel(double value) {
    switch (value.toInt()) {
      case 1:
        return "Buồn";
      case 2:
        return "Giận Dữ";
      case 3:
        return "Đang Yêu";
      case 4:
        return "Vui";
      case 5:
        return "Hạnh Phúc";
      default:
        return "";
    }
  }

// -------------------- HÀM BUILD --------------------
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final int totalDaysRecorded = trendData.keys.length;
    final List<FlSpot> spots = [];
    int daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      if (trendData.containsKey(day.toString())) {
        final emotion = trendData[day.toString()];
        final y = getMoodValue(emotion);
        spots.add(FlSpot(day.toDouble(), y));
      }
    }

    if (spots.isEmpty) {
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
        child: const Center(child: Text("Chưa có dữ liệu biểu đồ đường.")),
      );
    }

    final emotionSet = trendData.values.toSet().cast<String>().toList();
    final yAxisValues = [1.0, 2.0, 3.0, 4.0, 5.0];

    return Column(
      children: [
        // BIỂU ĐỒ ĐƯỜNG VÀ CHÚ THÍCH
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 16, bottom: 16), // Thêm margin bottom
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
            children: [
              const Text(
                "📈 Biểu đồ đường cảm xúc trong tháng",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 114, 53, 102)), 
              ),
              const SizedBox(height: 20),

              // Biểu đồ đường
              AspectRatio(
                aspectRatio: 1.6,
                child: LineChart(
                  LineChartData(
                    minX: 1,
                    maxX: daysInMonth.toDouble(),
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
                        isCurved: true,
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
                            style: TextStyle(fontSize: 13, color: Colors.grey)),
                        axisNameSize: 20,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            int day = value.toInt();
                            if (day % 2 != 0) {
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
                        int day = value.toInt();
                        if (day % 2 != 0) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        }
                        return FlLine(color: Colors.transparent);
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
                        Image.asset(iconPath, width: 26, height: 26),
                        const SizedBox(width: 6),
                        Text(
                          emotion,
                          style: TextStyle(
                            fontSize: 15,
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

        //PHÂN TÍCH CHUYỂN ĐỔI TÂM TRẠNG
        ChuyenDoiMood( // Tên class đã được đổi thành ChuyenDoiMood
          negToPosCount: negToPosCount,
          posToNegCount: posToNegCount,
          totalDaysRecorded: totalDaysRecorded,
        ),
      ],
    );
  }
}