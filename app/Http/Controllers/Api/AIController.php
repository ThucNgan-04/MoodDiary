<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\Request;

class AIController extends Controller
{
    public function generateSuggestion($mood, $tag, $note)
    {
        $apiKey = config('services.gemini.api_key');

        if (!$apiKey) {
            return "Chưa cấu hình GEMINI_API_KEY trong .env";
        }

        // Prompt tạo gợi ý
        $prompt = "Tôi đang cảm thấy '$mood' về '$tag'. Ghi chú: '$note'. 
        Hãy gợi ý một lời khuyên ngắn gọn, dễ hiểu, tích cực (1-2 câu). Là lời muốn gửi gắm của một người ấm áp!";

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
                    'suggestion' => 'AI đang tạm nghỉ để nạp năng lượng 😅. Hãy thử lại sau ít phút nhé!'
                ], 200);
            }

            if ($response->failed()) {
                Log::error('Gemini API error', [
                    'status' => $response->status(),
                    'body'   => $response->body()
                ]);
                return "Không thể kết nối AI ngay lúc này. Hãy thử lại sau.";
            }

            $result = $response->json();

            // Kiểm tra dữ liệu trả về trước khi lấy text
            $text = $result['candidates'][0]['content']['parts'][0]['text']
                ?? null;

            if ($text && trim($text) !== '') {
                return trim($text);
            }

            Log::warning('Gemini trả về rỗng', ['result' => $result]);

            return "AI không trả lời được. Debug: " . json_encode($result, JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            Log::error('AI Exception', [
                'message' => $e->getMessage()
            ]);
            return "Lỗi khi gọi AI: " . $e->getMessage();
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
        $prompt = "Bạn là chuyên gia phân tích tâm lý. 
        Đây là thống kê cảm xúc trong tháng của người dùng: " . json_encode($stats, JSON_UNESCAPED_UNICODE) . ".
        Hãy phân tích ngắn gọn (2-3 câu) về tình trạng cảm xúc của họ. 
        Nếu buồn/giận dữ chiếm nhiều thì bạn tính đại khái Phân tích người dùng có nguy cơ bị trầm cảm/ stress không, hãy khuyên cách cải thiện để tránh tiêu cực/stress.
        Nếu vui/hạnh phúc chiếm nhiều, hãy khuyến khích họ giữ vững tinh thần với giọng điệu cảm xúc này phấn chấn, vui vẻ dễ thương.
        Viết giọng thân thiện, dễ hiểu, như một người bạn quan tâm.";

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
        Phân tích sự dịch chuyển cảm xúc giữa Tuần trước ({$prevDateRange}) và Tuần này ({$currDateRange}).
        - Tuần A: Tích cực {$prevStats['pos']} ngày, Tiêu cực {$prevStats['neg']} ngày, Trung tính/Chưa ghi {$prevStats['neu']} ngày (Tổng {$prevTotal} ngày ghi).
        - Tuần B: Tích cực {$currStats['pos']} ngày, Tiêu cực {$currStats['neg']} ngày, Trung tính/Chưa ghi {$currStats['neu']} ngày (Tổng {$currTotal} ngày ghi).

        Là một chuyên gia tâm lý, hãy đưa ra một đoạn nhận xét chuyên sâu (khoảng 3-4 câu, không quá 50 từ):
        1. Nhận định xu hướng chung và sự dịch chuyển chính (Tích cực hay Tiêu cực đang chiếm ưu thế hơn và so với tuần trước).
        2. Đưa ra một lời khuyên hoặc gợi ý hành động cụ thể và tích cực cho người dùng.
        Tuyệt đối trả lời bằng tiếng Việt, không dùng dấu ngoặc kép. Chỉ trả về đoạn phân tích, không thêm lời chào, kết luận hay bất kỳ tiêu đề nào.
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