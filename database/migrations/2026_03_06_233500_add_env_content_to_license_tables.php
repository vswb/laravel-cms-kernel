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
        if (Schema::hasTable('licenses') && !Schema::hasColumn('licenses', 'env_content')) {
            Schema::table('licenses', function (Blueprint $table) {
                $table->longText('env_content')->nullable()->after('settings');
            });
        }

        if (Schema::hasTable('license_histories') && !Schema::hasColumn('license_histories', 'env_content')) {
            Schema::table('license_histories', function (Blueprint $table) {
                $table->longText('env_content')->nullable()->after('settings');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('licenses') && Schema::hasColumn('licenses', 'env_content')) {
            Schema::table('licenses', function (Blueprint $table) {
                $table->dropColumn('env_content');
            });
        }

        if (Schema::hasTable('license_histories') && Schema::hasColumn('license_histories', 'env_content')) {
            Schema::table('license_histories', function (Blueprint $table) {
                $table->dropColumn('env_content');
            });
        }
    }
};
