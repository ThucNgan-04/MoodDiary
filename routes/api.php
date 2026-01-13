<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\MoodController;
use App\Http\Controllers\Api\SettingController;
use App\Http\Controllers\Api\AIController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\BadgeController;
use App\Http\Controllers\Api\StatsController;
use App\Http\Controllers\Api\EmotionTreeController;

// Auth API
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:api')->group(function(){
    // Route User
    Route::get('/user',[AuthController::class,'user']);
    Route::post('/logout',[AuthController::class,'logout']);
    Route::post('/change-password',[AuthController::class,'changePassword']);
    Route::get('/users',[AuthController::class,'index']);
    Route::delete('/users/{id}',[AuthController::class,'destroy']);
    Route::put('/user/profile', [AuthController::class, 'updateProfile']);
    Route::post('/user/avatar', [UserController::class, 'updateAvatar']);

    // Route Settings
    Route::get('/settings', [SettingController::class, 'getSettings']);
    Route::put('/settings', [SettingController::class, 'updateSettings']);

    // Route Moods
    Route::get('/moods',[MoodController::class,'index']);
    //AI
    Route::post('/moods',[MoodController::class,'store']);
    Route::put('/moods/{id}',[MoodController::class,'update']);
    Route::delete('/moods/{id}',[MoodController::class,'destroy']);
    Route::get('/mood-monthly/{year}/{month}', [StatsController::class, 'Monthly']);
    Route::get('/mood-daily-trend/{year}/{month}', [StatsController::class, 'dailyTrend']);
    Route::get('/mood-all-entries/{startDate}/{endDate}', [StatsController::class, 'weeklyEntries']);   

    // Route huy hiệu
    Route::get('/badges/me', [BadgeController::class, 'me']);
    Route::post('/badges/save', [BadgeController::class, 'store']);
    Route::get('/badges/check', [BadgeController::class, 'checkBadges']);
    Route::get('/badges/{user_id}', [BadgeController::class, 'getUserBadges']);
    Route::post('badges/revoke', [BadgeController::class, 'revokeBadge']);
    //AI huy note hh
    Route::get('/badges/streak-info', [BadgeController::class, 'getStreakInfo']);

    //test ai
    Route::post('/ai/analyze-stats', [AIController::class, 'analyzeStats']);
    Route::post('/ai/generate-badge-quote', [AIController::class, 'generateBadgeQuote']);
    Route::post('/ai/mood-shift-analysis', [AIController::class, 'analyzeWeeklyMoodShift']);

    // Emotion Tree & Garden Routes
    // Lấy trạng thái Cây Cảm Xúc cá nhân
    Route::get('/tree/status', [EmotionTreeController::class, 'getTreeStatus']);
    Route::post('/tree/plant', [EmotionTreeController::class, 'plantTree']);
    Route::post('/tree/log', [EmotionTreeController::class, 'logDiary']); 
    //(Vườn Cảm Xúc)
    Route::get('/garden/friends', [EmotionTreeController::class, 'getFriendTrees']);
    //Thực hiện hành động tương tác (Tưới cây,...)
    Route::post('/garden/action', [EmotionTreeController::class, 'performAction']);
});