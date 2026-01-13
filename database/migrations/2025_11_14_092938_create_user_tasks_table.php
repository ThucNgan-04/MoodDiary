<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Đảm bảo tên class phải khớp với tên file (CreateUserTasksTable)
class CreateUserTasksTable extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('user_tasks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('task_id')->constrained()->onDelete('cascade');
            $table->integer('current_count')->default(0)->comment('Số lần đã hoàn thành');
            $table->dateTime('reset_at')->comment('Thời điểm nhiệm vụ này sẽ reset (dựa trên tần suất)');      
            $table->boolean('is_completed')->default(false);
            $table->unique(['user_id', 'task_id']);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_tasks');
    }
}