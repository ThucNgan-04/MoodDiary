// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
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
    return Consumer<SettingProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        final Color selectedColor = settings.colorTheme != null
            ? _hexToColor(settings.colorTheme!)
            : const Color(0xFFFFC0CB);
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
                  "Nhật kí cảm xúc của bạn",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: selectedColor,
                  ),
                ),
                const SizedBox(height: 10),

                // ---- LỊCH ----
                TableCalendar(
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
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: selectedColor.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: selectedColor,
                      shape: BoxShape.circle,
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
                              Text(
                                DateFormat('yyyy-MM-dd HH:mm').format(mood.createdAt),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),

                              Text("${mood.emotion} - Tag: ${mood.tag}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          
                          subtitle: Text(mood.note),

                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Xóa nhật ký"),
                                  content: const Text("Bạn có chắc muốn xóa nhật ký này?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa")),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                final result = await _moodService.deleteMood(mood.id!);
                                if (result['success']) {
                                  _fetchMoods();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Đã xóa nhật ký")),
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
