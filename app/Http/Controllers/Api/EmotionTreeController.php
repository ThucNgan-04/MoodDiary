<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use App\Models\EmotionTree;
use App\Models\Mood; 
use App\Models\Task;
use App\Models\UserTask;

class EmotionTreeController extends Controller
{
    const MAX_GROWTH_POINT = 7;
    const MAX_LEVEL = 3;
    const DAYS_TO_WITHER = 7; // Số ngày không ghi nhật ký để cây héo

    private function synchronizeUserTasks($userId)
    {
        $activeTasks = Task::where('is_active', true)->get();
        $now = Carbon::now();

        foreach ($activeTasks as $task) {
            $userTask = UserTask::where('user_id', $userId)
                                ->where('task_id', $task->id)
                                ->first();

            if (!$userTask) {
                // Tạo UserTask nếu chưa tồn tại
                UserTask::create([
                    'user_id' => $userId,
                    'task_id' => $task->id,
                    'current_count' => 0,
                    'reset_at' => $this->calculateNextReset($now, $task->frequency),
                    'is_completed' => false,
                ]);
            } else {
                // Kiểm tra và Reset nếu đã quá thời gian
                if ($now->greaterThanOrEqualTo(Carbon::parse($userTask->reset_at))) {
                    // Reset nhiệm vụ
                    $userTask->update([
                        'current_count' => 0,
                        'is_completed' => false,
                        'reset_at' => $this->calculateNextReset($now, $task->frequency),
                    ]);
                }
            }
        }
    }

    /**
     * Tính toán thời điểm reset tiếp theo dựa trên tần suất.
     */
    private function calculateNextReset($currentTime, $frequency)
    {
        switch ($frequency) {
            case 'daily':
                return $currentTime->copy()->addDay()->startOfDay();
            case 'weekly':
                return $currentTime->copy()->addWeek()->startOfWeek(); // Reset vào đầu tuần sau
            case 'biweekly':
                return $currentTime->copy()->addWeeks(2)->startOfWeek(); // Reset vào đầu 2 tuần sau
            default: // One_time
                return $currentTime->copy()->addYears(100); // Không bao giờ reset
        }
    }
    
    /**
     * Lấy danh sách nhiệm vụ đã định dạng.
     */
    private function getFormattedWaterTasks($userId)
    {
        $this->synchronizeUserTasks($userId);

        $userTasks = UserTask::with('task')
            ->where('user_id', $userId)
            ->get();

        return $userTasks->map(function ($ut) {
            $task = $ut->task;
            $progress = min($ut->current_count, $task->target_count); // Không cho hiển thị vượt quá target
            $isCompleted = $ut->is_completed || ($progress >= $task->target_count);

            return [
                'id' => $task->id,
                'title' => $task->title,
                'reward' => "+" . $task->water_reward . " nước",
                'progress' => "$progress/{$task->target_count}",
                'is_done' => $isCompleted,
            ];
        });
    }

    /**
     * Lấy hoặc tạo cây cảm xúc của người dùng và tính toán các chỉ số
     */
    private function getCurrentTreeData($userId)
    {
        // Lấy hoặc tạo cây
        $tree = EmotionTree::firstOrCreate(
            ['user_id' => $userId],
            [
                'level' => 0,
                'emotion_type' => 'Hạnh phúc',
                'growth_point' => 0,
                'last_update' => Carbon::now()->subDays(self::DAYS_TO_WITHER + 1)->toDateTimeString(),
            ]
        );
        
        $isWilted = false;
        $daysSinceLastEntry = 0;

        // Nếu cây đã được trồng (Level > 0)
        if ($tree->level > 0) {
            // Tính toán ngày không ghi nhật ký
            $lastUpdate = Carbon::parse($tree->last_update);
            $daysSinceLastEntry = $lastUpdate->diffInDays(Carbon::now());

            // KIỂM TRA CÂY HÉO/CHẾT
            if ($daysSinceLastEntry >= self::DAYS_TO_WITHER) {
                $isWilted = true;
            }
        }
        
        // Lấy Cảm xúc Chiếm ưu thế trong 30 ngày gần nhất
        $emotionDominance = $this->getDominantEmotion($userId); 

        return [
            'level' => $tree->level,
            'emotion_type' => $tree->emotion_type, // Cảm xúc nhật ký gần nhất
            'growth_point' => $tree->growth_point,
            'emotion_dominance' => $emotionDominance, // Dùng cho màu sắc/hình ảnh chính theo tháng
            'days_since_last_entry' => $daysSinceLastEntry, // Dùng cho logic héo trên frontend
            // NEEDS_PLANTING: TRUE nếu Level = 0 (Chưa trồng) HOẶC cây bị héo hoàn toàn/chết
            'needs_planting' => ($tree->level == 0 || $isWilted)
        ];
    }
    
