<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('badges', function (Blueprint $table) {
            $table->string('image_url')->nullable()->after('ai_quote');
        });
    }
};
