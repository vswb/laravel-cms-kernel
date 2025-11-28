<?php

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Route;

#region General routes, customize routes. To avoid modification core platform
Route::group([
    'middleware' => [
        'app.middleware.empty-to-null',
        'api'
    ],
    'prefix' => 'api/v1',
    'namespace' => 'Dev\Api\Http\Controllers',
    'as' => 'kernel.api.v1.'
], function () {
    #region for laravel cms platform only: force update url cho toàn bộ hệ thống mã nguồn cms sau khi triển khai
    Route::post('products/check-update', function (): JsonResponse {
        return response()->json([
            'error' => false,
            'data' => null,
            'message' => 'The system is already running the latest version. For further assistance, please contact us at toan@visualweber.com or call +84 943 999 819',
        ]);
    })->name('license.check-update');
    Route::get('products/check-update', function (): JsonResponse {
        return response()->json([
            'error' => false,
            'data' => null,
            'message' => 'The system is already running the latest version. For further assistance, please contact us at toan@visualweber.com or call +84 943 999 819',
        ]);
    })->name('license.check-update');
    
    Route::get('license/verify', function (): JsonResponse {
        return response()->json([
            'error' => false,
            'data' => null,
            'message' => 'The system is already running the latest version. For further assistance, please contact us at toan@visualweber.com or call +84 943 999 819',
        ]);
    })->name('license.verify');

    Route::get('license/check', function (): JsonResponse {
        return response()->json([
            'error' => false,
            'data' => null,
            'message' => 'The system is already running the latest version. For further assistance, please contact us at toan@visualweber.com or call +84 943 999 819',
        ]);
    })->name('license.check');
    #endregion
});
#endregion General routes, customize routes. To avoice modification core platform

Route::group([
    'middleware' => ['api'],
    'prefix'    => 'api/v1',
    'namespace' => 'Dev\Kernel\Http\Controllers\API\v1',
    'as' => 'kernel.api.v1.'
], function () {
    Route::group(
        [
            'prefix' => 'test',
            'as' => 'test'
        ],
        function () {
            // Middleware test route - để verify middleware hoạt động
            Route::get('middleware-check', [
                'as' => '.middleware-check',
                'uses' => 'KernelController@middlewareCheck',
            ]);
        }
    );
});
