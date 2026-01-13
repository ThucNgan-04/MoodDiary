<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserTask extends Model
{
    use HasFactory;
    
    //BẮT BUỘC: Khai báo các trường được phép gán dữ liệu hàng loạt
    protected $fillable = [
        'user_id',
        'task_id',
        'current_count',
        'reset_at',
        'is_completed',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    //QUAN HỆ: Cần thiết cho UserTask::with('task')
    public function task()
    {
        return $this->belongsTo(Task::class);
    }
}