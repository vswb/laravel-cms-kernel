<?php
/**
 * (c) Copyright 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Distributed by: VISUAL WEBER CO., LTD.
 * * [PRODUCT INFORMATION]
 * This software is a proprietary product developed by Visual Weber.
 * All rights to the software and its components are reserved under 
 * Intellectual Property laws.
 * * [TERMS OF USE]
 * Usage is permitted strictly according to the License Agreement 
 * between Visual Weber and the Client.
 * -------------------------------------------------------------------------
 * (c) Bản quyền thuộc về CÔNG TY TNHH VISUAL WEBER 2026. Bảo lưu mọi quyền.
 * Phát hành bởi: Công ty TNHH Visual Weber.
 * * [THÔNG TIN SẢN PHẨM]
 * Phần mềm này là sản phẩm độc quyền được phát triển bởi Visual Weber.
 * Mọi quyền đối với phần mềm và các thành phần cấu thành đều được bảo hộ 
 * theo luật Sở hữu trí tuệ.
 * * [ĐIỀU KHOẢN SỬ DỤNG]
 * Việc sử dụng được giới hạn nghiêm ngặt theo Hợp đồng cung cấp dịch vụ/phần mềm 
 * giữa Visual Weber và Khách hàng.
 */


namespace Dev\Kernel\Providers;

use Illuminate\Support\Str;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\ServiceProvider;
use Illuminate\Database\Eloquent\Builder as EloquentBuilder;
use Illuminate\Support\Collection;
class MacroServiceProvider extends ServiceProvider
{
    /**
     * Bootstrap services.
     *
     * @return void
     */
    public function boot()
    {
        #region Macro 1 show FULL sql
        /**
         * Macro 1 show FULL sql
         * 
         * usage: 
         * DB::table('table-name')->toBoundSql();
         * // result: ['name' => 'Chris']
         * 
         */
        Builder::macro('toBoundSql', function () {
            /* @var Builder $this */
            $bindings = array_map(
                fn($parameter) => is_string($parameter) ? "'$parameter'" : $parameter,
                $this->getBindings()
            );

            return Str::replaceArray(
                '?',
                $bindings,
                $this->toSql()
            );
        });
        EloquentBuilder::macro('toBoundSql', function () {
            return $this->toBase()->toBoundSql();
        });
        #endregion

        #region Macro 2 for case insensitive 'where' filter
        /**
         * Macro 2 for case insensitive 'where' filter
         * 
         * $collection = collect([
         *   [
         *      'name' => 'Chris'
         *   ],
         *   [
         *      'name' => 'Monica'
         *   ]
         * ]);
         * 
         * $collection->where('name', 'chris');
         * // result: null
         * 
         * If you want a case insensitive 'where' filter, 
         * add this to your AppServiceProvider's boot method
         *
         * usage: 
         * $collection->whereCaseInsensitive('name', 'chris');
         * // result: ['name' => 'Chris']
         *
         */

        Collection::macro('whereCaseInsensitive', function (string $field, string $search) {
            return $this->filter(function ($item) use ($field, $search) {
                return strtolower($item[$field]) == strtolower($search);
            });
        });
        #endregion
    }
}
