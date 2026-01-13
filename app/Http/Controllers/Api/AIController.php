<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AIController extends Controller
{
    public function generateSuggestion($mood, $tag, $note)
    {
        $apiKey = config('services.gemini.api_key');

        if (!$apiKey) {
            return response()->json([
                'success' => false,
                'suggestion' => "Lỗi cấu hình: Chưa cấu hình GEMINI_API_KEY trong .env"
            ], 500);
        }

        $prompt = "
            **Vai trò:** Bạn là một người bạn ấm áp, chuyên đưa ra lời động viên và gợi ý tích cực.
            **Dữ liệu Nhật ký:**
            - Cảm xúc chính: '$mood'
            - Chủ đề/Tag: '$tag'
            - Ghi chú: '$note'

            **Yêu cầu Đầu ra:**
            1.  Dựa trên cảm xúc và ghi chú, hãy đưa ra một lời khuyên hoặc lời động viên ngắn gọn, dễ hiểu, và tích cực.
            2.  Đảm bảo lời nhắn có tính cá nhân hóa (dùng các từ như 'bạn', 'chúng ta').
            3.  **Giới hạn:** Tuyệt đối chỉ viết **3 câu** hoặc **tối đa 4 câu rất ngắn** (không quá 50 từ).
            4.  **Giọng điệu:** Phải cực kỳ ấm áp, nhẹ nhàng, và chân thành.
            5.  **Định dạng:** Chỉ trả về đoạn văn bản (lời khuyên), không có lời chào hay bất kỳ tiêu đề nào.
        ";

        try {
            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
            ])->post(
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={$apiKey}",
                [
                    "contents" => [
                        [
                            "role" => "user",
                            "parts" => [
                                ["text" => $prompt]
                            ]
                        ]
                    ],
                    "generationConfig" => [
                        "maxOutputTokens" => 150, // Giới hạn vừa phải, tránh bị cắt ngang
                        "temperature" => 0.7
                    ]
                ]
            );

            if ($response->status() === 429) {
                return response()->json([
                    'success' => true,
                    'suggestion' => 'AI đang tạm nghỉ để nạp năng lượng 😅. Hãy thử lại sau ít phút nhé!'
                ], 200);
            }

            if ($response->failed()) {
                Log::error('Gemini API error', [
                    'status' => $response->status(),
                    'body'   => $response->body()
                ]);
                return response()->json([
                    'success' => false,
                    'suggestion' => "Không thể kết nối AI ngay lúc này. Hãy thử lại sau. (Status: {$response->status()})"
                ], 500);
            }

            $result = $response->json();

            // Kiểm tra dữ liệu trả về trước khi lấy text
            $text = $result['candidates'][0]['content']['parts'][0]['text']
                ?? null;

            if ($text && trim($text) !== '') {
                return response()->json([
                    'success' => true, // Báo thành công cho Flutter
                    'suggestion' => trim($text)
                ], 200);
            }

            Log::warning('Gemini trả về rỗng', ['result' => $result]);

            return response()->json([
                'success' => false,
                'suggestion' => "AI không trả lời được. Vui lòng thử lại." // Không cần debug chi tiết ra cho người dùng
            ], 200);

        } catch (\Exception $e) {
            Log::error('AI Exception', [
                'message' => $e->getMessage()
            ]);
            return response()->json([
                'success' => false,
                'suggestion' => "Lỗi khi gọi AI: " . $e->getMessage()
            ], 500);
        }
    }
    public function analyzeStats(Request $request)
    {
        $apiKey = config('services.gemini.api_key');
        if (!$apiKey) {
            return response()->json([
                'suggestion' => 'Chưa cấu hình GEMINI_API_KEY trong .env'
            ], 200);
        }

        $stats = $request->input('stats', []);

        if (!$stats || !is_array($stats) || empty($stats)) {
            return response()->json([
                'suggestion' => 'Chưa có dữ liệu để phân tích'
            ], 200);
        }

        // Tạo prompt cho Gemini
        $prompt = "
            Bạn là chuyên gia phân tích tâm lý.
            Đây là thống kê cảm xúc trong tháng của người dùng: " . json_encode($stats, JSON_UNESCAPED_UNICODE) . ".

            **QUAN TRỌNG:**
            1.  Trước tiên, bạn phải tính toán và đưa ra **phần trăm** của các nhóm cảm xúc chủ đạo (Tích cực: Vui/Hạnh phúc/Đang yêu và Tiêu cực: Buồn/Giận dữ) trong tháng.
            2.  Sau đó, hãy phân tích chuyên sâu về tình trạng cảm xúc của họ, bao gồm cả dữ liệu phần trăm đã tính.
            3.  **Phản hồi Tương ứng:**
                a.  Nếu nhóm Tiêu cực (Buồn/Giận) chiếm ưu thế: Nhận định nhẹ nhàng về nguy cơ stress/tiêu cực và khuyên 1 cách cải thiện cụ thể, tích cực.
                b.  Nếu nhóm Tích cực (Vui/Hạnh phúc) chiếm ưu thế: Khuyến khích họ giữ vững tinh thần với giọng điệu phấn chấn, vui vẻ, dễ thương.
            4.  **Giới hạn và Định dạng:**
                -   Viết thành một đoạn văn liền mạch, **khoảng 5-6 câu**, **không vượt quá 100 từ**.
                -   Giọng điệu phải thân thiện, dễ hiểu, như một người bạn quan tâm, **viết hết câu**.
                -   Chỉ trả về đoạn phân tích, KHÔNG có lời chào, tiêu đề hay bất kỳ dấu ngoặc kép nào.
        ";

        try {
            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
            ])->post(
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={$apiKey}",
                [
                    "contents" => [
                        [
                            "role" => "user",
                            "parts" => [
                                ["text" => $prompt]
                            ]
                        ]
                    ],
                    "generationConfig" => [
                        "maxOutputTokens" => 200,
                        "temperature" => 0.7
                    ]
                ]
            );

            if ($response->status() === 429) {
                return response()->json([
                    'suggestion' => 'AI đang tạm nghỉ để nạp năng lượng 😅. Hãy thử lại sau ít phút nhé!'
                ], 200);
            }

            if ($response->failed()) {
                return response()->json([
                    'suggestion' => 'Không thể kết nối AI ngay lúc này.'
                ], 200);
            }

            $result = $response->json();
            $text = $result['candidates'][0]['content']['parts'][0]['text'] ?? null;

            return response()->json([
                'suggestion' => $text ?: 'AI không trả lời được.'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'suggestion' => 'Lỗi khi gọi AI: ' . $e->getMessage()
            ], 200);
        }
    }
    
    public function analyzeWeeklyMoodShift(Request $request)
    {
        $apiKey = config('services.gemini.api_key');
        
        $currStats = $request->input('curr_stats');
        $prevStats = $request->input('prev_stats');
        $currDateRange = $request->input('curr_date_range');
        $prevDateRange = $request->input('prev_date_range');

        if (!$apiKey) {
            return response()->json(['analysis' => 'Chưa cấu hình GEMINI_API_KEY trong .env.'], 500);
        }

        if (!$currStats || !$prevStats || !$currDateRange || !$prevDateRange) {
            return response()->json(['analysis' => 'Thiếu dữ liệu thống kê tuần để phân tích.'], 400);
        }

        $currTotal = ($currStats['pos'] ?? 0) + ($currStats['neg'] ?? 0) + ($currStats['neu'] ?? 0);
        $prevTotal = ($prevStats['pos'] ?? 0) + ($prevStats['neg'] ?? 0) + ($prevStats['neu'] ?? 0);
        
        $prompt = "
            Bạn là chuyên gia tâm lý và phân tích dữ liệu cảm xúc.

            **Dữ liệu Phân tích Dịch chuyển Cảm xúc:**
            - Tuần trước ({$prevDateRange}): Tích cực {$prevStats['pos']} ngày, Tiêu cực {$prevStats['neg']} ngày, Trung tính/Chưa ghi {$prevStats['neu']} ngày (Tổng {$prevTotal} ngày ghi).
            - Tuần này ({$currDateRange}): Tích cực {$currStats['pos']} ngày, Tiêu cực {$currStats['neg']} ngày, Trung tính/Chưa ghi {$currStats['neu']} ngày (Tổng {$currTotal} ngày ghi).

            **Yêu cầu Phân tích Chuyên sâu:**
            Hãy phân tích sự dịch chuyển cảm xúc giữa hai tuần này và đưa ra một đoạn nhận xét chuyên sâu, sâu sắc (khoảng 5-6 câu, không quá 80 từ).
            1.  **Nhận định Xu hướng Chính:** Phân tích rõ ràng xu hướng chủ đạo (Tích cực hay Tiêu cực) đang chiếm ưu thế, và mức độ dịch chuyển/thay đổi so với tuần trước.
            2.  **Phân tích Nguyên nhân Tiềm ẩn:** Dựa trên sự thay đổi, nhận định ngắn gọn về nguyên nhân tiềm ẩn (ví dụ: đang cố gắng cải thiện, hay đang gặp áp lực).
            3.  **Khuyến nghị Chuyên môn:** Đưa ra một lời khuyên tâm lý chuyên nghiệp, thiết thực để duy trì hoặc cải thiện trạng thái cảm xúc.
            4.  **Kỳ vọng Tuần tiếp theo:** Đưa ra kỳ vọng có điều kiện về trạng thái cảm xúc tuần tiếp theo nếu xu hướng hiện tại tiếp tục.

            **Định dạng và Giọng điệu:**
            -   Sử dụng giọng điệu chuyên nghiệp, sâu sắc nhưng vẫn ấm áp.
            -   Tuyệt đối trả lời bằng tiếng Việt, viết thành một đoạn văn liền mạch, KHÔNG dùng dấu ngoặc kép.
            -   Chỉ trả về đoạn phân tích. KHÔNG thêm lời chào, kết luận hay bất kỳ tiêu đề nào.
        ";

        try {
            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
            ])->post(
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={$apiKey}",
                [
                    "contents" => [
                        [
                            "role" => "user",
                            "parts" => [
                                ["text" => $prompt]
                            ]
                        ]
                    ],
                    "generationConfig" => [
                        "maxOutputTokens" => 200, // Tăng token cho đoạn phân tích dài hơn 1 câu
                        "temperature" => 0.7,      // Giảm nhiệt độ một chút để phân tích khách quan hơn
                    ]
                ]
            );

            if ($response->status() === 429) {
                return response()->json([
                    'analysis' => 'AI đang tạm nghỉ để nạp năng lượng 😅. Hãy thử lại sau ít phút nhé!'
                ], 200);
            }

            if ($response->failed()) {
                Log::error('Gemini API error (Mood Shift Analysis)', [
                    'status' => $response->status(),
                    'body'   => $response->body()
                ]);
                return response()->json(['analysis' => 'Không thể tạo phân tích AI lúc này. Vui lòng thử lại sau.'], 500);
            }

            $result = $response->json();
            $text = $result['candidates'][0]['content']['parts'][0]['text'] ?? null;

            // Xử lý và làm sạch văn bản
            return response()->json([
                'analysis' => trim($text, "\"\n\r\t ") ?: 'Tâm hồn bạn mạnh mẽ hơn bạn nghĩ, hãy tiếp tục chăm sóc nó!'
            ], 200);

        } catch (\Exception $e) {
            Log::error('AI Exception (Mood Shift Analysis)', [
                'message' => $e->getMessage()
            ]);
            return response()->json(['analysis' => 'Lỗi khi gọi AI: ' . $e->getMessage()], 500);
        }
    }
}