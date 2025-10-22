<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('badges', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('badge_name', 100);
            $table->text('description')->nullable();
            $table->timestamp('earned_date')->useCurrent();
            $table->unique(['user_id', 'badge_name']);
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }
};