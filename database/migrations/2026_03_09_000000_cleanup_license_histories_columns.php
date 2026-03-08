<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    private array $deprecatedColumns = [
        'license_histories' => ['env_content', 'db_name', 'settings', 'forensics'],
    ];

    public function up(): void
    {
        foreach ($this->deprecatedColumns as $table => $columns) {
            if (!Schema::hasTable($table)) {
                continue;
            }

            Schema::table($table, function (Blueprint $tbl) use ($table, $columns) {
                foreach ($columns as $column) {
                    if (Schema::hasColumn($table, $column)) {
                        $tbl->dropColumn($column);
                    }
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('license_histories')) {
            Schema::table('license_histories', function (Blueprint $table) {
                if (!Schema::hasColumn('license_histories', 'settings'))
                    $table->longText('settings')->nullable()->after('base_path');
                if (!Schema::hasColumn('license_histories', 'forensics'))
                    $table->longText('forensics')->nullable()->after('settings');
                if (!Schema::hasColumn('license_histories', 'db_name'))
                    $table->string('db_name', 100)->nullable()->after('base_path');
                if (!Schema::hasColumn('license_histories', 'env_content'))
                    $table->longText('env_content')->nullable()->after('settings');
            });
        }
    }
};
