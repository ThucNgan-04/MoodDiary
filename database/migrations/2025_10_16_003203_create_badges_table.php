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
        Schema::create('badges', function (Blueprint $table) {
            $table->id();
            
            // Khóa ngoại
            $table->unsignedBigInteger('user_id');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            
            // Các cột dữ liệu
            $table->string('badge_name', 100);
            $table->text('description')->nullable();
            
            // Các cột được thêm vào từ các migration phụ (và xuất hiện trong truy vấn lỗi)
            $table->text('ai_quote')->nullable();
            $table->string('image_url')->nullable();
            
            // Cột ngày nhận badge
            $table->timestamp('earned_date')->useCurrent();
            
            // Khắc phục lỗi "Unknown column 'updated_at'"
            $table->timestamps(); // Thêm 'created_at' và 'updated_at'
            
            // Constraints
            $table->unique(['user_id', 'badge_name']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('badges');
    }
};