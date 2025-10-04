<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Setting;
use App\Models\Suggestion;

class DatabaseSeeder extends Seeder
{
    public function run()
    {
        $admin = User::create([
            'name'=>'Admin',
            'email'=>'admin@example.com',
            'password'=>bcrypt('admin123'),
            'role'=>'admin',
            'gender'=>'male'
        ]);

        Setting::create(['user_id'=>$admin->id,'theme'=>'dark']);

        Suggestion::insert([
            ['mood_type'=>'fun','content'=>'Hãy tận hưởng khoảnh khắc vui vẻ này cùng với người bạn của bạn!'],
            ['mood_type'=>'happy','content'=>'Hãy chia sẻ niềm vui với bạn bè.'],
            ['mood_type'=>'sad','content'=>'Nghe một bản nhạc yêu thích để thư giãn.'],
            ['mood_type'=>'love','content'=>'Hãy gọi điện với người ấy để trau dồi tình củm ngen'],
            ['mood_type'=>'angry','content'=>'Hít thở sâu 5 lần và thử bình tĩnh lại.'],
            ['mood_type'=>'love','content'=>'Hãy nói lời "yêu thương" với ai đó hôm nay'],
        ]);
    }
}
