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
        // 1. Add missing columns to license_histories and prepare it to be a proper child
        Schema::table('license_histories', function (Blueprint $table) {
            // Check before adding to prevent errors
            if (!Schema::hasColumn('license_histories', 'base_path')) {
                $table->text('base_path')->nullable()->after('ip');
            }
            if (!Schema::hasColumn('license_histories', 'db_name')) {
                $table->string('db_name')->nullable()->after('base_path');
            }

            // Ensure license_id is a UUID string and add foreign key
            // Note: If you want to use true foreign keys, make sure types match exactly.
            // licenses.id is uuid string.
            $table->foreign('license_id')
                ->references('id')
                ->on('licenses')
                ->onDelete('cascade');
        });

        // 2. Remove columns from licenses
        Schema::table('licenses', function (Blueprint $table) {
            $table->dropColumn([
                'base_path',
                'db_name',
                'forensics',
                'settings',
                'env_content'
            ]);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('licenses', function (Blueprint $table) {
            $table->text('base_path')->nullable();
            $table->string('db_name')->nullable();
            $table->longText('forensics')->nullable();
            $table->longText('settings')->nullable();
            $table->longText('env_content')->nullable();
        });

        Schema::table('license_histories', function (Blueprint $table) {
            $table->dropForeign(['license_id']);
            $table->dropColumn(['base_path', 'db_name']);
        });
    }
};
