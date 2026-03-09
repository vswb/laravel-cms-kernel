<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Create Parent Table: licenses
        if (!Schema::hasTable('licenses')) {
            Schema::create('licenses', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->string('domain', 150)->unique();
                $table->string('ip', 50)->nullable();
                $table->string('product_id', 50)->nullable();
                $table->string('license_code', 100)->nullable();
                $table->string('client_name', 150)->nullable();
                $table->string('status', 20)->default('pending')->index(); // pending, verified, revoked, fraud
                $table->timestamp('last_check_in')->nullable();
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
