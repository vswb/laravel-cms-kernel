<?php

namespace Platform\Kernel\Providers;

// use Illuminate\Support\Facades\Schema;
// use Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull;

// use Platform\Base\Supports\Helper;
// use Platform\Base\Facades\EmailHandler;
use Illuminate\Support\ServiceProvider;
// use Platform\Kernel\Traits\LoadAndPublishDataTrait;

class KernelServiceProvider extends ServiceProvider
{
    // use LoadAndPublishDataTrait; // Temporarily removed to isolate redirect issue

    /**
     * @throws BindingResolutionException
     */
    public function register(): void
    {
        // MINIMAL VERSION: All code commented out to prevent redirect loops
        // Uncomment sections below only after verifying they don't cause issues
        
        // $this->app['config']->set([...]);
        // if (class_exists('ApiHelper')) { ... }
        // $this->app->booted(function () { ... });
        // $this->app->singleton(ExceptionHandler::class, Handler::class);
        // $this->registerMiddlewares();
        // Helper::autoload(__DIR__ . '/../../helpers');
    }

    public function boot(): void
    {
        // MINIMAL VERSION: All code commented out to prevent redirect loops
        // Uncomment sections below only after verifying they don't cause issues
        
        // Schema::defaultStringLength(191);
        // $this->app->register(CommandServiceProvider::class);
        // $this->app->register(EventServiceProvider::class);
        // $this->app->register(HookServiceProvider::class);
        // if (method_exists($this->app, 'scoped')) { ... }
        // $this->setNamespace('kernel')->loadMigrations()...->loadRoutes(['web', 'api']);
        // $this->app['events']->listen(RouteMatched::class, function () { ... });
        // $this->app->booted(function () { ... });
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
