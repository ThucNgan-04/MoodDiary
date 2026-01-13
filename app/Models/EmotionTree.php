<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmotionTree extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'level',
        'emotion_type',
        'growth_point',
        'last_update',
    ];

    /**
     * Định nghĩa mối quan hệ với User.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    //QUAN HỆ VỚI USER TASKS
    public function userTasks()
    {
        return $this->hasMany(UserTask::class, 'user_id', 'user_id');
    }
}