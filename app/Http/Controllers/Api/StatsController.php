<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Mood;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class StatsController  extends Controller
{
    //Biểu đồ tròn
    public function monthly($year, $month)
    {
        $userId = Auth::id();
        $start = Carbon::create($year, $month, 1)->startOfMonth();
        $end   = Carbon::create($year, $month, 1)->endOfMonth();

        $stats = Mood::where('user_id', $userId)
            ->whereBetween('date', [$start, $end])
            ->selectRaw('emotion, COUNT(*) as count')
            ->groupBy('emotion')
            ->get();

        return response()->json([
            'year' => $year,
            'month' => $month,
            'stats' => $stats
        ]);
    }
    //Cảm xúc theo ngày - đường, tính top emotion
    public function dailyTrend($year, $month)
    {
        $userId = Auth::id();
        $start = Carbon::create($year, $month, 1)->startOfMonth();
        $end   = Carbon::create($year, $month, 1)->endOfMonth();

        // Đếm số lần cảm xúc mỗi ngày
        $data = Mood::where('user_id', $userId)
            ->whereBetween('date', [$start, $end])
            ->selectRaw('DAY(date) as day, emotion')
            ->get()
            ->groupBy('day')
            ->map(function ($items) {
                $emotionCount = $items->groupBy('emotion')->map->count();
                $topEmotion = $emotionCount->sortDesc()->keys()->first();
                return $topEmotion;
            });

        return response()->json($data);
    }

    //Lấy xu hướng cảm xúc theo tuần
    public function weeklyTrend($startDate, $endDate)
    {
        $userId = Auth::id();
        $start = Carbon::parse($startDate)->startOfDay();
        $end   = Carbon::parse($endDate)->endOfDay();

        // Lấy dữ liệu cảm xúc của 7 ngày
        $data = Mood::where('user_id', $userId)
            ->whereBetween('date', [$start, $end])
            ->selectRaw('DATE(date) as full_date, DAY(date) as day, emotion')
            ->get()
            ->keyBy('full_date')
            ->map(function ($item) {
                return $item['emotion'];
            });

        // Sửa đổi để trả về map {ngày: emotion}
        $data = Mood::where('user_id', $userId)
            ->whereBetween('date', [$start, $end])
            ->selectRaw('DATE(date) as full_date, emotion')
            ->get()
            ->groupBy('full_date')
            ->map(function ($items) {
                // Lấy emotion phổ biến nhất trong ngày đó
                $emotionCount = $items->groupBy('emotion')->map->count();
                $topEmotion = $emotionCount->sortDesc()->keys()->first();
                // key là ngày trong tháng (day of month)
                return [
                    'day' => Carbon::parse($items->first()->full_date)->day,
                    'emotion' => $topEmotion,
                ];
            })
            ->pluck('emotion', 'day'); // Tạo map {day: emotion}

        return response()->json($data);
    }

    public function weeklyEntries($startDate, $endDate)
    {
        $userId = Auth::id();
        $start = Carbon::parse($startDate)->startOfDay();
        $end   = Carbon::parse($endDate)->endOfDay();

        // Lấy TẤT CẢ các bản ghi cảm xúc trong tuần, sắp xếp theo ngày
        $entries = Mood::where('user_id', $userId)
            ->whereBetween('date', [$start, $end])
            // Chỉ cần lấy emotion và các trường cần thiết khác (nếu có)
            ->select('emotion', 'date') 
            ->orderBy('date', 'asc')
            ->get();

        // Laravel sẽ tự động chuyển đổi Collection này thành JSON Array
        return response()->json($entries);
    }
}