// File: widgets/phantich_chuyendoimood.dart

import 'package:flutter/material.dart';

// Widget mới để hiển thị toàn bộ phần phân tích chuyển đổi và lời khuyên
class ChuyenDoiMood extends StatelessWidget {
  final int negToPosCount;
  final int posToNegCount;
  final int totalDaysRecorded; // Cần thêm tham số này để đưa ra lời khuyên chính xác

  const ChuyenDoiMood({
    super.key,
    required this.negToPosCount,
    required this.posToNegCount,
    required this.totalDaysRecorded,
  });

  // HÀM TẠO CÂU GỢI Ý (PROMPT) DỰA TRÊN KẾT QUẢ CHUYỂN ĐỔI
  String _getAdvicePrompt() {
    // Trường hợp không có đủ dữ liệu để phân tích chuyển đổi
    if (totalDaysRecorded < 2) {
      return "Hãy ghi lại nhật ký nhiều hơn để chúng tôi có thể phân tích chuyển đổi tâm trạng của bạn!";
    }

    // A. Tâm trạng không ổn định (Biến động mạnh)
    if (posToNegCount > 4 && negToPosCount > 4) {
      return "⚠️ Tâm trạng tháng này có vẻ rất biến động. Bạn liên tục chuyển đổi giữa hai thái cực. Hãy tìm cách giữ nhịp sống ổn định hơn và tránh các yếu tố gây căng thẳng đột ngột.";
    }

    // B. Xuống dốc nhiều hơn Cải thiện (Cần chú ý)
    if (posToNegCount > negToPosCount + 2) { // Xuống dốc nhiều hơn Cải thiện từ 3 lần trở lên
      return "🚨 Thống kê cho thấy số lần tâm trạng bạn 'xuống dốc' (Tích cực → Tiêu cực) cao hơn. Hãy dành thời gian nghỉ ngơi, chăm sóc bản thân và tìm kiếm nguyên nhân gây ra sự sụt giảm tinh thần này.";
    }

    // C. Cải thiện nhiều hơn Xuống dốc (Rất tích cực)
    if (negToPosCount > posToNegCount + 2) { // Cải thiện nhiều hơn Xuống dốc từ 3 lần trở lên
      return "🌟 Chúc mừng! Số lần bạn 'cải thiện' tâm trạng (Tiêu cực → Tích cực) vượt trội. Điều này thể hiện khả năng phục hồi và sức mạnh tinh thần tuyệt vời của bạn!";
    }

    // D. Ổn định và Tích cực (Xuống dốc và Cải thiện đều thấp: 0-2 lần)
    if (posToNegCount <= 2 && negToPosCount <= 2) {
      return "Ổn định là chìa khóa! Tâm trạng bạn rất ít thay đổi giữa hai nhóm, cho thấy bạn đang kiểm soát cảm xúc rất tốt. Tiếp tục duy trì phong độ này nhé!";
    }

    // E. Cân bằng hoặc biến động nhẹ
    return "Tâm trạng bạn đang ở mức khá cân bằng hoặc có sự biến động nhẹ. Hãy cố gắng phát huy những ngày tích cực và học hỏi từ những ngày cần được chăm sóc hơn.";
  }

  // HÀM XÂY DỰNG ITEM CHUYỂN ĐỔI
  Widget _buildTransitionItem(
      String title, int count, Color color, String icon) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 5),
            Text(
              "$count lần",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 5, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink.withOpacity(0.3)),
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
            "📊 Phân tích chuyển đổi tâm trạng",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 114, 53, 102)),
          ),
          const SizedBox(height: 15),

          // Hiển thị số lần chuyển đổi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTransitionItem(
                  "Tiêu cực -> Tích cực", negToPosCount, Colors.green.shade600, "⬆️"),
              _buildTransitionItem(
                  "Tích cực -> Tiêu cực", posToNegCount, Colors.red.shade600, "⬇️"),
            ],
          ),

          const Divider(height: 30, thickness: 1, indent: 20, endIndent: 20),

          // Lời khuyên
          Text(
            "Lời khuyên cho tháng này:",
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),

          Text(
            _getAdvicePrompt(), // GỌI HÀM LẤY LỜI KHUYÊN
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
                height: 1.4),
          ),
        ],
      ),
    );
  }
}