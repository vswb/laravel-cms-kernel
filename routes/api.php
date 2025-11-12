<?php

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Route;

#region General routes, customize routes. To avoice modification core platform
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
    Route::match(['GET', 'POST'], 'products/check-update', function (): JsonResponse {
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

    Route::group(['middleware' => ['auth:sanctum']], function () {
        Route::delete(
            'delete-account',
            [
                'as' => 'platform.package.api.delete-account',
                'uses' => 'ProfileController@deleteAccount'
            ]
        );
    });
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
            Route::get('test', [
                'as' => '.test',
                'uses' => 'KernelController@test',
            ]);

            Route::get('make-qrcode/{type?}', [
                'as' => '.make-qrcode',
                'uses' => 'KernelController@makeQrcode',
            ]);
            Route::get('plan/add-features-plan', [
                'as' => '.plan.add-features-plan',
                'uses' => 'KernelController@addFeaturesToPlan',
            ]);
            Route::get('plan/create-plan', [
                'as' => '.plan.create-plan',
                'uses' => 'KernelController@createPlan',
            ]);
            Route::get('plan/details/{id}', [
                'as' => '.plan.get-plan',
                'uses' => 'KernelController@getPlan',
            ]);
            Route::get('plan/details/{id}', [
                'as' => '.plan.change-plan',
                'uses' => 'KernelController@changePlan',
            ]);
            Route::get('plan/details/{id}', [
                'as' => '.plan.get-feature',
                'uses' => 'KernelController@getFeature',
            ]);
            Route::get('plan/create-subscription', [
                'as' => '.plan.create-subscription',
                'uses' => 'KernelController@createSubscription',
            ]);
        }
    );
});
