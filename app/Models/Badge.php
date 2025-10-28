<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Badge extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'badge_name',
        'description',
        'ai_quote',
        'image_url',
        'earned_date',
    ];

    protected $casts = [
        'earned_date' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}