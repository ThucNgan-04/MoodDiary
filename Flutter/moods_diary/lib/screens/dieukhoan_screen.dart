import 'package:flutter/material.dart';
import 'package:moods_diary/widgets/auto_text.dart';

class DieukhoanScreen extends StatelessWidget {
  final String title;
  final String contentKey; //để xác định nội dung cần hiển thị
  
  const DieukhoanScreen({
    super.key,
    required this.title,
    required this.contentKey,
  });

String _getContent(String key) {
  if (key == 'dieukhoan') {
    return """
  ♦♦ Điều khoản và Dịch vụ của MOODDIARY ♦♦
  (Cập nhật gần nhất: 01/10/2025)

  Chào mừng bạn đến với MOODDIARY, được cung cấp bởi Nhóm 3 - MOODDIARY. Bằng việc cài đặt hoặc sử dụng Ứng dụng này, bạn đồng ý tuân thủ các Điều khoản và Dịch vụ sau:

  1. Chấp nhận Điều khoản
  Bằng cách truy cập hoặc sử dụng Ứng dụng, bạn xác nhận đã đọc, hiểu và đồng ý bị ràng buộc bởi các Điều khoản này.

  2. Dịch vụ được Cung cấp
  MOODDIARY là ứng dụng nhật ký số giúp người dùng ghi lại, theo dõi và phân tích cảm xúc cá nhân.
  - Mục đích: Ứng dụng chỉ dùng cho mục đích theo dõi cảm xúc cá nhân và không phải là công cụ thay thế cho lời khuyên chuyên môn về sức khỏe tinh thần.
  - Tính chính xác: Nhóm 3 - MOODDIARY không đảm bảo tính chính xác hoặc hữu ích của bất kỳ phân tích nào được tạo ra.

  3. Quyền Sở hữu và Quyền Sử dụng
  - Quyền của bạn đối với Dữ liệu: Bạn hoàn toàn sở hữu và kiểm soát các mục nhật ký bạn nhập vào Ứng dụng.
  - Quyền của chúng tôi: Nhóm sở hữu tất cả các quyền sở hữu trí tuệ đối với Ứng dụng, logo (MOODDIARY) và mã nguồn. Bạn được cấp quyền sử dụng Ứng dụng cho mục đích cá nhân, phi thương mại.

  4. Hành vi bị Cấm
  - Bạn đồng ý không sử dụng Ứng dụng để đăng tải nội dung bất hợp pháp, sao chép hoặc bán lại Ứng dụng, hoặc cố gắng truy cập trái phép vào hệ thống.
  """;
    } else if (key == 'chinhsach') {
      return """
  ♥♥ Chính sách Bảo mật của MOODDIARY: Nhật ký cảm xúc ♥♥
  (Cập nhật gần nhất: 01/10/2025)

  Nhóm 3 cam kết bảo vệ quyền riêng tư của bạn.

  1. Nguyên tắc cốt lõi về Dữ liệu
  - Quyền riêng tư của bạn là ưu tiên hàng đầu.
  -  Nội dung nhật ký và cảm xúc của bạn được mã hóa và không được chia sẻ với bất kỳ bên thứ ba nào vì mục đích quảng cáo hoặc tiếp thị.

  2. Thông tin chúng tôi Thu thập
  - Dữ liệu do Người dùng cung cấp: Tên người dùng (tùy chọn), các mục nhật ký, cảm xúc đã chọn, đánh giá tâm trạng.
  - Dữ liệu Kỹ thuật và Phi cá nhân: Thông tin về thiết bị (loại điện thoại), ngôn ngữ đã chọn, và dữ liệu sử dụng ứng dụng ẩn danh.

  3. Cách chúng tôi Sử dụng Thông tin
  - Chúng tôi chỉ sử dụng thông tin của bạn để cung cấp dịch vụ cốt lõi (lưu trữ nhật ký), tạo các báo cáo tâm trạng cá nhân hóa, và cải tiến ứng dụng.

  4. Lưu trữ và Bảo vệ Dữ liệu
  - Tất cả dữ liệu nhật ký và cảm xúc nhạy cảm được mã hóa cả khi truyền tải và khi lưu trữ trên máy chủ (nếu có tính năng đồng bộ).

  5. Chia sẻ Thông tin với Bên thứ ba
  Chúng tôi sẽ **KHÔNG** chia sẻ dữ liệu nhật ký cá nhân của bạn với bất kỳ bên thứ ba nào, trừ khi bạn tự nguyện chọn chia sẻ hoặc có yêu cầu pháp lý hợp lệ.
  """;
    }
    return "Nội dung không có sẵn.";
  }

  @override
  Widget build(BuildContext context) {
    final detailContent = _getContent(contentKey);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        // Thêm nút Back tự động
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutoText(
              detailContent,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}