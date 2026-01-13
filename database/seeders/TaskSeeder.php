<?php

namespace Database\Seeders;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\Seeder;
use App\Models\Task;

class TaskSeeder extends Seeder
{
    /**
     * Chèn dữ liệu nhiệm vụ gốc vào bảng 'tasks'.
     */
    public function run()
    {
        DB::statement('SET FOREIGN_KEY_CHECKS=0;'); 

        Task::truncate();

        // 4. KÍCH HOẠT LẠI kiểm tra khóa ngoại
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');
        // Xóa tất cả dữ liệu cũ để tránh trùng lặp khi chạy lại
        

        $tasks = [
            // Nhiệm vụ hàng ngày: Ghi nhật ký (Daily Write Diary)
            // Sẽ được kích hoạt từ logDiary() Controller
            [
                'key' => 'WRITE_DIARY_1',
                'title' => 'Hôm nay tưới cây cho bạn 1 lần',
                'description' => 'Ghi nhật ký cảm xúc một lần trong ngày.',
                'frequency' => 'daily',
                'target_count' => 1,
                'water_reward' => 1,
                'is_active' => true,
            ],
            
            // Nhiệm vụ chuỗi ngày: Tưới cây 3 ngày liên tiếp
            [
                'key' => 'WATER_3_DAYS',
                'title' => 'Tưới cây 3 ngày liên tiếp',
                'description' => 'Tưới nước cho cây cảm xúc 3 ngày liên tiếp bằng cách ghi nhật ký.',
                'frequency' => 'consecutive', // Tần suất liên tiếp
                'target_count' => 3,
                'water_reward' => 3,
                'is_active' => true,
            ],
            
            // Nhiệm vụ chuỗi ngày: Tưới cây 7 ngày liên tiếp
            [
                'key' => 'WATER_7_DAYS',
                'title' => 'Tưới cây 7 ngày liên tiếp',
                'description' => 'Tưới nước cho cây cảm xúc 7 ngày liên tiếp bằng cách ghi nhật ký.',
                'frequency' => 'consecutive',
                'target_count' => 7,
                'water_reward' => 7,
                'is_active' => true,
            ],
            
            // Nhiệm vụ chuỗi ngày: Tưới cây 14 ngày liên tiếp
            [
                'key' => 'WATER_14_DAYS',
                'title' => 'Tưới cây 14 ngày liên tiếp',
                'description' => 'Tưới nước cho cây cảm xúc 14 ngày liên tiếp bằng cách ghi nhật ký.',
                'frequency' => 'consecutive',
                'target_count' => 14,
                'water_reward' => 15,
                'is_active' => true,
            ],
        ];

        foreach ($tasks as $task) {
            Task::create($task);
        }
    }
}