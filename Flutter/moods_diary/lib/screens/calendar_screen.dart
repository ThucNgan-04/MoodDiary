
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:moods_diary/utils/thongbao_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:moods_diary/widgets/user_sayhello.dart';
import '../widgets/auto_text.dart';
import '../providers/setting_provider.dart';
import '../services/mood_service.dart';
import '../models/mood_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final MoodService _moodService = MoodService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<MoodModel> _moods = [];
  bool isLoading = false;

  Color _hexToColor(String hexColor) {
    if (hexColor.startsWith('#')) {
      hexColor = hexColor.substring(1);
    }
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  void initState() {
    super.initState();
    _fetchMoods();
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
      return "assets/icons/default.png";
    }
  }
  
  Future<void> _fetchMoods() async {
    setState(() => isLoading = true);
    final dateString =
        "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}";
    final moods = await _moodService.getMoodsByDate(dateString);
    setState(() {
      _moods = moods;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Consumer<SettingProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        final Color selectedColor = settings.colorTheme != null
            ? _hexToColor(settings.colorTheme!)
            : const Color(0xFFFFC0CB);

        final Color onSelectedColor = Theme.of(context).colorScheme.onPrimary;
        
        return Scaffold(
          // ignore: deprecated_member_use
          backgroundColor: selectedColor.withOpacity(0.2),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const UserSayHello(),
                const SizedBox(height: 10),

                AutoText(
                  "NHẬT KÝ CẢM XÚC CỦA BẠN",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(230, 140, 65, 0),
                    fontStyle: FontStyle.italic,
                    shadows: [
                      // Viền trên
                      Shadow(offset: const Offset(0, -1.5), color: Colors.white), 
                      // Viền dưới
                      Shadow(offset: const Offset(0, 1.5), color: Colors.white), 
                      // Viền trái
                      Shadow(offset: const Offset(-1.5, 0), color: Colors.white), 
                      // Viền phải
                      Shadow(offset: const Offset(1.5, 0), color: Colors.white),
                      // Viền chéo (tùy chọn để làm viền dày hơn)
                      Shadow(offset: const Offset(2, 2), color: Colors.white),
                      Shadow(offset: const Offset(-2, -2), color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ---- LỊCH ----
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.grey.withOpacity(0.15),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2100),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _fetchMoods();
                    },
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false, // ẩn "2 WEEKS"
                      titleTextStyle: TextStyle(
                        color: Colors.pinkAccent, // Màu chữ tháng/năm
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: Icon(Icons.chevron_left, color: Colors.pinkAccent),
                      rightChevronIcon: Icon(Icons.chevron_right, color: Colors.pinkAccent),
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: selectedColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ---- Danh sách nhật ký ----
                if (isLoading)
                  const CircularProgressIndicator()
                else if (_moods.isEmpty)
                  const AutoText("Không có nhật ký cho ngày này.")
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _moods.length,
                    itemBuilder: (context, index) {
                      final mood = _moods[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoText(
                                DateFormat('yyyy-MM-dd HH:mm').format(mood.createdAt),
                                style: const TextStyle(fontSize: 18, color: Colors.grey),
                              ),

                              Row(
                                children: [
                                  Image.asset(
                                    _getIconForEmotion(mood.emotion),
                                    width: 25,
                                    height: 25,
                                  ),
                                  const SizedBox(width: 8),
                                  AutoText(
                                    "- ${mood.emotion} ",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              
                              //tag có background
                              Text.rich(
                                TextSpan(
                                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                                  children: [
                                    const TextSpan(
                                      text: "Tag: ",
                                      style: TextStyle(color: Colors.black), 
                                    ),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20),),
                                        child: AutoText(
                                          mood.tag,
                                          style: const TextStyle(
                                            fontSize: 13, 
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        
                          subtitle: Text(mood.note),

                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const AutoText("Xóa nhật ký"),
                                  content: const AutoText("Bạn có chắc muốn xóa nhật ký này?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const AutoText("Hủy")),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const AutoText("Xóa")),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                final result = await _moodService.deleteMood(mood.id!);
                                if (result['success']) {
                                  _fetchMoods();
                                  await showSnackBarAutoText(
                                    context,
                                    "Đã xóa nhật ký ☻",
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}