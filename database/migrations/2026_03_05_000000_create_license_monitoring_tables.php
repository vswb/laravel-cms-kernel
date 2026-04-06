<?php

/**
 * © 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Proprietary software developed and distributed by Visual Weber.
 * Use is permitted only under a valid license agreement.
 *
 * © 2026 CÔNG TY TNHH VISUAL WEBER. Bảo lưu mọi quyền.
 * Phần mềm độc quyền của Visual Weber, chỉ được sử dụng theo Hợp đồng cấp phép.
 */


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
                $table->enum('status', ['pending', 'verified', 'revoked', 'fraud', 'tracked'])
                    ->default('pending')
                    ->index()
                    ->comment('pending: New/First check-in, verified: Manually approved customer, revoked: Terminated/Expired, fraud: Blacklisted/Confirmed theft, tracked: Silent monitoring mode');
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
