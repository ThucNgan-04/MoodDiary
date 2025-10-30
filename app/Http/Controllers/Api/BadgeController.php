<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use App\Models\Mood;
use App\Models\Badge;

class BadgeController extends Controller
{
    // Toàn bộ danh sách huy hiệu
    const BADGES = [
        'KIEN_TRI_3' => ['name' => 'Thử Thách 3 Ngày 🥉', 'description' => 'Hoàn thành 3 ngày liên tiếp ghi nhật ký.', 'type' => 'streak', 'image_path' => '3day.png'],
        'KIEN_TRI_7' => ['name' => 'Người Kiên Trì 7 Ngày 💪', 'description' => 'Viết nhật ký cảm xúc 7 ngày liên tiếp.', 'type' => 'streak', 'image_path' => '7day.png'],
        'KIEN_TRI_30' => ['name' => 'Nhà Cảm Xúc Bền Bỉ 🌟', 'description' => 'Viết nhật ký cảm xúc 30 ngày liên tiếp.', 'type' => 'streak', 'image_path' => '30day.png'],

        'TICH_CUC_DE' => ['name' => 'Tia Nắng Sớm ☀️', 'description' => 'Đạt 70% log tích cực trong 7 ngày gần nhất.', 'type' => 'condition', 'image_path' => 'sun.png'],
        'TICH_CUC_KHO' => ['name' => 'Tinh Thần Lạc Quan ✨', 'description' => 'Duy trì tỷ lệ 80% log tích cực trong 30 ngày.', 'type' => 'condition', 'image_path' => 'lacquan30.png'],
        'TICH_CUC_CHINH' => ['name' => 'Tâm hồn tích cực 🌈', 'description' => 'Chia sẻ cảm xúc tích cực thường xuyên (trên 60% tổng thể).', 'type' => 'condition', 'image_path' => 'tichcuc60%.png'],

        'COT_MOC_10' => ['name' => 'Người Ghi Chép Tập Sự', 'description' => 'Hoàn thành 10 lần ghi nhật ký đầu tiên', 'type' => 'permanent', 'image_path' => 'vuotkho.png'],
        'COT_MOC_100' => ['name' => 'Nhà Sử Học Cảm Xúc', 'description' => 'Hoàn thành 100 lần ghi nhật ký.', 'type' => 'permanent', 'image_path' => 'moc100.png'],
        'VUOT_KHO_5' => ['name' => 'Bậc Thầy Vượt Khó 🏆', 'description' => 'Ghi nhận được sự cải thiện sau giai đoạn cảm xúc tiêu cực kéo dài.', 'type' => 'permanent', 'image_path' => 'vuotkho.png'],

        'NHAT_KY_CHAM_CHI' => ['name' => 'Nhật Ký Chăm Chỉ ✍️', 'description' => 'Ghi lại 3 cảm xúc trong cùng một ngày.','type' => 'permanent', 'image_path' => 'chamchi.png'],
    ];