    /**
     * Phân tích cảm xúc chiếm ưu thế trong 30 ngày gần nhất. màu chính của cây
     */
    private function getDominantEmotion($userId): string
    {
        // Truy vấn bảng Mood để tìm cảm xúc được ghi nhiều nhất trong 30 ngày qua
        $dominant = Mood::where('user_id', $userId)
            // Lọc các nhật ký từ 30 ngày trước đến nay
            ->where('created_at', '>=', Carbon::now()->subDays(30)) 
            // Gom nhóm theo cột 'emotion' (từ bảng moods)
            ->groupBy('emotion')
            // Đếm số lần xuất hiện và chọn cột 'emotion'
            ->selectRaw('count(*) as count, emotion') 
            // Sắp xếp giảm dần theo số lần đếm
            ->orderByDesc('count')
            // Chỉ lấy kết quả đầu tiên (cảm xúc chiếm ưu thế)
            ->first();
            
        // Trả về cảm xúc chiếm ưu thế, hoặc 'Hạnh phúc' nếu không có dữ liệu
        return $dominant ? $dominant->emotion : 'Hạnh phúc';
    }

    /**
     * [GET] Lấy trạng thái Cây Cảm Xúc cá nhân. (Giữ nguyên)
     */
    public function getTreeStatus(Request $request)
    {
        $userId = $request->user()->id; 

        $treeData = $this->getCurrentTreeData($userId);

        $waterTasks = $this->getFormattedWaterTasks($userId);

        return response()->json([
            'status' => 'success',
            'data' => array_merge($treeData, [
                'water_tasks' => $waterTasks, 
            ]),
        ]);
    }

    /**
     * [POST] Xử lý cập nhật cây sau khi ghi nhật ký. (Giữ nguyên logic tăng trưởng)
     */
    public function logDiary(Request $request)
    {
        $request->validate([
            'emotion_type' => 'required|string', 
        ]);

        $userId = $request->user()->id;
        $newEmotion = $request->input('emotion_type');

        $tree = EmotionTree::where('user_id', $userId)->first();

        // Kiểm tra xem cây đã được trồng chưa (Level > 0). Nếu chưa, không cho ghi nhật ký
        if (!$tree || $tree->level == 0) {
            return response()->json([
                'status' => 'error',
                'message' => 'Cây chưa được trồng. Vui lòng trồng cây trước khi ghi nhật ký.',
            ], 400);
        }
        
        // Kiểm tra nếu đã ghi nhật ký hôm nay
        if (Carbon::parse($tree->last_update)->isToday()) {
            // Cập nhật cảm xúc tức thời và ngày update
            $tree->emotion_type = $newEmotion;
            $tree->last_update = Carbon::now()->toDateTimeString();
            $tree->save();
            $this->updateTaskProgress($userId, 'WATER_FRIEND');
            return response()->json([
                'status' => 'success',
                'message' => 'Đã cập nhật nhật ký. Cây đã được tưới hôm nay (Không tăng điểm).',
                'tree_status' => $this->getCurrentTreeData($userId)
            ]);
        }
        
        // LOGIC TĂNG TRƯỞNG (Chỉ chạy nếu đây là nhật ký ĐẦU TIÊN trong ngày)
        $currentPoints = $tree->growth_point;
        $currentLevel = $tree->level;

        $newPoints = $currentPoints + 1;
        $newLevel = $currentLevel;
        
        // Tăng cấp khi đạt đủ điểm và chưa phải level tối đa
        if ($newPoints >= self::MAX_GROWTH_POINT) {
            if ($currentLevel < self::MAX_LEVEL) {
                $newLevel = $currentLevel + 1;
                $newPoints = 0; // Reset điểm khi lên cấp
            } else {
                $newPoints = self::MAX_GROWTH_POINT - 1; // Giữ ở mức tối đa nếu đã Level 3
            }
        }

        // Cập nhật vào DB
        $tree->level = $newLevel;
        $tree->emotion_type = $newEmotion;
        $tree->growth_point = $newPoints;
        $tree->last_update = Carbon::now()->toDateTimeString();
        $tree->save();
        
        // GỌI HÀM CẬP NHẬT TIẾN TRÌNH NHIỆM VỤ SAU KHI GHI NHẬT KÝ LẦN ĐẦU
        $this->updateTaskProgress($userId, 'WRITE_DIARY_1');
        $this->updateTaskProgress($userId, 'WATER_3_DAYS');
        $this->updateTaskProgress($userId, 'WATER_7_DAYS');
        $this->updateTaskProgress($userId, 'WATER_14_DAYS');

        // Trả về trạng thái cây mới
        return response()->json([
            'status' => 'success',
            'message' => 'Nhật ký đã được ghi. Cây cảm xúc của bạn đã tăng trưởng.',
            'tree_status' => $this->getCurrentTreeData($userId),
        ]);
    }
    
