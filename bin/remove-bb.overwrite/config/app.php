<?php

use Illuminate\Support\Facades\Facade;
use Illuminate\Support\ServiceProvider;

return [

    /*
    |--------------------------------------------------------------------------
    | Application Name
    |--------------------------------------------------------------------------
    |
    | This value is the name of your application, which will be used when the
    | framework needs to place the application's name in a notification or
    | other UI elements where an application name needs to be displayed.
    |
    */

    'name' => env('APP_NAME', 'Laravel'),

    /*
    |--------------------------------------------------------------------------
    | Application Environment
    |--------------------------------------------------------------------------
    |
    | This value determines the "environment" your application is currently
    | running in. This may determine how you prefer to configure various
    | services the application utilizes. Set this in your ".env" file.
    |
    */

    'env' => env('APP_ENV', 'production'),

    /*
    |--------------------------------------------------------------------------
    | Application Debug Mode
    |--------------------------------------------------------------------------
    |
    | When your application is in debug mode, detailed error messages with
    | stack traces will be shown on every error that occurs within your
    | application. If disabled, a simple generic error page is shown.
    |
    */

    'debug' => (bool) env('APP_DEBUG', false),
    'debug_blacklist' => [
        '_ENV' => [
            'DB_CONNECTION',
            'DB_HOST',
            'DB_PORT',
            'DB_DATABASE',
            'DB_USERNAME',
            'DB_PASSWORD',
            'BROADCAST_DRIVER',
            'CACHE_DRIVER',
            'QUEUE_CONNECTION',
            'SESSION_DRIVER',
            'SESSION_LIFETIME',
            'QUEUE_DRIVER',
            'REDIS_HOST',
            'REDIS_PASSWORD',
            'REDIS_PORT',
            'MAIL_DRIVER',
            'MAIL_HOST',
            'MAIL_PORT',
            'MAIL_FROM_NAME',
            'MAIL_FROM_ADDRESS',
            'MAIL_USERNAME',
            'MAIL_PASSWORD',
            'MAIL_ENCRYPTION',
            'MAILGUN_DOMAIN',
            'MAILGUN_SECRET',
            'PUSHER_APP_CLUSTER',
            'JWT_TTL',
            'JWT_SECRET',
            'ONESIGNAL',
            'REST_API_KEY',
            'FACEBOOK_ID',
            'FACEBOOK_SECRET',
            'FACEBOOK_REDIRECT',
            'GOOGLE_ID',
            'GOOGLE_SECRET',
            'SENTRY_LARAVEL_DSN',
            'FFMPEG_BINARIES',
            'FFPROBE_BINARIES',
            'NOCAPTCHA_SECRET',
            'NOCAPTCHA_SITEKEY',
            'ELASTIC_HOST',
            'ELASTIC_PORT',
            'ELASTIC_CONNECTION',
            'ELASTIC_SCHEME',
            'ELASTIC_INDEX',
            'VNP_TMNCODE',
            'VNP_SECRET',
            'VNP_URL_CALLBACK',
            'GOOGLE_MAP_API',
            'MIX_PREFIX_DOMAIN_STORE',
            'MIX_SUB_DOMAIN_STORE',
            'MIX_PREFIX_DOMAIN_COMPANY',
            'MIX_SUB_DOMAIN_COMPANY',
            'MIX_PREFIX_DOMAIN_BUSINESS',
            'MIX_SUB_DOMAIN_BUSINESS',
            'FILESYSTEM_DRIVER',
            'GOOGLE_CLOUD_PROJECT_ID',
            'GOOGLE_CLOUD_STORAGE_BUCKET',
            'GOOGLE_CLOUD_STORAGE_API_URI',
            'DB_HOST_B',
            'DB_PORT_B',
            'DB_DATABASE_B',
            'DB_USERNAME_B',
            'DB_PASSWORD_B',
            'DB_CONNECTION_C',
            'DB_HOST_C',
            'DB_PORT_C',
            'DB_DATABASE_C',
            'DB_USERNAME_C',
            'DB_PASSWORD_C',
            'ADMIN_DIR',
            'PUSHER_APP_CLUSTER',
            'PUSHER_APP_ID',
            'PUSHER_APP_SECRET',
            'PUSHER_APP_KEY',
            'DEBUGBAR_ENABLED',
            'MIX_PUSHER_APP_KEY',
            'MIX_PUSHER_APP_CLUSTER',
            'FACEBOOK_APP_ID',
            'FACEBOOK_APP_SECRET',
            'FACEBOOK_CLIENT_TOKEN',
            'FACEBOOK_APP_CALLBACK_URL',
            'FACEBOOK_GRAPH_VERSION',
            'GITHUB_APP_ID',
            'GITHUB_APP_SECRET',
            'GITHUB_APP_CALLBACK_URL',
            'TWITTER_APP_ID',
            'TWITTER_APP_SECRET',
            'TWITTER_APP_CALLBACK_URL',
            'GOOGLE_APPLICATION_NAME',
            'GOOGLE_CLIENT_ID',
            'GOOGLE_CLIENT_SECRET',
            'GOOGLE_REDIRECT',
            'GOOGLE_CALLBACK_URL',
            'GOOGLE_DEVELOPER_KEY',
            'GOOGLE_SERVICE_ENABLED',
            'GOOGLE_SERVICE_ACCOUNT_JSON_LOCATION',
            'GOOGLE_DRIVE_CLIENT_ID',
            'GOOGLE_DRIVE_CLIENT_SECRET',
            'GOOGLE_DRIVE_ACCESS_TOKEN',
            'GOOGLE_DRIVE_REFRESH_TOKEN',
            'GOOGLE_DRIVE_TEAM_DRIVE_ID',
            'TELEGRAM_BOT_TOKEN',
            'TELEGRAM_BOT_NAME',
            'TELEGRAM_BASE_URI',
            'TELEGRAM_WEBHOOK_URL',
            'TELEGRAM_CERTIFICATE_PATH',
            'TELEGRAM_CHANNEL_NAME',
            'TELEGRAM_EXCEPTION_NOTIFY',
            'TELEGRAM_NOTIFY_ENABLE',
            'TELEGRAM_ASYNC_REQUESTS',
            'MAUTIC_BASE_URL',
            'MAUTIC_BASE_URL_API',
            'MAUTIC_PUBLIC_KEY',
            'MAUTIC_SECRET_KEY',
            'MAUTIC_REDIRECT',
            'TMV_USERNAME',
            'TMV_PASSWORD',
            'TIKTOK_AD_APP_ID',
            'TIKTOK_AD_APP_SECRET',
            'TIKTOK_AD_ENDPOINT',
            'TIKTOK_AD_PERM_URL',
            'TIKTOK_AD_CALLBACK_URL',
            'TIKTOK_AD_WEBHOOK_URL',
            'TIKTOK_APP_ID',
            'TIKTOK_CLIENT_ID',
            'TIKTOK_CLIENT_KEY',
            'TIKTOK_CLIENT_SECRET',
            'TIKTOK_REDIRECT',
            'ZALO_OA_ID',
            'ZALO_OA_SECRET',
            'ZALO_OA_ENDPOINT',
            'ZALO_OA_OPENAPI_ENDPOINT',
            'ZALO_OA_PERM_URL',
            'ZALO_OA_CALLBACK_URL',
            'ZALO_CLIENT_ID',
            'ZALO_CLIENT_SECRET',
            'ZALO_REDIRECT'
        ],
        '_SERVER' => [
            'DB_CONNECTION',
            'DB_HOST',
            'DB_PORT',
            'DB_DATABASE',
            'DB_USERNAME',
            'DB_PASSWORD',
            'BROADCAST_DRIVER',
            'CACHE_DRIVER',
            'QUEUE_CONNECTION',
            'SESSION_DRIVER',
            'SESSION_LIFETIME',
            'QUEUE_DRIVER',
            'REDIS_HOST',
            'REDIS_PASSWORD',
            'REDIS_PORT',
            'MAIL_DRIVER',
            'MAIL_HOST',
            'MAIL_PORT',
            'MAIL_FROM_NAME',
            'MAIL_FROM_ADDRESS',
            'MAIL_USERNAME',
            'MAIL_PASSWORD',
            'MAIL_ENCRYPTION',
            'MAILGUN_DOMAIN',
            'MAILGUN_SECRET',
            'PUSHER_APP_CLUSTER',
            'JWT_TTL',
            'JWT_SECRET',
            'ONESIGNAL',
            'REST_API_KEY',
            'FACEBOOK_APP_ID',
            'FACEBOOK_APP_SECRET',
            'FACEBOOK_CLIENT_TOKEN',
            'FACEBOOK_APP_CALLBACK_URL',
            'FACEBOOK_GRAPH_VERSION',
            'GOOGLE_ID',
            'GOOGLE_SECRET',
            'SENTRY_LARAVEL_DSN',
            'FFMPEG_BINARIES',
            'FFPROBE_BINARIES',
            'NOCAPTCHA_SECRET',
            'NOCAPTCHA_SITEKEY',
            'ELASTIC_HOST',
            'ELASTIC_PORT',
            'ELASTIC_CONNECTION',
            'ELASTIC_SCHEME',
            'ELASTIC_INDEX',
            'VNP_TMNCODE',
            'VNP_SECRET',
            'VNP_URL_CALLBACK',
            'GOOGLE_MAP_API',
            'MIX_PREFIX_DOMAIN_STORE',
            'MIX_SUB_DOMAIN_STORE',
            'MIX_PREFIX_DOMAIN_COMPANY',
            'MIX_SUB_DOMAIN_COMPANY',
            'MIX_PREFIX_DOMAIN_BUSINESS',
            'MIX_SUB_DOMAIN_BUSINESS',
            'FILESYSTEM_DRIVER',
            'GOOGLE_CLOUD_PROJECT_ID',
            'GOOGLE_CLOUD_STORAGE_BUCKET',
            'GOOGLE_CLOUD_STORAGE_API_URI',
            'DB_HOST_B',
            'DB_PORT_B',
            'DB_DATABASE_B',
            'DB_USERNAME_B',
            'DB_PASSWORD_B',
            'DB_CONNECTION_C',
            'DB_HOST_C',
            'DB_PORT_C',
            'DB_DATABASE_C',
            'DB_USERNAME_C',
            'DB_PASSWORD_C',
            'ADMIN_DIR',
            'PUSHER_APP_CLUSTER',
            'PUSHER_APP_ID',
            'PUSHER_APP_SECRET',
            'PUSHER_APP_KEY',
            'DEBUGBAR_ENABLED',
            'MIX_PUSHER_APP_KEY',
            'MIX_PUSHER_APP_CLUSTER',
            'FACEBOOK_APP_ID',
            'FACEBOOK_APP_SECRET',
            'FACEBOOK_APP_CALLBACK_URL',
            'FACEBOOK_GRAPH_VERSION',
            'GITHUB_APP_ID',
            'GITHUB_APP_SECRET',
            'GITHUB_APP_CALLBACK_URL',
            'TWITTER_APP_ID',
            'TWITTER_APP_SECRET',
            'TWITTER_APP_CALLBACK_URL',
            'FILESYSTEM_CLOUD',
            'GOOGLE_APPLICATION_NAME',
            'GOOGLE_CLIENT_ID',
            'GOOGLE_CLIENT_SECRET',
            'GOOGLE_REDIRECT',
            'GOOGLE_CALLBACK_URL',
            'GOOGLE_DEVELOPER_KEY',
            'GOOGLE_SERVICE_ENABLED',
            'GOOGLE_SERVICE_ACCOUNT_JSON_LOCATION',
            'GOOGLE_DRIVE_CLIENT_ID',
            'GOOGLE_DRIVE_CLIENT_SECRET',
            'GOOGLE_DRIVE_ACCESS_TOKEN',
            'GOOGLE_DRIVE_REFRESH_TOKEN',
            'GOOGLE_DRIVE_TEAM_DRIVE_ID',
            'TELEGRAM_BOT_TOKEN',
            'TELEGRAM_BOT_NAME',
            'TELEGRAM_BASE_URI',
            'TELEGRAM_WEBHOOK_URL',
            'TELEGRAM_CERTIFICATE_PATH',
            'TELEGRAM_CHANNEL_NAME',
            'TELEGRAM_EXCEPTION_NOTIFY',
            'TELEGRAM_NOTIFY_ENABLE',
            'TELEGRAM_ASYNC_REQUESTS',
            'MAUTIC_BASE_URL',
            'MAUTIC_BASE_URL_API',
            'MAUTIC_PUBLIC_KEY',
            'MAUTIC_SECRET_KEY',
            'MAUTIC_REDIRECT',
            'TMV_USERNAME',
            'TMV_PASSWORD',
            'TIKTOK_AD_APP_ID',
            'TIKTOK_AD_APP_SECRET',
            'TIKTOK_AD_ENDPOINT',
            'TIKTOK_AD_PERM_URL',
            'TIKTOK_AD_CALLBACK_URL',
            'TIKTOK_AD_WEBHOOK_URL',
            'TIKTOK_APP_ID',
            'TIKTOK_CLIENT_ID',
            'TIKTOK_CLIENT_KEY',
            'TIKTOK_CLIENT_SECRET',
            'TIKTOK_REDIRECT',
            'ZALO_OA_ID',
            'ZALO_OA_SECRET',
            'ZALO_OA_ENDPOINT',
            'ZALO_OA_OPENAPI_ENDPOINT',
            'ZALO_OA_PERM_URL',
            'ZALO_OA_CALLBACK_URL',
            'ZALO_CLIENT_ID',
            'ZALO_CLIENT_SECRET',
            'ZALO_REDIRECT'
        ],
        '_POST' => [
            'password',
        ],
    ],
    /*
    |--------------------------------------------------------------------------
    | Application URL
    |--------------------------------------------------------------------------
    |
    | This URL is used by the console to properly generate URLs when using
    | the Artisan command line tool. You should set this to the root of
    | the application so that it's available within Artisan commands.
    |
    */

    'url' => env('APP_URL', 'http://localhost'),

    'asset_url' => env('ASSET_URL'),

    /*
    |--------------------------------------------------------------------------
    | Application Timezone
    |--------------------------------------------------------------------------
    |
    | Here you may specify the default timezone for your application, which
    | will be used by the PHP date and date-time functions. The timezone
    | is set to "UTC" by default as it is suitable for most use cases.
    |
    */

    'timezone' => env('APP_TIMEZONE', 'UTC'),

    /*
    |--------------------------------------------------------------------------
    | Application Locale Configuration
    |--------------------------------------------------------------------------
    |
    | The application locale determines the default locale that will be used
    | by Laravel's translation / localization methods. This option can be
    | set to any locale for which you plan to have translation strings.
    |
    */

    'locale' => env('APP_LOCALE', 'en'),

    'fallback_locale' => env('APP_FALLBACK_LOCALE', 'en'),

    'faker_locale' => env('APP_FAKER_LOCALE', 'en_US'),

    /*
    |--------------------------------------------------------------------------
    | Encryption Key
    |--------------------------------------------------------------------------
    |
    | This key is utilized by Laravel's encryption services and should be set
    | to a random, 32 character string to ensure that all encrypted values
    | are secure. You should do this prior to deploying the application.
    |
    */

    'cipher' => 'AES-256-CBC',

    'key' => env('APP_KEY'),

    'previous_keys' => [
        ...array_filter(
            explode(',', env('APP_PREVIOUS_KEYS', ''))
        ),
    ],

    /*
    |--------------------------------------------------------------------------
    | Maintenance Mode Driver
    |--------------------------------------------------------------------------
    |
    | These configuration options determine the driver used to determine and
    | manage Laravel's "maintenance mode" status. The "cache" driver will
    | allow maintenance mode to be controlled across multiple machines.
    |
    | Supported drivers: "file", "cache"
    |
    */

    'maintenance' => [
        'driver' => env('APP_MAINTENANCE_DRIVER', 'file'),
        'store' => env('APP_MAINTENANCE_STORE', 'database'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Autoloaded Service Providers
    |--------------------------------------------------------------------------
    |
    | The service providers listed here will be automatically loaded on the
    | request to your application. Feel free to add your own services to
    | this array to grant expanded functionality to your applications.
    |
    */

    'providers' => ServiceProvider::defaultProviders()->merge([
        /*
         * Package Service Providers...
         */

        /*
         * Application Service Providers...
         */
        App\Providers\AppServiceProvider::class,
        App\Providers\AuthServiceProvider::class,
        App\Providers\BroadcastServiceProvider::class,
        App\Providers\EventServiceProvider::class,
        App\Providers\RouteServiceProvider::class,
    ])->toArray(),

    /*
    |--------------------------------------------------------------------------
    | Class Aliases
    |--------------------------------------------------------------------------
    |
    | This array of class aliases will be registered when this application
    | is started. However, feel free to register as many as you wish as
    | the aliases are "lazy" loaded so they don't hinder performance.
    |
    */

    'aliases' => Facade::defaultAliases()->merge([
        // 'Example' => App\Facades\Example::class,
    ])->toArray(),

];
