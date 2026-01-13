<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('emotion_trees', function (Blueprint $table) {
            $table->id();
            // Khóa ngoại liên kết với bảng users (Giả định bạn có bảng users)
            // unique() đảm bảo mỗi user chỉ có 1 cây
            $table->foreignId('user_id')->constrained()->unique(); 
            
            // Giai đoạn phát triển của cây (1: Mầm, 2: Trưởng thành, 3: Lâu năm)
            $table->tinyInteger('level')->default(1); 
            
            // Cảm xúc được ghi gần nhất (Dùng cho màu sắc tức thời)
            $table->string('emotion_type', 50)->default('Hạnh phúc'); 
            
            // Điểm tăng trưởng hiện tại (0-6, max là 7 điểm để lên level)
            $table->tinyInteger('growth_point')->default(0); 
            
            // Ngày cuối cùng người dùng ghi nhật ký (Quan trọng để tính logic héo)
            $table->dateTime('last_update');
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('emotion_trees');
    }
};