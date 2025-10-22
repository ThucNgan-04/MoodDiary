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
import '../screens/thongke_user_screen.dart'; // ThongKeUserStatChart

class ThongKeScreen extends StatefulWidget {
  const ThongKeScreen({super.key});

  @override
  State<ThongKeScreen> createState() => _ThongKeScreenState();
}

class _ThongKeScreenState extends State<ThongKeScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController; 
  final MoodService _moodService = MoodService();
  
  bool isLoading = true;
  // ignore: unused_field
  List<MoodModel> _moods = [];
  List<_EmotionStat> stats = [];

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  List<DateTime> months = [];

  String? aiSuggestion;

  // Khai báo Tabs
  final List<Tab> _tabs = [
    const Tab(text: 'Cảm xúc tháng'),
    const Tab(text: 'Tỷ lệ chuyển đổi'),
  ];

  @override
  void initState() {
    super.initState();
    // Khởi tạo TabController
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    _generateMonths();
    if (months.isNotEmpty) selectedMonth = months[0];
    _fetchMoods(shouldCallAI: false); 
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _generateMonths() {
    final now = DateTime.now();
    final List<DateTime> tmp = List.generate(12, (i) {
      final m = DateTime(now.year, now.month - i, 1);
      return DateTime(m.year, m.month, 1);
    });

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

  Future<void> _fetchMoods({bool shouldCallAI = true}) async {
    setState(() => isLoading = true);

    final moods = await _moodService.getAllMoods();
    final moodsThisMonth = moods.where((m) =>
      m.createdAt.year == selectedMonth.year &&
      m.createdAt.month == selectedMonth.month
    ).toList();
    if (!mounted) return;
    if (moodsThisMonth.isEmpty) {
      setState(() {
        _moods = [];
        stats = [];
        aiSuggestion = null;
        isLoading = false;
      });
      return;
    }

    final Map<String, int> counter = {};
    for (var m in moodsThisMonth) {
      final key = m.emotion.toString();
      counter[key] = (counter[key] ?? 0) + 1;
    }

    final total = moodsThisMonth.length;
    final calculatedStats = counter.entries.map((e) {
      final percent = total > 0 ? (e.value / total) * 100 : 0.0;
      return _EmotionStat(
        e.key,
        percent,
        _getIconForEmotion(e.key),
        _getColorForEmotion(e.key),
      );
    }).toList();

    // ignore: avoid_init_to_null
    String? suggestion = null;

    if (shouldCallAI) {
      final statsMap = calculatedStats.map((s) => {"emotion": s.label, "value": s.value}).toList();
      suggestion = await _moodService.analyzeStats(statsMap);
    } 

    setState(() {
      _moods = moodsThisMonth;
      stats = calculatedStats;
      aiSuggestion = suggestion; 
      isLoading = false;
    });
  }

  Future<void> _analyzeWithAI() async {
    if (stats.isEmpty) return; 

    setState(() => aiSuggestion = "Đang phân tích..."); 

    final statsData = stats.map((e) => {
      "emotion": e.label,
      "value": e.value,
    }).toList();

    final suggestion = await _moodService.analyzeStats(statsData);

    if (suggestion != null) {
      setState(() {
        aiSuggestion = suggestion;
      });
    } else {
      setState(() {
        aiSuggestion = "Không thể phân tích dữ liệu lúc này.";
      });
    }
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

  // --- CẢM XÚC THÁNG (Biểu đồ Tròn) ---
  Widget _buildEmotionStatTab(Color selectedColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 600,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [ BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5) ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AutoText(
                  "Biểu đồ cảm xúc tháng",
                  style: TextStyle(fontSize: 25, color: Colors.black, fontWeight: FontWeight.bold,),
                ),
                DropdownButton<DateTime>(
                  value: selectedMonth,
                  items: months.map((month) {
                    return DropdownMenuItem<DateTime>(
                      value: month,
                      child: AutoText(
                        "${month.month}/${month.year}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedMonth = DateTime(value.year, value.month, 1);
                      isLoading = true;
                      aiSuggestion = null;
                    });
                    _fetchMoods(shouldCallAI: false); 
                  },
                ),
                const SizedBox(height: 10),
                //Biểu đồ tròn
                if (stats.isEmpty)
                  Container(
                    height: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      ),
                      child: const AutoText(
                          "Chưa có dữ liệu cho tháng này",
                        ),
                  )else
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
                              radius: 130,
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
                    const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 20),

          //Phần Thống kê chi tiết (Icon + %)
          AutoText(
            "THỐNG KÊ CẢM XÚC THÁNG ${selectedMonth.month}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 600,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [ BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5) ],
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: stats.map((e) => _buildStatItem(e.icon, e.value)).toList(),
            ),
          ),
          const SizedBox(height: 30),
          
          // Phần Phân tích AI
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
                    color: Colors.black,
                    shadows: [
                      Shadow(offset: const Offset(0, -1.5), color: Colors.white), 
                      Shadow(offset: const Offset(0, 1.5), color: Colors.white), 
                      Shadow(offset: const Offset(-1.5, 0), color: Colors.white), 
                      Shadow(offset: const Offset(1.5, 0), color: Colors.white),
                      Shadow(offset: const Offset(2, 2), color: Colors.white),
                      Shadow(offset: const Offset(-2, -2), color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                ElevatedButton(
                  onPressed: stats.isEmpty || aiSuggestion == "Đang phân tích..." ? null : _analyzeWithAI,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: AutoText(
                    aiSuggestion == "Đang phân tích..." ? "Đang phân tích..." : "Phân tích cảm xúc",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),

                if (aiSuggestion == "Đang phân tích...")
                  Center(child: CircularProgressIndicator(color: selectedColor,))
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
                        color: selectedColor.withOpacity(0.9),
                      ),
                    ),
                  )
                else if (stats.isNotEmpty)
                  AutoText(
                    "Nhấn 'Phân tích Cảm Xúc' để nhận gợi ý từ MoodDiary.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tỷ LỆ CHUYỂN ĐỔI (Biểu đồ Đường) ---
  Widget _buildTrendChartTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ThongKeUserStatChart(
            year: selectedMonth.year,
            month: selectedMonth.month,
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Biểu đồ đường hiển thị xu hướng cảm xúc hàng ngày trong tháng.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Đảm bảo TabController đã sẵn sàng trước khi build các widget phụ thuộc
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator()); 
    }

    return Consumer<SettingProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        final Color selectedColor = settings.colorTheme != null
            ? Color(int.parse(settings.colorTheme!.replaceFirst('#', '0xff')))
            : const Color(0xFFFFC0CB);

        return Scaffold(
          backgroundColor: selectedColor.withOpacity(0.2),
          body: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                child: UserSayHello(),
              ),
              const SizedBox(height: 10),

              // Tab Bar
              TabBar(
                // Sử dụng toán tử ! vì đã kiểm tra null ở trên
                controller: _tabController!, 
                tabs: _tabs,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorColor: selectedColor,
              ),
              
              //Tab Bar View (Nội dung từng tab)
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        // Sử dụng toán tử ! vì đã kiểm tra null ở trên
                        controller: _tabController!, 
                        children: [
                          _buildEmotionStatTab(selectedColor),
                          _buildTrendChartTab(),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
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