    /**
     * [POST] Kích hoạt quá trình trồng cây (Level 0 -> Level 1 HOẶC Reset cây chết).
     * Luôn set Level = 1 khi trồng cây, loại bỏ Level 0 khỏi trạng thái hoạt động.
     */
    public function plantTree(Request $request)
    {
        $request->validate([
            'seed_type' => 'required|string', // Loại hạt giống người dùng chọn
        ]);

        $userId = $request->user()->id;
        $seedType = $request->input('seed_type');

        $tree = EmotionTree::where('user_id', $userId)->first();
        
        // Nếu cây chưa tồn tại (chưa từng được tạo qua firstOrCreate)
        if (!$tree) {
             $tree = EmotionTree::create([
                'user_id' => $userId,
                'level' => 1, // Bắt đầu ở Level 1
                'emotion_type' => $seedType,
                'growth_point' => 0,
                'last_update' => Carbon::now()->toDateTimeString(),
            ]);
        } else {
            // Nếu cây đã tồn tại, reset lại trạng thái về Level 1
            $tree->level = 1; // Level 1 là trạng thái cây mới nhất sau khi trồng/reset
            $tree->emotion_type = $seedType; // Cảm xúc khởi đầu
            $tree->growth_point = 0;
            $tree->last_update = Carbon::now()->toDateTimeString();
            $tree->save();
        }
        
        return response()->json([
            'status' => 'success',
            'message' => 'Hạt giống đã được trồng thành công! Cây đang ở Level 1.',
            'tree_status' => $this->getCurrentTreeData($userId),
        ]);
    }
    /**
     * Xử lý cập nhật tiến trình nhiệm vụ.
     * Cần gọi hàm này sau khi người dùng thực hiện các hành động liên quan đến nhiệm vụ
     * Ví dụ: Sau khi ghi nhật ký, gọi updateTaskProgress($userId, 'WRITE_DIARY_1');
     */
    public function updateTaskProgress($userId, $taskKey, $count = 1)
    {
        $task = Task::where('key', $taskKey)->first();
        if (!$task) return;

        $userTask = UserTask::where('user_id', $userId)
                            ->where('task_id', $task->id)
                            ->first();
        
        if (!$userTask) {
            $this->synchronizeUserTasks($userId);
            $userTask = UserTask::where('user_id', $userId)->where('task_id', $task->id)->first();
            if (!$userTask) return; 
        }
        
        if ($userTask->is_completed){
            if ($task->frequency != 'consecutive') {
                return;
            }
        }
        $now = Carbon::now();
        $lastActionDate = Carbon::parse($userTask->updated_at)->startOfDay();

        // **********NHIỆM VỤ LIÊN TIẾP **********
        if ($task->frequency == 'consecutive') {
            
            $today = $now->copy()->startOfDay();
            if ($lastActionDate->equalTo($today)) {
                return; // Đã ghi nhật ký hôm nay
            }
            
            // 3. Kiểm tra Chuỗi liên tiếp có bị đứt quãng không
            // Ngày cần kiểm tra là NGÀY HÔM QUA
            $yesterday = $now->copy()->subDay()->startOfDay();
            
            // Nếu hành động cuối cùng KHÔNG phải là HÔM QUA (và không phải HÔM NAY - đã kiểm tra ở trên)
            // VÀ current_count lớn hơn 0 (đã có chuỗi) thì reset chuỗi.
            if (!$lastActionDate->equalTo($yesterday) && $userTask->current_count > 0) {
                // Chuỗi bị đứt quãng, reset về 0.
                $userTask->current_count = 0; 
                $userTask->is_completed = false;
            }
            if ($userTask->current_count >= $task->target_count) {
                $userTask->current_count = 0; 
                $userTask->is_completed = false;
            }
        }
        // ********** KẾT THÚC LOGIC LIÊN TIẾP **********
        
        // Logic tăng điểm chung (áp dụng cho cả daily và consecutive sau khi kiểm tra reset)
        $newCount = $userTask->current_count + $count;
        
        if ($task->frequency != 'consecutive') {
            $newCount = min($newCount, $task->target_count);
        }
        $isCompleted = $newCount >= $task->target_count;
        // Cập nhật
        $userTask->current_count = $newCount;
        $userTask->is_completed = $isCompleted;
        $userTask->updated_at = $now; // Đánh dấu ngày cập nhật

        // Xử lý phần thưởng khi hoàn thành (giữ nguyên logic bạn đã có)
        if ($isCompleted && !$userTask->getOriginal('is_completed')) {
        }
        
        $userTask->save();
    }
    public function getFriendTrees(Request $request) { 
        return response()->json(['message' => 'Tính năng này sẽ sớm được triển khai.']);
    }
    public function performAction(Request $request) 
    {  
        $userId = $request->user()->id ?? 1;
        $this->updateTaskProgress($userId, 'WATER_FRIEND', 1);
        return response()->json(['message' => 'Tính năng này sẽ sớm được triển khai.']);
    }
}