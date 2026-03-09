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
        if (Schema::hasTable('licenses')) {
            Schema::table('licenses', function (Blueprint $table) {
                if (!Schema::hasColumn('licenses', 'status')) {
                    $table->string('status', 20)->default('pending')->index()->after('client_name');
                }
                if (Schema::hasColumn('licenses', 'is_active')) {
                    $table->dropColumn('is_active');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('licenses')) {
            Schema::table('licenses', function (Blueprint $table) {
                if (Schema::hasColumn('licenses', 'status')) {
                    $table->dropColumn('status');
                }
                if (!Schema::hasColumn('licenses', 'is_active')) {
                    $table->boolean('is_active')->default(0)->after('last_check_in');
                }
            });
        }
    }
};
