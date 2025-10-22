<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Mood;
use App\Models\Suggestion;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class MoodController extends Controller
{
    /**
     * Lấy danh sách moods (có thể lọc theo ngày)
     */
    public function index(Request $request)
    {
        $query = Mood::where('user_id', Auth::id());

        // Nếu có tham số date thì lọc theo ngày (dạng Y-m-d)
        if ($request->has('date')) {
            try {
                $query->whereDate('date', Carbon::parse($request->date));
            } catch (\Exception $e) {
                return response()->json(['error' => 'Ngày không hợp lệ: ' . $request->date], 400);
            }
        }

        $moods = $query->orderBy('date', 'desc')->get();

        return response()->json([
            'user_id'       => Auth::id(),
            'requested_date'=> $request->date ?? null,
            'data'          => $moods
        ]);
    }

    /**
     * Lưu mood mới + gọi AI gợi ý
     */
    public function store(Request $request)
    {
        $date = $request->input('date') ? Carbon::parse($request->input('date')) : now();

        $mood = Mood::create([
            'user_id' => Auth::id(),
            'emotion' => $request->emotion,
            'tag'     => $request->tag,
            'note'    => $request->note,
            'date'    => $date,
        ]);

        // 🔹 Chỉnh chỗ này: gọi AI bằng service container thay vì new
        $ai = app(\App\Http\Controllers\Api\AIController::class);
        $aiSuggestion = $ai->generateSuggestion(
            $request->emotion,
            $request->tag,
            $request->note
        )?? 'Chưa có gợi ý, vui lòng thử lại sau.';

        $badgeController = app(\App\Http\Controllers\Api\BadgeController::class);
        $badgeResponse = $badgeController->checkBadges($request);
        $badgeData = json_decode($badgeResponse->getContent(), true);

        // 👇 Lấy huy hiệu mới nếu có
        $newBadge = $badgeData['new_badge'] ?? null;

        app(\App\Http\Controllers\Api\BadgeController::class)->checkBadges($request);

        return response()->json([
            'data'       => $mood,
            'suggestion' => $aiSuggestion,
            'new_badge'  => $newBadge,
        ]);
    }


    /**
     * Cập nhật mood
     */
    public function update(Request $request, $id)
    {
        $mood = Mood::where('user_id', Auth::id())->findOrFail($id);
        $mood->update($request->only(['emotion', 'tag', 'note']));

        return response()->json(['data' => $mood]);
    }

    /**
     * Xóa mood
     */
    public function destroy($id)
    {
        Mood::where('user_id', Auth::id())->findOrFail($id)->delete();

        return response()->json(['message' => 'Xóa mood thành công']);
    }

    /**
     * Lấy gợi ý theo emotion 
     */
    public function getSuggestion($emotion)
    {
        $suggestion = Suggestion::where('mood_type', $emotion)
            ->inRandomOrder()
            ->first();

        if (!$suggestion) {
            return response()->json(['message' => 'Chưa có gợi ý cho mood này']);
        }

        return response()->json(['suggestion' => $suggestion->content]);
    }
}