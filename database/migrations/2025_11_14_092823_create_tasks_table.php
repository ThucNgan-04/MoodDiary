<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Đảm bảo tên class phải khớp với tên file (CreateTasksTable)
class CreateTasksTable extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tasks', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique()->comment('Mã định danh nhiệm vụ: T.UOI_3_NGAY');
            $table->string('title')->comment('Tiêu đề hiển thị: Tưới cây 3 ngày');
            $table->text('description')->nullable();
            $table->integer('target_count')->default(1)->comment('Số lần cần hoàn thành (vd: 3 ngày, 7 ngày, 1 lần bạn bè)');
            $table->integer('water_reward')->default(1)->comment('Phần thưởng nước');
            // ĐÃ THÊM 'consecutive' VÀO DANH SÁCH ENUM ĐỂ KHỚP VỚI DỮ LIỆU SEEDER
            $table->enum('frequency', ['daily', 'weekly', 'biweekly', 'one_time', 'consecutive'])->default('daily'); 
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tasks');
    }
}