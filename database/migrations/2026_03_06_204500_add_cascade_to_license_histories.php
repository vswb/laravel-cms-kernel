<?php

use Illuminate\Database\Migrations\Migration;
use Dev\Base\Supports\Database\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // First, ensure all license_id exist in licenses table to avoid FK error
        DB::table('license_histories')->whereNotExists(function ($query) {
            $query->select(DB::raw(1))
                  ->from('licenses')
                  ->whereRaw('licenses.id = license_histories.license_id');
        })->delete();

        Schema::table('license_histories', function (Blueprint $table) {
            // Check if column exists (it should)
            if (Schema::hasColumn('license_histories', 'license_id')) {
                // We need to change the column type to match licenses.id (char 36)
                // and add the foreign key.
                $table->char('license_id', 36)->nullable()->change();
                
                $table->foreign('license_id')
                      ->references('id')
                      ->on('licenses')
                      ->onDelete('cascade');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('license_histories', function (Blueprint $table) {
            $table->dropForeign(['license_id']);
        });
    }
};
