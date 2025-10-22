<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
        public function up()
    {
        Schema::table('badges', function (Blueprint $table) {
            $table->text('ai_quote')->nullable()->after('description');
        });
    }

    public function down()
    {
        Schema::table('badges', function (Blueprint $table) {
            $table->dropColumn('ai_quote');
        });
    }

};
