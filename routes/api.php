<?php

/**
 * © 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Proprietary software developed and distributed by Visual Weber.
 * Use is permitted only under a valid license agreement.
 *
 * © 2026 CÔNG TY TNHH VISUAL WEBER. Bảo lưu mọi quyền.
 * Phần mềm độc quyền của Visual Weber, chỉ được sử dụng theo Hợp đồng cấp phép.
 */


use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Route;

#region General routes, customize routes. To avoid modification core platform
Route::group([
    'middleware' => [
        'app.middleware.empty-to-null'
    ],
    'prefix' => 'api/v1',
    'namespace' => 'Dev\Api\Http\Controllers',
    'as' => 'kernel.api.v1.'
], function () {
    #region Laravel CMS only — force-refresh all system URLs post-deployment


    Route::get('license/verify', function (): JsonResponse {
        return response()->json([
            'error' => false,
            'data' => null,
            'message' => 'The system is already running the latest version. For further assistance, please contact us at contact@visualweber.com or call +84 943 999 819',
        ]);
    })->name('license.verify');

    Route::get('license/check', function (): JsonResponse {
        return response()->json([
            'error' => false,
            'data' => null,
            'message' => 'The system is already running the latest version. For further assistance, please contact us at contact@visualweber.com or call +84 943 999 819',
        ]);
    })->name('license.check');

    Route::get('products', function (): JsonResponse {
        return response()->json([
            'error' => false,
            'data' => [],
            'message' => 'Success',
        ]);
    });

    Route::get('products/{id}', function (): JsonResponse {
        return response()->json([
            'error' => true,
            'message' => 'Product not found or marketplace is undergoing maintenance.',
        ]);
    });
    #endregion
});
#endregion

Route::group([
    'middleware' => [],
    'prefix' => 'api/v1',
    'namespace' => 'Dev\Kernel\Http\Controllers\API\v1',
    'as' => 'kernel.api.v1.'
], function () {
    Route::group(
        [
            'prefix' => 'test',
            'as' => 'test'
        ],
        function () {
            // Middleware test route - to verify middleware is working
            Route::get('middleware-check', [
                'as' => '.middleware-check',
                'uses' => 'KernelController@middlewareCheck',
            ]);
        }
    );
});
Route::group([
    'middleware' => [],
    'prefix' => 'api/v1',
    'namespace' => 'Dev\Kernel\Http\Controllers\API\v1',
    'as' => 'kernel.api.v1.'
], function () {
    Route::group(
        [
            'prefix' => 'cms',
            'as' => 'cms'
        ],
        function () {
            // Get and check active plugins
            Route::get('plugins/get-plugins', [
                'as' => '.get-plugins',
                'uses' => 'KernelController@getPlugins',
            ]);
        }
    );
});

Route::group([
    'prefix' => 'api',
    'namespace' => 'Dev\Kernel\Http\Controllers\API',
    'middleware' => [],
], function () {

});
