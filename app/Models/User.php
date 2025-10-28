<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Passport\HasApiTokens;
use App\Models\Badge;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name','email','password','avatar','gender','bio','role'
    ];

    protected $hidden = ['password','remember_token'];

    public function moods()
    {
        return $this->hasMany(Mood::class);
    }

    public function setting()
    {
        return $this->hasOne(Setting::class);
    }

    //1 người dùng có nhiều huy hiệu
    public function badges()
    {
        return $this->hasMany(Badge::class, 'user_id');
    }
}
