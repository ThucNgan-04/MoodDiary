<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Mood;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class MoodController extends Controller
{
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
}