    //ktra cấp và thu hồi hh
    public function checkBadges(Request $request)
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }
        $newBadge = $this->checkAllBadgeConditions($user);
        // Lấy ds hh cần bị thu hồi
        $revokedBadgeNames = $this->getRevokedBadgeNames($user);
        
        $userBadges = $user->badges()->get(); 
        
        $finalBadges = $userBadges->filter(function($badge) use ($revokedBadgeNames) {
            // Chỉ giữ lại những huy hiệu KHÔNG bị thu hồi
            return !in_array($badge->badge_name, $revokedBadgeNames);
        })->values()->map(function($badge) {

            $badgeInfo = collect(self::BADGES)->first(function ($info) use ($badge) {
                return $info['name'] === $badge->badge_name;
            });
            // Tạo URL mạng
            $imagePath = $badgeInfo['image_path'] ?? 'default.png';
            $imageUrl = asset('images/badges/' . $imagePath);

             return [
                 'badge_name' => $badge->badge_name,
                 'description' => $badge->description,
                 'ai_quote' => $badge->ai_quote,
                 'earned_date' => $badge->earned_date,
                 'image_url' => $imageUrl,
             ];
        })->toArray();
        
        return response()->json([
            'badges' => $finalBadges, // Danh sách huy hiệu ĐÃ LỌC
            'new_badge' => $newBadge, // Thông tin huy hiệu mới (nếu có)
            'revoked_badge_names' => $revokedBadgeNames // Danh sách tên huy hiệu cần thông báo thu hồi
        ]);
    }

    //API: Xóa huy hiệu khỏi DB sau khi Flutter thông báo cho người dùng
    public function revokeBadge(Request $request)
    {
        $user = $request->user();
        $badgeName = $request->input('badge_name');

        if (!$user || !$badgeName) {
            return response()->json(['success' => false, 'message' => 'Invalid request'], 400);
        }

        $badge = Badge::where('user_id', $user->id)
            ->where('badge_name', $badgeName)
            ->first();

        if ($badge) {
            $badge->delete();
            return response()->json(['success' => true, 'message' => "Huy hiệu '{$badgeName}' đã được thu hồi."], 200);
        }

        return response()->json(['success' => false, 'message' => "Huy hiệu '{$badgeName}' không tồn tại."], 404);
    }
    
    //API lấy huy hiệu user hiện tại
    public function me(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Token không hợp lệ'], 401);
        }

        $badges = Badge::where('user_id', $user->id)
            ->orderBy('earned_date', 'desc')
            ->get();

        return response()->json(['success' => true, 'badges' => $badges]);
    }

    //Lấy danh sách tên huy hiệu cần bị thu hồi
    private function getRevokedBadgeNames($user)
    {
        $revokedNames = [];
        
        //Kiểm tra Thu hồi Streak
        $streakRevoked = $this->checkStreakRevocation($user);
        if (!empty($streakRevoked)) {
            $revokedNames = array_merge($revokedNames, $streakRevoked);
        }

        $conditionRevoked = $this->checkConditionRevocation($user);
        if (!empty($conditionRevoked)) {
            $revokedNames = array_merge($revokedNames, $conditionRevoked);
        }

        return array_unique($revokedNames);
    }

    private function checkStreakRevocation($user)
    {
        $currentStreak = $this->getStreak($user); 
        $revokedNames = [];

        // Lấy danh sách tên huy hiệu Streak cần kiểm tra
        $streakBadgeNames = [
            self::BADGES['KIEN_TRI_3']['name'],
            self::BADGES['KIEN_TRI_7']['name'],
            self::BADGES['KIEN_TRI_30']['name'],
        ];

        // Lấy tất cả huy hiệu streak mà người dùng đang có
        $userStreakBadges = Badge::where('user_id', $user->id)
            ->whereIn('badge_name', $streakBadgeNames)
            ->get();
            
        foreach ($userStreakBadges as $badge) {
            $requiredStreak = (int) filter_var($badge->badge_name, FILTER_SANITIZE_NUMBER_INT);
            if ($currentStreak < $requiredStreak) {
                $revokedNames[] = $badge->badge_name;
            }
        }
        
        return $revokedNames;
    }

    private function checkConditionRevocation($user)
    {
        $revokedNames = [];
        $moods = Mood::where('user_id', $user->id)->get();
        $totalLogs = $moods->count();
        if ($totalLogs == 0) return [];

        $positive = ['vui', 'hạnh phúc', 'tích cực', 'rất tích cực', 'đang yêu', 'happy'];
        $positiveCount = $moods->filter(fn($m) => in_array(strtolower($m->emotion ?? ''), $positive))->count();
        $ratio = $totalLogs ? $positiveCount / $totalLogs : 0;

        // TICH_CUC_CHINH (Tỷ lệ tổng thể < 60%)
        if ($ratio < 0.6) {
            $this->markBadgeForRevocation($user, self::BADGES['TICH_CUC_CHINH']['name'], $revokedNames);
        }

        // TICH_CUC_DE (7 ngày gần nhất < 70%)
        $recent7 = $moods->where('created_at', '>=', Carbon::now()->subDays(7));
        if ($recent7->count() >= 5) {
            $ratio7 = $recent7->filter(fn($m) => in_array(strtolower($m->emotion ?? ''), $positive))->count() / $recent7->count();
            if ($ratio7 < 0.7) {
                $this->markBadgeForRevocation($user, self::BADGES['TICH_CUC_DE']['name'], $revokedNames);
            }
        }

        // TICH_CUC_KHO (30 ngày gần nhất < 80%)
        $recent30 = $moods->where('created_at', '>=', Carbon::now()->subDays(30));
        if ($recent30->count() >= 10) {
            $ratio30 = $recent30->filter(fn($m) => in_array(strtolower($m->emotion ?? ''), $positive))->count() / $recent30->count();
            if ($ratio30 < 0.8) {
                $this->markBadgeForRevocation($user, self::BADGES['TICH_CUC_KHO']['name'], $revokedNames);
            }
        }

        return $revokedNames;
    }

    private function markBadgeForRevocation($user, $badgeName, &$revokedNames)
    {
        $exists = Badge::where('user_id', $user->id)
            ->where('badge_name', $badgeName)
            ->exists();

        if ($exists) {
            $revokedNames[] = $badgeName;
        }
    }

    //Kiểm tra tất cả điều kiện và cấp huy hiệu
    private function checkAllBadgeConditions($user)
    {
        $newBadge = null;
        $moods = Mood::where('user_id', $user->id)->get();
        $totalLogs = $moods->count();
        if ($totalLogs == 0) return null;

        // Kiểm tra streak
        $streak = $this->getStreak($user);
        if ($streak >= 3) $newBadge = $this->awardBadge($user, self::BADGES['KIEN_TRI_3']);
        if ($streak >= 7) $newBadge = $this->awardBadge($user, self::BADGES['KIEN_TRI_7']);
        if ($streak >= 30) $newBadge = $this->awardBadge($user, self::BADGES['KIEN_TRI_30']);

        // Cột mốc tổng log
        if ($totalLogs >= 10) $newBadge = $this->awardBadge($user, self::BADGES['COT_MOC_10']);
        if ($totalLogs >= 100) $newBadge = $this->awardBadge($user, self::BADGES['COT_MOC_100']);

        // Viết 3 cảm xúc trong cùng 1 ngày
        $logsByDay = $moods->groupBy(fn($m) => Carbon::parse($m->date ?? $m->created_at)->toDateString());
        foreach ($logsByDay as $day => $logs) {
            if ($logs->count() >= 3) {
                $newBadge = $this->awardBadge($user, self::BADGES['NHAT_KY_CHAM_CHI']);
                break;
            }
        }
        // Tích cực
        $positive = ['vui', 'hạnh phúc', 'tích cực', 'rất tích cực', 'đang yêu', 'happy'];
        $positiveCount = $moods->filter(fn($m) => in_array(strtolower($m->emotion ?? ''), $positive))->count();
        $ratio = $totalLogs ? $positiveCount / $totalLogs : 0;
        // (Trên 60% tổng thể)
        if ($ratio >= 0.6) $newBadge = $this->awardBadge($user, self::BADGES['TICH_CUC_CHINH']);
        // (7 ngày gần nhất)
        $recent7 = $moods->where('created_at', '>=', Carbon::now()->subDays(7));
        if ($recent7->count() >= 5) {
            $ratio7 = $recent7->filter(fn($m) => in_array(strtolower($m->emotion ?? ''), $positive))->count() / $recent7->count();
            if ($ratio7 >= 0.7) $newBadge = $this->awardBadge($user, self::BADGES['TICH_CUC_DE']);
        }
        // (30 ngày gần nhất)
        $recent30 = $moods->where('created_at', '>=', Carbon::now()->subDays(30));
        if ($recent30->count() >= 10) {
            $ratio30 = $recent30->filter(fn($m) => in_array(strtolower($m->emotion ?? ''), $positive))->count() / $recent30->count();
            if ($ratio30 >= 0.8) $newBadge = $this->awardBadge($user, self::BADGES['TICH_CUC_KHO']);
        }
        //Vượt khó
        $badLevels = ['rất tệ', 'tồi tệ', 'buồn bã'];
        $history = $moods->pluck('emotion')->map(fn($e) => strtolower($e ?? ''));
        $badStreak = 0; $overcome = false;
        
        foreach ($history as $e) {
            if (in_array($e, $badLevels)) $badStreak++;
            else $badStreak = 0;
            if ($badStreak >= 5) $overcome = true; 
        }
        if ($overcome && $positiveCount >= 10)
            $newBadge = $this->awardBadge($user, self::BADGES['VUOT_KHO_5']);
        return $newBadge;
    }

    //Tính toán Streak
    private function getStreak($user)
    {
        $dates = Mood::where('user_id', $user->id)
            ->orderBy('date', 'desc')
            ->pluck('date')
            ->filter()
            ->map(fn($d) => Carbon::parse($d)->startOfDay())
            ->unique()
            ->values();

        if ($dates->isEmpty()) return 0;

        $streak = 1;
        
        $latestLogDate = $dates->first();
        $today = Carbon::now('Asia/Ho_Chi_Minh')->startOfDay();
        $yesterday = Carbon::yesterday('Asia/Ho_Chi_Minh')->startOfDay();
        
        if (!$latestLogDate->equalTo($today) && !$latestLogDate->equalTo($yesterday)) {
            return 0;
        }

        for ($i = 1; $i < count($dates); $i++) {
            if ($dates[$i - 1]->diffInDays($dates[$i]) == 1) {
                $streak++;
            } else {
                break; // Đứt chuỗi
            }
        }
        return $streak;
    }

    //Trao huy hiệu & AI
    private function awardBadge($user, $badge)
    {
        $imagePath = $badge['image_path'] ?? 'default.png';
        $imageUrl = asset('images/badges/' . $imagePath);

        $existingBadge = Badge::where('user_id', $user->id)//Tìm kiếm huy hiệu hiện có
            ->where('badge_name', $badge['name'])
            ->first();

        if ($existingBadge) {
            if ($badge['type'] === 'permanent') {
                return null; // Giữ nguyên ngày đạt được ban đầu
            }
            
            if (!Carbon::parse($existingBadge->earned_date)->isToday()) {
                $existingBadge->update(['earned_date' => Carbon::now()]);
            }
            return null; //trả null vì ko phải hh ms
        }

        $aiQuote = $this->generateAIQuote($badge['name'], $badge['description']);//cấp mới nếu chưa tồn tại hh

        $new = Badge::create([
            'user_id' => $user->id,
            'badge_name' => $badge['name'],
            'description' => $badge['description'],
            'ai_quote' => $aiQuote,
            'earned_date' => Carbon::now(),
            'image_url' => $imageUrl,
        ]);

        return $new->toArray();
    }

    private function generateAIQuote($badgeName, $description)
    {
        $apiKey = config('services.gemini.api_key');
        $fallback = 'Một cột mốc cảm xúc đáng nhớ! 🌈';

        if (!$apiKey) return $fallback;

        try {
            $prompt = "
                **Vai trò:** Bạn là chuyên gia truyền cảm hứng, chuyên tạo ra lời chúc mừng độc đáo.

                **Dữ liệu Huy hiệu:**
                - Tên huy hiệu: '{$badgeName}'
                - Thành tích: '{$description}'

                **Yêu cầu Đầu ra:**
                1.  Viết một lời chúc mừng ngắn gọn, truyền cảm hứng và cực kỳ tích cực, dựa trên '{$badgeName}' và '{$description}'.
                2.  **Bắt buộc** phải sử dụng một trong các yếu tố sau để làm câu văn nổi bật hơn: **Biểu tượng cảm xúc (emoji)**, **cách nói ví von sâu sắc**, hoặc **một câu thơ/thành ngữ ngắn** liên quan đến thành tích.
                3.  **Tính đa dạng:** Mỗi lần tạo ra câu nói, hãy thay đổi cách diễn đạt (cấu trúc câu, từ ngữ, kiểu emoji) để tránh lặp lại.
                4.  **Giới hạn:** Tuyệt đối chỉ viết **MỘT CÂU** duy nhất (không quá 15 từ) để giữ sự sắc sảo và tác động.
                5.  **Định dạng:** Không sử dụng dấu ngoặc kép. Chỉ trả về câu nói, không có lời chào hay bất kỳ văn bản giải thích nào khác.
            ";
            $response = Http::withHeaders(['Content-Type' => 'application/json'])
                ->post("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={$apiKey}", [
                    "contents" => [[
                        "role" => "user",
                        "parts" => [["text" => $prompt]]
                    ]],
                    "generationConfig" => [
                        "maxOutputTokens" => 50,
                        "temperature" => 0.8
                    ]
                ]);

            if ($response->successful()) {
                $data = $response->json();
                return trim($data['candidates'][0]['content']['parts'][0]['text'] ?? $fallback, "\"\n ");
            }
        } catch (\Throwable $e) {
            Log::error('AI Quote Error: ' . $e->getMessage());
        }

        return $fallback;
    }
}