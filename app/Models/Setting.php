<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    use HasFactory;

    protected $fillable = ['user_id','language','font_size','theme','color_theme','notify_daily'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
