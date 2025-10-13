// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:moods_diary/utils/thongbao_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'dart:convert';
// ignore: unused_import
import 'package:shared_preferences/shared_preferences.dart';
// ignore: unused_import
import '../utils/constants.dart';

import 'package:moods_diary/widgets/user_sayhello.dart';
import '../widgets/auto_text.dart';
import '../providers/setting_provider.dart';
import '../services/mood_service.dart';

class DiaryScreen extends StatefulWidget {
  final DateTime? selectedDate;
  const DiaryScreen({super.key, this.selectedDate});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  // Chuyển hex -> Color
  Color _hexToColor(String hexColor) {
    if (hexColor.startsWith('#')) {
      hexColor = hexColor.substring(1);
    }
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  final List<Map<String, String>> emotions = [
    {"type": "fun", "label": "Vui", "icon": "assets/icons/fun.png"},
    {"type": "angry", "label": "Giận dữ", "icon": "assets/icons/angry.png"},
    {"type": "sad", "label": "Buồn", "icon": "assets/icons/sad.png"},
    {"type": "love", "label": "Đang yêu", "icon": "assets/icons/love.png"},
    {"type": "happy", "label": "Hạnh phúc", "icon": "assets/icons/happy.png"},
  ];

  int? selectedEmotionIndex;
  String selectedTag = "Gia đình";
  final TextEditingController _noteController = TextEditingController();
  final MoodService _moodService = MoodService();

  // --- AI Suggestion ---
  String? aiSuggestion;
  bool isLoading = false;

    // Lưu nhật ký
  Future<void> _saveDiaryEntry() async {
    if (selectedEmotionIndex == null || _noteController.text.isEmpty) {
      await showSnackBarAutoText(
        context,
        "Vui lòng chọn cảm xúc và viết nhật ký.",
        isError: true,
      );
      return;
    }

    final emotion = emotions[selectedEmotionIndex!]["label"];
    final note = _noteController.text;

    setState(() => isLoading = true);

    // format ngày (nếu có selectedDate thì dùng nó)
    final date = widget.selectedDate ?? DateTime.now();
    final formattedDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(date);

    // Lưu nhật ký vào DB
    final response = await _moodService.saveMood(
      emotion!,
      selectedTag,
      note,
      date: formattedDate,
    );

    if (response != null && response['data'] != null) {
      await showSnackBarAutoText(
        context,
        "Lưu nhật ký cho ngày $formattedDate thành công!",
      );

      // Reset form nhập liệu
      setState(() {
        aiSuggestion = response['suggestion'];
        selectedTag = "Gia đình";
        selectedEmotionIndex = null;
        _noteController.clear();
      });

    } else {
      await showSnackBarAutoText(
        context,
        response?['message'] ?? 'Lỗi không xác định',
        isError: true,
      );
    }

    setState(() => isLoading = false);
  }


  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
                const SizedBox(height: 20),
                AutoText(
                  "HÔM NAY BẠN THẾ NÀO?",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                    shadows: [
                      // Viền trên
                      Shadow(offset: const Offset(0, -1.5), color: Colors.white), 
                      // Viền dưới
                      Shadow(offset: const Offset(0, 1.5), color: Colors.white), 
                      // Viền trái
                      Shadow(offset: const Offset(-1.5, 0), color: Colors.white), 
                      // Viền phải
                      Shadow(offset: const Offset(1.5, 0), color: Colors.white),
                      // Viền chéo -độ dày viền
                      Shadow(offset: const Offset(2, 2), color: Colors.white),
                      Shadow(offset: const Offset(-2, -2), color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 650,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      // ignore: deprecated_member_use
                      border: Border.all(color: selectedColor.withOpacity(0.5)), 
                    ),
                    child: AutoText(
                      "Chọn cảm xúc ↓",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: selectedColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Danh sách cảm xúc
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: emotions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => setState(() => selectedEmotionIndex = index),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedEmotionIndex == index
                                ? Colors.pink
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          emotions[index]["icon"]!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // TAG
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selectedColor),
                      ),
                      child: Center( 
                        child: AutoText(
                          "TAG",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            color: selectedColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selectedColor),
                        ),
                        child: DropdownButton<String>(
                          value: selectedTag,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: [
                            DropdownMenuItem(value: "Gia đình", child: AutoText("Gia đình")),
                            DropdownMenuItem(value: "Công việc", child: AutoText("Công việc")),
                            DropdownMenuItem(value: "Bạn bè", child: AutoText("Bạn bè")),
                            DropdownMenuItem(value: "Học tập", child: AutoText("Học tập")),
                            DropdownMenuItem(value: "Đời sống", child: AutoText("Đời sống")),
                          ],
                          onChanged: (value) => setState(() => selectedTag = value!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Viết nhật ký
                TextField(
                  controller: _noteController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: "Viết cảm xúc hôm nay...",
                    hintStyle: TextStyle(color: selectedColor),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: selectedColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nút lưu
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _saveDiaryEntry,
                    child: const AutoText(
                      "Lưu nhật ký",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Gợi ý AI
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
