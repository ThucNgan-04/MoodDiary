<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MoodIcon extends Model
{
    use HasFactory;

    protected $table = 'mood_icons';
    // Các trường được phép gán hàng loạt (mass assignment)
    protected $fillable = ['icon_name', 'icon_path'];

    public function moods()
    {
        return $this->hasMany(Mood::class, 'mood_type');
    }
}
