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

        // Lấy cảm xúc phổ biến nhất (top emotion) cho từng ngày trong tháng
        $data = Mood::where('user_id', $userId)
            ->whereBetween('date', [$start, $end])
            ->selectRaw('DATE(date) as full_date, emotion')
            ->get()
            ->groupBy('full_date') 
            ->map(function ($items) {
                $emotionCount = $items->groupBy('emotion')->map->count();
                $topEmotion = $emotionCount->sortDesc()->keys()->first();
                
                return [
                    'day' => Carbon::parse($items->first()->full_date)->day,
                    'emotion' => $topEmotion,
                ];
            })
            ->pluck('emotion', 'day'); // Tạo map {day_of_month: top_emotion}


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
            ->select('emotion', 'date') 
            ->orderBy('date', 'asc')
            ->get();

        return response()->json($entries);
    }
}