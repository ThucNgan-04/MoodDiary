<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Task extends Model
{
    use HasFactory;

    // BẮT BUỘC PHẢI THÊM: Cho phép tạo các trường này qua TaskSeeder
    protected $fillable = [
        'key',
        'title',
        'description',
        'frequency',
        'target_count',
        'water_reward',
        'is_active',
    ];

    public function userTasks()
    {
        return $this->hasMany(UserTask::class);
    }
}