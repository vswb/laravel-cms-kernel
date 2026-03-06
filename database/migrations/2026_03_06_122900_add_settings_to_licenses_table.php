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
        if (Schema::hasTable('licenses') && !Schema::hasColumn('licenses', 'settings')) {
            Schema::table('licenses', function (Blueprint $table) {
                $table->longText('settings')->nullable()->after('forensics');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('licenses') && Schema::hasColumn('licenses', 'settings')) {
            Schema::table('licenses', function (Blueprint $table) {
                $table->dropColumn('settings');
            });
        }
    }
};
