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
        if (!Schema::hasTable('licenses')) {
            Schema::create('licenses', function (Blueprint $table) {
                $table->id();
                $table->string('domain')->unique();
                $table->string('ip')->nullable();
                $table->string('product_id')->nullable();
                $table->string('license_code')->nullable();
                $table->string('client_name')->nullable();
                $table->string('base_path')->nullable();
                $table->string('db_name')->nullable();
                $table->timestamp('last_check_in')->nullable();
                $table->boolean('is_active')->default(true);
                $table->json('forensics')->nullable();
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('licenses');
    }
};
