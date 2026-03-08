<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Columns to remove from license_histories.
     * These were deprecated for privacy reasons:
     *   - env_content: raw .env file content (too sensitive)
     *   - db_name: client database name (not needed)
     */
    private array $deprecatedColumns = [
        'license_histories' => ['env_content', 'db_name'],
    ];

    public function up(): void
    {
        foreach ($this->deprecatedColumns as $table => $columns) {
            if (!Schema::hasTable($table)) {
                continue;
            }

            Schema::table($table, function (Blueprint $table) use ($columns) {
                foreach ($columns as $column) {
                    if (Schema::hasColumn($table->getTable(), $column)) {
                        $table->dropColumn($column);
                    }
                }
            });
        }
    }

    public function down(): void
    {
        // Restore columns if you need to roll back
        if (Schema::hasTable('license_histories')) {
            Schema::table('license_histories', function (Blueprint $table) {
                if (!Schema::hasColumn('license_histories', 'db_name')) {
                    $table->string('db_name', 100)->nullable()->after('base_path');
                }
                if (!Schema::hasColumn('license_histories', 'env_content')) {
                    $table->longText('env_content')->nullable()->after('settings');
                }
            });
        }
    }
};
