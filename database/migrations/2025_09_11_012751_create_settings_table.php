<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('language')->default('vi');
            $table->enum('font_size', ['small','medium','large'])->default('medium');
            $table->enum('theme', ['light','dark'])->default('light');
            $table->boolean('notify_daily')->default(true);
            $table->timestamps();

            $table->unique('user_id'); // Đảm bảo mỗi user chỉ có 1 bản ghi setting
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('settings');
    }
};
