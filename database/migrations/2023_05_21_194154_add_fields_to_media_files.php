<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use Platform\Base\Supports\Database\Blueprint;

return new class extends Migration {
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::disableForeignKeyConstraints();
        if (Schema::hasTable('media_files')) {
            Schema::table('media_files', function (Blueprint $table) {
                $foreignKeys = $this->listTableForeignKeys('media_files');


                $indexes = $this->listTableIndexes('media_files');

                // if (in_array('plans_slug_unique', $indexes)) $table->dropIndex('plans_slug_unique');

                if (!Schema::hasColumn('media_files', 'visibility')) {
                    $table->char('visibility', 191)->nullable(true);
                }
            });
        }
        Schema::enableForeignKeyConstraints();
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down() {}

    protected function listTableIndexes($table)
    {
        $db = DB::getDatabaseName();
        $result = DB::select("SHOW INDEX FROM `{$table}` FROM `{$db}`");

        return collect($result)->pluck('Key_name')->unique()->values()->toArray();
    }

    protected function listTableForeignKeys($table)
    {
        $db = DB::getDatabaseName();
        $result = DB::select("
            SELECT CONSTRAINT_NAME
            FROM information_schema.KEY_COLUMN_USAGE
            WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND CONSTRAINT_NAME != 'PRIMARY'
        ", [$db, $table]);

        return collect($result)->pluck('CONSTRAINT_NAME')->unique()->values()->toArray();
    }
};
