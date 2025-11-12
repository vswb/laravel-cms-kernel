<?php

namespace Platform\Kernel\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
/**
 * Usage: php artisan db:seed --class=\\Platform\\Kernel\\Seeders\\RandomFakeSeeder
 * 
 */
class RandomFakeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        Schema::disableForeignKeyConstraints();

        if (file_exists(base_path('scripts/update_random_data.sql'))) {
            DB::unprepared(file_get_contents('scripts/update_random_data.sql'));
        }

        Schema::enableForeignKeyConstraints();
    }
}
