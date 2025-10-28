// ignore: unused_import
import 'package:flutter/material.dart';

// Class chứa thông tin chi tiết về một tuần
class WeeklyData {
  final int weekNumber;
  final String dateRange;
  final List<DateTime> dates; // Danh sách các ngày trong tuần (VD: [1, 2, 3, 4, 5, 6, 7])

  WeeklyData({
    required this.weekNumber,
    required this.dateRange,
    required this.dates,
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
    List<DateTime> datesOfWeek = [];
    int startDay = currentDay;
    int potentialEndDay = currentDay + 6;
    int endDay = potentialEndDay > daysInMonth ? daysInMonth : potentialEndDay;

    for (int day = currentDay; day <= endDay; day++) {
      datesOfWeek.add(DateTime(year, month, day));
    }
    // Tạo chuỗi ngày (VD: 01/01 - 07/01)
    String dateRange = "${_formatDay(currentDay)}/${_formatMonth(month)} - ${_formatDay(endDay)}/${_formatMonth(month)}";
    
    weeks.add(WeeklyData(
      weekNumber: weekCounter,
      dateRange: dateRange,
      dates: datesOfWeek,
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

String formatDateForApi(DateTime date) {
    // Định dạng YYYY-MM-DD
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
}