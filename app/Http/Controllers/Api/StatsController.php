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
    //Cảm xúc theo ngày đường
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
}