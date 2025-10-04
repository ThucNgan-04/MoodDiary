import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/user_sayhello.dart';
import '../widgets/auto_text.dart';
import '../providers/setting_provider.dart';

import '../services/mood_service.dart';
import '../models/mood_model.dart';

// ignore: unused_import
import '../utils/monthly_stat_cache.dart';

class ThongKeScreen extends StatefulWidget {
  const ThongKeScreen({super.key});

  @override
  State<ThongKeScreen> createState() => _ThongKeScreenState();
}

class _ThongKeScreenState extends State<ThongKeScreen> {
  final MoodService _moodService = MoodService();
  bool isLoading = true;
  // ignore: unused_field
  List<MoodModel> _moods = [];
  List<_EmotionStat> stats = [];

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  List<DateTime> months = [];

  String? aiSuggestion;

  @override
  void initState() {
    super.initState();
    _generateMonths();
    if (months.isNotEmpty) selectedMonth = months[0];
    _fetchMoods();
  }

  void _generateMonths() {
    final now = DateTime.now();
    // tạo 6 tháng gần nhất, mỗi phần tử là ngày 1 của tháng
    final List<DateTime> tmp = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - i, 1);
      return DateTime(m.year, m.month, 1);
    });

    // loại bỏ trùng và giữ thứ tự (nhiều cách, ở đây dùng công thức đơn giản)
    final seen = <String>{};
    months = [];
    for (var m in tmp) {
      final key = "${m.year}-${m.month}";
      if (!seen.contains(key)) {
        seen.add(key);
        months.add(m);
      }
    }
  }

  Future<void> _fetchMoods() async {
    setState(() => isLoading = true);

    // Lấy toàn bộ moods
    final moods = await _moodService.getAllMoods();

    // Lọc đúng theo tháng được chọn
    final moodsThisMonth = moods.where((m) =>
      m.createdAt.year == selectedMonth.year &&
      m.createdAt.month == selectedMonth.month
    ).toList();

    if (moodsThisMonth.isEmpty) {
      setState(() {
        _moods = [];
        stats = [];
        isLoading = false;
      });
      return;
    }

    // Đếm cảm xúc
    final Map<String, int> counter = {};
    for (var m in moodsThisMonth) {
      counter[m.emotion] = (counter[m.emotion] ?? 0) + 1;
    }

    final total = moodsThisMonth.length;
    final tmp = counter.entries.map((e) {
      final percent = (e.value / total) * 100;
      return _EmotionStat(
        e.key,
        percent,
        _getIconForEmotion(e.key),
        _getColorForEmotion(e.key),
      );
    }).toList();

    setState(() {
      _moods = moodsThisMonth;
      stats = tmp;
      isLoading = false;
    });
  }

  void _buildStatsFromCache(Map<String, dynamic>? cached) {
    if (cached == null) {
      setState(() {
        _moods = [];
        stats = [];
        isLoading = false;
      });
      return;
    }

    final moodsJson = (cached['moods'] as List<dynamic>? ?? []);
    final moodsThisMonth = moodsJson.map((j) => MoodModel.fromJson(j)).toList();

    if (moodsThisMonth.isEmpty) {
      setState(() {
        _moods = [];
        stats = [];
        isLoading = false;
      });
      return;
    }

    final Map<String, int> counter = {};
    for (var m in moodsThisMonth) {
      counter[m.emotion] = (counter[m.emotion] ?? 0) + 1;
    }

    final total = moodsThisMonth.length;
    final tmp = counter.entries.map((e) {
      final percent = (e.value / total) * 100;
      return _EmotionStat(
        e.key,
        percent,
        _getIconForEmotion(e.key),
        _getColorForEmotion(e.key),
      );
    }).toList();

    setState(() {
      _moods = moodsThisMonth;
      stats = tmp;
      isLoading = false;
    });
  }

  String _getIconForEmotion(String emotion) {
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
  Color _getColorForEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case "vui":
        return const Color.fromARGB(212, 235, 230, 63);
      case "hạnh phúc":
        return const Color.fromARGB(234, 3, 160, 8);
      case "buồn":
        return const Color.fromARGB(228, 113, 82, 225);
      case "giận dữ":
        return Colors.red;
      default:
        return const Color.fromARGB(143, 232, 112, 152);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        final Color selectedColor = settings.colorTheme != null
            ? Color(int.parse(settings.colorTheme!.replaceFirst('#', '0xff')))
            : const Color(0xFFFFC0CB);

        return Scaffold(
          // ignore: deprecated_member_use
          backgroundColor: selectedColor.withOpacity(0.2),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const UserSayHello(),
                      const SizedBox(height: 20),

                      AutoText(
                        textAlign: TextAlign.center,
                        "Biểu đồ cảm xúc Tháng",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: selectedColor,
                        ),
                      ),
                      // Dropdown tháng
                      DropdownButton<DateTime>(
                        value: selectedMonth,
                        items: months.map((month) {
                          return DropdownMenuItem<DateTime>(
                            value: month,
                            child: AutoText(
                              "${month.month}/${month.year}",
                              style: TextStyle(
                                color: selectedColor,
                                fontSize: 25,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return; // <-- SỬA: kiểm tra NULL
                          setState(() {
                            selectedMonth = DateTime(value.year, value.month, 1);
                            isLoading = true;
                          });
                          _fetchMoods();
                        },
                      ),
                      const SizedBox(height: 20),

                      if (stats.isEmpty)
                        Container(
                          height: 220,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const AutoText("Chưa có dữ liệu cho tháng này"),
                        )
                      else
                        AspectRatio(
                          aspectRatio: 1.3,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 0,
                              sections: stats.map((e) {
                                return PieChartSectionData(
                                  color: e.color,
                                  value: e.value,
                                  title: "${e.value.toStringAsFixed(1)}%",
                                  radius: 140,
                                  titleStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 30),
                      
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: stats.map((e) => _buildStatItem(e.icon, e.value)).toList(),
                      ),
                      const SizedBox(height: 30),

                      Center(
                        child: Column(
                          children: [
                            AutoText(
                              "MOODDIARY CÓ ĐÔI LỜI MUỐN GỬI ♥",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: selectedColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (isLoading)
                              const CircularProgressIndicator()
                            else if (aiSuggestion != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: selectedColor),
                                ),
                                child: AutoText(
                                  aiSuggestion!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.pink.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStatItem(String icon, double percent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        
        Image.asset(icon, width: 37, height: 37),
        const SizedBox(height: 4),
        Text("${percent.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _EmotionStat {
  final String label;
  final double value;
  final String icon;
  final Color color;
  _EmotionStat(this.label, this.value, this.icon, this.color);
}