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
        
        // 1. Kiểm tra Thu hồi Streak
        $streakRevoked = $this->checkStreakRevocation($user);
        if (!empty($streakRevoked)) {
            $revokedNames = array_merge($revokedNames, $streakRevoked);
        }

        // 2. Kiểm tra Thu hồi Tỷ lệ/Điều kiện khác
        $conditionRevoked = $this->checkConditionRevocation($user);
        if (!empty($conditionRevoked)) {
            $revokedNames = array_merge($revokedNames, $conditionRevoked);
        }

        return array_unique($revokedNames);
    }

    // Kiểm tra và lấy danh sách tên huy hiệu STREAK cần thu hồi
    private function checkStreakRevocation($user)
    {
        // Tính toán Streak hiện tại
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
            // Lấy yêu cầu streak từ tên (ví dụ: 'Thử Thách 3 Ngày 🥉' -> 3)
            $requiredStreak = (int) filter_var($badge->badge_name, FILTER_SANITIZE_NUMBER_INT);
            //Nếu người dùng có huy hiệu 7 ngày (requiredStreak = 7) và $currentStreak = 3, huy hiệu sẽ bị thu hồi. Nếu người dùng có huy hiệu 3 ngày (requiredStreak = 3) và $currentStreak = 3, huy hiệu sẽ được giữ lại.
            if ($currentStreak < $requiredStreak) {
                $revokedNames[] = $badge->badge_name;
            }
        }
        
        return $revokedNames;
    }

    //Kiểm tra và lấy danh sách tên huy hiệu CONDITION cần thu hồi
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

    //Chỉ đánh dấu tên huy hiệu cần bị thu hồi nếu người dùng đang sở hữu
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
        // TICH_CUC_CHINH (Trên 60% tổng thể)
        if ($ratio >= 0.6) $newBadge = $this->awardBadge($user, self::BADGES['TICH_CUC_CHINH']);
        // TICH_CUC_DE (7 ngày gần nhất)
        $recent7 = $moods->where('created_at', '>=', Carbon::now()->subDays(7));
        if ($recent7->count() >= 5) {
            $ratio7 = $recent7->filter(fn($m) => in_array(strtolower($m->emotion ?? ''), $positive))->count() / $recent7->count();
            if ($ratio7 >= 0.7) $newBadge = $this->awardBadge($user, self::BADGES['TICH_CUC_DE']);
        }
        // TICH_CUC_KHO (30 ngày gần nhất)
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
        
        // Nếu log gần nhất không phải hôm nay và không phải hôm qua, streak là 0
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

        //Tìm kiếm huy hiệu hiện có
        $existingBadge = Badge::where('user_id', $user->id)
            ->where('badge_name', $badge['name'])
            ->first();

        //Nếu hh đã tồn tại
        if ($existingBadge) {
            if ($badge['type'] === 'permanent') {
                return null; // Giữ nguyên ngày đạt được ban đầu
            }
            
            if (!Carbon::parse($existingBadge->earned_date)->isToday()) {
                $existingBadge->update(['earned_date' => Carbon::now()]);
            }
            
            // Trả null vì KHÔNG phải huy hiệu mới
            return null; 
        }

        // Nếu huy hiệu CHƯA tồn tại, tiến hành cấp mới
        $aiQuote = $this->generateAIQuote($badge['name'], $badge['description']);

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
            $prompt = "Người dùng vừa đạt huy hiệu '{$badgeName}' với thành tích '{$description}'.
            Viết một câu không quá dài truyền sự cảm hứng và tích cực, có thể dùng emotion hoặc câu thơ đoạn văn hay vào.
            Mỗi lần hãy viết một cách diễn đạt khác một chút để tạo cảm giác tự nhiên. Không sử dụng dấu ngoặc kép.";

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