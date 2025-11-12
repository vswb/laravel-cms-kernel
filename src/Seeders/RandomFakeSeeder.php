<?php

namespace Platform\Kernel\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Arr;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Hash;
use Datetime;
use Faker\Factory;

use Platform\Language\Repositories\Interfaces\LanguageInterface;
use Platform\Setting\Repositories\Interfaces\SettingInterface;

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
