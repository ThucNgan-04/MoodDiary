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
        Hãy gợi ý một lời khuyên ngắn gọn, dễ hiểu, tích cực (1-2 câu).";

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

            // Nếu AI không trả lời thì log lại để debug
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
        Nếu buồn/giận dữ chiếm nhiều, hãy khuyên cách cải thiện để tránh tiêu cực.
        Nếu vui/hạnh phúc chiếm nhiều, hãy khuyến khích họ giữ vững tinh thần.
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
}