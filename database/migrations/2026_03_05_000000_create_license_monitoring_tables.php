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
                $table->timestamp('last_check_in')->nullable();
                $table->boolean('is_active')->default(0);
                $table->timestamps();
            });
        }

        // 2. Create Child Table: license_histories
        if (!Schema::hasTable('license_histories')) {
            Schema::create('license_histories', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('license_id')->index();
                $table->string('domain', 150)->index();
                $table->string('ip', 50)->nullable();
                $table->text('base_path')->nullable();
                $table->timestamps();

                // Foreign Key setup with Cascade Delete
                $table->foreign('license_id')
                    ->references('id')
                    ->on('licenses')
                    ->onDelete('cascade');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('license_histories');
        Schema::dropIfExists('licenses');
    }
};
