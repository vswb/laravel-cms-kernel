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
    #region Laravel CMS only — force-refresh all system URLs post-deployment
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
    })->name('license.check-update.get');

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
    'middleware' => ['api'],
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
    'middleware' => ['api'],
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
    'middleware' => ['api'],
], function () {
    if (config('core.base.general.is_license_server')) {
        Route::post('activate_license', 'LicenseServerController@activate');
        Route::post('verify_license', 'LicenseServerController@verify');
        Route::post('check_update', 'LicenseServerController@checkUpdate');
        Route::post('check_connection_ext', 'LicenseServerController@checkConnectionExt');
    }
});
