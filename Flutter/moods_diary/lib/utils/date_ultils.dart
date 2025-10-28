// File: utils/date_utils.dart

// ignore: unused_import
import 'package:flutter/material.dart';

// Class chứa thông tin chi tiết về một tuần
class WeeklyData {
  final int weekNumber;
  final String dateRange;
  final List<int> days; // Danh sách các ngày trong tuần (VD: [1, 2, 3, 4, 5, 6, 7])

  WeeklyData({
    required this.weekNumber,
    required this.dateRange,
    required this.days,
  });
}

// Hàm chia tháng thành các tuần
List<WeeklyData> getWeeksInMonth(int year, int month) {
  List<WeeklyData> weeks = [];
  
  // Ngày đầu tiên của tháng
  DateTime firstDayOfMonth = DateTime(year, month, 1);
  // Số ngày trong tháng
  int daysInMonth = DateTime(year, month + 1, 0).day;
  
  int currentDay = 1;
  int weekCounter = 1;
  
  while (currentDay <= daysInMonth) {
    List<int> daysOfWeek = [];
    DateTime startDate = DateTime(year, month, currentDay);
    
    // Tính ngày kết thúc tuần (Chủ nhật)
    // Tức là 7 ngày kể từ ngày bắt đầu, hoặc đến ngày cuối tháng
    // weekday 1=Monday, 7=Sunday
    int daysUntilSunday = 7 - startDate.weekday;
    if (startDate.weekday == 7) { // Nếu ngày bắt đầu là Chủ nhật, thì tuần chỉ còn 1 ngày
        daysUntilSunday = 0;
    }
    
    // Ngày kết thúc mặc định là ngày cuối cùng của tuần
    int endDay = currentDay + daysUntilSunday;
    
    // Kiểm tra nếu ngày kết thúc vượt quá số ngày trong tháng
    if (endDay > daysInMonth) {
      endDay = daysInMonth;
    }
    
    // Điền danh sách ngày trong tuần
    for (int day = currentDay; day <= endDay; day++) {
      daysOfWeek.add(day);
    }
    
    // Tạo chuỗi ngày (VD: 01/01 - 07/01)
    String dateRange = "${_formatDay(currentDay)}/${_formatMonth(month)} - ${_formatDay(endDay)}/${_formatMonth(month)}";

    weeks.add(WeeklyData(
      weekNumber: weekCounter,
      dateRange: dateRange,
      days: daysOfWeek,
    ));
    
    // Cập nhật ngày bắt đầu tuần tiếp theo
    currentDay = endDay + 1;
    weekCounter++;
  }
  
  return weeks;
}

// Hàm định dạng ngày/tháng thành 2 chữ số
String _formatDay(int day) {
  return day.toString().padLeft(2, '0');
}

String _formatMonth(int month) {
  return month.toString().padLeft(2, '0');
}