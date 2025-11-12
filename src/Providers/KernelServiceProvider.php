<?php

namespace Dev\Kernel\Providers;

use Illuminate\Support\Facades\Schema;
use Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull;

use Dev\Base\Supports\Helper;
use Dev\Base\Facades\EmailHandler;
use Illuminate\Support\ServiceProvider;
use Dev\Kernel\Traits\LoadAndPublishDataTrait;

class KernelServiceProvider extends ServiceProvider
{
    use LoadAndPublishDataTrait;

    /**
     * @throws BindingResolutionException
     */
    public function register(): void
    {
        // if (class_exists('ApiHelper')) {
        //     AliasLoader::getInstance()->alias('ApiHelper', ApiHelper::class);
        // }

        $this->app->booted(function () { // phải để trong booted để push với highest priority
            // TODO Auth::guard('your-guard')->guest(), it is always return true (guest) and can not use Auth::guard('your-guard')->user()
            // TODO added "StartSession Middleware" to fix the session store not set on REQUEST when you are using custom guard, it's very important

            // $this->app->make('router')->pushMiddlewareToGroup('api', \App\Http\Middleware\EncryptCookies::class);
            $this->app->make('router')->pushMiddlewareToGroup('api', \Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse::class);
            $this->app->make('router')->pushMiddlewareToGroup('api', \Illuminate\Session\Middleware\StartSession::class);
            $this->app->make('router')->pushMiddlewareToGroup('api', \Illuminate\View\Middleware\ShareErrorsFromSession::class);
        });

        $this->registerMiddlewares();

        Helper::autoload(__DIR__ . '/../../helpers');
    }

    public function boot(): void
    {
        Schema::defaultStringLength(191);

        $this->app->register(CommandServiceProvider::class);
        $this->app->register(EventServiceProvider::class);
        $this->app->register(HookServiceProvider::class);

        if (method_exists($this->app, 'scoped')) { // Laravel 8.x compatibility: Add scoped() method polyfill (Laravel 9.x+ feature)
            // This adds scoped() method to Application for compatibility with packages
            // that require Laravel 9.x+ (like javoscript/laravel-macroable-models)
            // $this->app->register(MacroServiceProvider::class, true);
        }

        $this
            ->setNamespace('kernel')
            ->loadMigrations()
            ->loadAndPublishConfigurations(['general', 'email'])
            ->loadAndPublishTranslations()
            ->loadMigrations()
            ->loadHelpers()
            ->loadAndPublishViews()
            ->loadRoutes(['web', 'api']);

        // $this->app['events']->listen(RouteMatched::class, function () {
        //     if (ApiHelper::enabled()) {
        //         $this->app['router']->pushMiddlewareToGroup('api', ForceJsonResponseMiddleware::class);
        //     }
        // });

        /* extend email template after CMS fully booted */
        $this->app->booted(function () {
            #region extend core to modify email template management in cms, do not remove or move these lines
            // EmailHandler::setPlatformPath('dev-extensions')->addTemplateSettings('kernel', config('kernel.kernel.email', []), 'kernel');
            // EmailHandler::setPlatformPath('dev');
            #endregion
        });
    }

    /**
     * Register the middlewares automatically.
     *
     * @return void
     */
    protected function registerMiddlewares()
    {
        $router = $this->app['router'];

        if (method_exists($router, 'middleware')) {
            $registerMethod = 'middleware';
        } elseif (method_exists($router, 'aliasMiddleware')) {
            $registerMethod = 'aliasMiddleware';
        } else {
            return;
        }

        $middlewares = [
            "app.middleware.empty-to-null" => ConvertEmptyStringsToNull::class
        ];

        foreach ($middlewares as $key => $class) {
            $router->$registerMethod($key, $class);
        }
    }
}
