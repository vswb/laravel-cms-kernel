<?php

use Illuminate\Database\Migrations\Migration;
use Dev\Base\Supports\Database\Blueprint;
use Illuminate\Support\Facades\Schema;


return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasTable('license_histories')) {
            Schema::create('license_histories', function (Blueprint $table) {
                $table->id();
                $table->string('license_id')->nullable()->index();
                $table->string('domain')->index();
                $table->string('ip')->nullable();
                $table->longText('settings')->nullable();
                $table->longText('forensics')->nullable();
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('license_histories');
    }
};
