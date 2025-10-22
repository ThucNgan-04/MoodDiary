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
        'KIEN_TRI_3' => ['name' => 'Thử Thách 3 Ngày 🥉', 'description' => 'Hoàn thành 3 ngày liên tiếp ghi nhật ký.'],
        'KIEN_TRI_7' => ['name' => 'Người Kiên Trì 7 Ngày 💪', 'description' => 'Viết nhật ký cảm xúc 7 ngày liên tiếp.'],
        'KIEN_TRI_30' => ['name' => 'Nhà Cảm Xúc Bền Bỉ 🌟', 'description' => 'Viết nhật ký cảm xúc 30 ngày liên tiếp.'],

        'TICH_CUC_DE' => ['name' => 'Tia Nắng Sớm ☀️', 'description' => 'Đạt 70% log tích cực trong 7 ngày gần nhất.'],
        'TICH_CUC_KHO' => ['name' => 'Tinh Thần Lạc Quan ✨', 'description' => 'Duy trì tỷ lệ 80% log tích cực trong 30 ngày.'],
        'TICH_CUC_CHINH' => ['name' => 'Tâm hồn tích cực 🌈', 'description' => 'Chia sẻ cảm xúc tích cực thường xuyên (trên 60% tổng thể).'],

        'COT_MOC_10' => ['name' => 'Người Ghi Chép Tập Sự', 'description' => 'Hoàn thành 10 lần ghi nhật ký đầu tiên.'],
        'COT_MOC_100' => ['name' => 'Nhà Sử Học Cảm Xúc', 'description' => 'Hoàn thành 100 lần ghi nhật ký.'],
        'VUOT_KHO_5' => ['name' => 'Bậc Thầy Vượt Khó 🏆', 'description' => 'Ghi nhận được sự cải thiện sau giai đoạn cảm xúc tiêu cực kéo dài.'],

        'NHAT_KY_CHAM_CHI' => [
            'name' => 'Nhật Ký Chăm Chỉ ✍️',
            'description' => 'Ghi lại 3 cảm xúc trong cùng một ngày.',
        ],
    ];

    public function checkBadges(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        // Kiểm tra huy hiệu streak mất hiệu lực
        $revoked = $this->revokeStreakBadges($user);
        // Kiểm tra huy hiệu mới
        $newBadge = $this->checkAllBadgeConditions($user);

        $badges = Badge::where('user_id', $user->id)
            ->orderBy('earned_date', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'has_new_badge' => $newBadge ? true : false,
            'new_badge' => $newBadge,
            'revoked_badge' => $revoked,
            'badges' => $badges,
        ]);
    }

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
        if ($ratio >= 0.6) $newBadge = $this->awardBadge($user, self::BADGES['TICH_CUC_CHINH']);

        // 7 ngày gần nhất
        $recent7 = $moods->where('created_at', '>=', Carbon::now()->subDays(7));
        if ($recent7->count() >= 5) {
            $ratio7 = $recent7->filter(fn($m) => in_array(strtolower($m->emotion ?? ''), $positive))->count() / $recent7->count();
            if ($ratio7 >= 0.7) $newBadge = $this->awardBadge($user, self::BADGES['TICH_CUC_DE']);
        }

        // 30 ngày gần nhất
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
        for ($i = 1; $i < count($dates); $i++) {
            if ($dates[$i - 1]->diffInDays($dates[$i]) == 1) $streak++;
            else break;
        }
        return $streak;
    }

    private function revokeStreakBadges($user)
    {
        $yesterday = Carbon::yesterday()->toDateString();
        $hasLog = Mood::where('user_id', $user->id)
            ->whereDate('date', $yesterday)
            ->exists();

        if ($hasLog) return null;

        $revoked = Badge::where('user_id', $user->id)
            ->whereIn('badge_name', [
                self::BADGES['KIEN_TRI_3']['name'],
                self::BADGES['KIEN_TRI_7']['name'],
                self::BADGES['KIEN_TRI_30']['name']
            ])
            ->get();

        foreach ($revoked as $badge) $badge->delete();

        return $revoked->pluck('badge_name')->toArray();
    }

    // Trao huy hiệu và sinh quote từ AI
    private function awardBadge($user, $badge)
    {
        $exists = Badge::where('user_id', $user->id)
            ->where('badge_name', $badge['name'])
            ->exists();

        if ($exists) return null;

        $aiQuote = $this->generateAIQuote($badge['name'], $badge['description']);

        $new = Badge::create([
            'user_id' => $user->id,
            'badge_name' => $badge['name'],
            'description' => $badge['description'],
            'ai_quote' => $aiQuote,
            'earned_date' => Carbon::now(),
        ]);

        return $new->toArray();
    }

    //Sinh AI quote từ Gemini (có fallback)
    private function generateAIQuote($badgeName, $description)
    {
        $apiKey = config('services.gemini.api_key');
        $fallback = 'Một cột mốc cảm xúc đáng nhớ! 🌈';

        if (!$apiKey) return $fallback;

        try {
            $prompt = "Người dùng vừa đạt huy hiệu '{$badgeName}' với thành tích '{$description}'. 
            Viết một câu nói truyền cảm hứng và tích cực, có thể dùng emotion hoặc câu thơ văn Việt Nam vào. 
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