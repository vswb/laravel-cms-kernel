<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class() extends Migration {
    public function up(): void
    {
        if (is_plugin_active('location')) { // make sure plg location is active
            if (! Schema::hasTable('districts')) {
                Schema::create('districts', function (Blueprint $table) {
                    $table->id();
                    $table->string('name', 120);
                    $table->string('code', 120)->nullable();
                    $table->string('type', 120)->nullable()->comment('Thành phố/Huyện/Thị xã');
                    $table->foreignId('city_id');
                    $table->string('record_id', 40)->nullable();
                    $table->tinyInteger('order')->default(0);
                    $table->tinyInteger('is_default')->unsigned()->default(0);
                    $table->string('status', 60)->default('published');
                    $table->timestamps();
                });
            }

            if (! Schema::hasTable('wards')) {
                Schema::create('wards', function (Blueprint $table) {
                    $table->id();
                    $table->string('name', 120);
                    $table->string('code', 120)->nullable();
                    $table->string('type', 120)->nullable()->comment('Phường/Xã/Thị trấn');
                    $table->foreignId('district_id');
                    $table->string('record_id', 40)->nullable();
                    $table->tinyInteger('order')->default(0);
                    $table->tinyInteger('is_default')->unsigned()->default(0);
                    $table->string('status', 60)->default('published');
                    $table->timestamps();
                });
            }

            if (! Schema::hasColumn('cities', 'code')) {
                Schema::table('cities', function (Blueprint $table) {
                    $table->string('code', 30)->unique()->after('name')->nullable();
                });
            }
            if (! Schema::hasColumn('cities', 'type')) {
                Schema::table('cities', function (Blueprint $table) {
                    $table->string('type', 30)->nullable()->comment('Thành phố Trung ương/Tỉnh');
                });
            }

            if (! Schema::hasColumn('states', 'code')) {
                Schema::table('states', function (Blueprint $table) {
                    $table->string('code', 30)->unique()->after('name')->nullable();
                });
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('wards');
    }
};
