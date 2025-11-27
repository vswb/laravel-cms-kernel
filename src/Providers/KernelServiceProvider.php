<?php

namespace Dev\Kernel\Providers;

use Illuminate\Support\Facades\Schema;
use Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull;

use Dev\Base\Supports\Helper;
use Dev\Base\Facades\EmailHandler;
use Dev\Base\Supports\ServiceProvider;
use Dev\Kernel\Traits\LoadAndPublishDataTrait;

class KernelServiceProvider extends ServiceProvider
{
    use LoadAndPublishDataTrait;

    /**
     * @throws BindingResolutionException
     */
    public function register(): void
    {
        // $this->app['config']->set([
        //     'scribe.routes.0.match.prefixes' => ['api/*'],
        //     'scribe.routes.0.apply.headers' => [
        //         'Authorization' => 'Bearer {token}',
        //         'Api-Version' => 'v1',
        //     ],
        // ]);

        // if (class_exists('ApiHelper')) {
        //     AliasLoader::getInstance()->alias('ApiHelper', ApiHelper::class);
        // }

        $this->app->booted(function () {
            // Phải để trong booted để push với highest priority
            // TODO Auth::guard('your-guard')->guest(), it is always return true (guest) and can not use Auth::guard('your-guard')->user()
            // TODO added "StartSession Middleware" to fix the session store not set on REQUEST when you are using custom guard, it's very important

            $router = $this->app->make('router');

            // Thứ tự middleware theo Laravel standard:
            // 1. TrustHosts - Phải đầu tiên (validate host trước khi xử lý request)
            $router->pushMiddlewareToGroup('api', \Dev\Kernel\Http\Middleware\TrustHosts::class);
            
            // 2. TrustProxies - Phải sớm (để biết real IP của client)
            $router->pushMiddlewareToGroup('api', \Dev\Kernel\Http\Middleware\TrustProxies::class);
            
            // 3. EncryptCookies - Trước AddQueuedCookies
            $router->pushMiddlewareToGroup('api', \Dev\Kernel\Http\Middleware\EncryptCookies::class);
            
            // 4. AddQueuedCookiesToResponse - Sau EncryptCookies
            $router->pushMiddlewareToGroup('api', \Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse::class);
            
            // 5. StartSession - Trước ShareErrors
            $router->pushMiddlewareToGroup('api', \Illuminate\Session\Middleware\StartSession::class);
            
            // 6. ShareErrorsFromSession - Sau StartSession
            $router->pushMiddlewareToGroup('api', \Illuminate\View\Middleware\ShareErrorsFromSession::class);
            
            // 7. TrimStrings - Trim input data
            $router->pushMiddlewareToGroup('api', \Dev\Kernel\Http\Middleware\TrimStrings::class);
            
            // 8. ValidateSignature - Validate signed URLs
            $router->pushMiddlewareToGroup('api', \Dev\Kernel\Http\Middleware\ValidateSignature::class);
            
            // 9. VerifyCsrfToken - CSRF protection (thường không cần cho API, nhưng giữ lại nếu cần)
            // Note: Nếu API dùng token-based auth, có thể exclude trong VerifyCsrfToken::$except
            $router->pushMiddlewareToGroup('api', \Dev\Kernel\Http\Middleware\VerifyCsrfToken::class);
            
            // 10. SecurityHeaders - Response headers (cuối cùng)
            $router->pushMiddlewareToGroup('api', \Dev\Kernel\Http\Middleware\SecurityHeaders::class);
        });

        // $this->app->singleton(ExceptionHandler::class, Handler::class); // không binding được vì thứ tự chạy trước, nên bị chạy sau đè lên Dev\Base\Providers\BaseServiceProvider

        $this->registerMiddlewares();

        Helper::autoload(__DIR__ . '/../../helpers');
    }

    public function boot(): void
    {
        Schema::defaultStringLength(191);

        $this->app->register(CommandServiceProvider::class);
        $this->app->register(EventServiceProvider::class);
        $this->app->register(HookServiceProvider::class);
        $this->app->register(MacroServiceProvider::class, true);

        $this
            ->setNamespace('kernel/kernel')
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
            EmailHandler::setPlatformPath('dev-extensions')->addTemplateSettings('kernel', config('kernel.kernel.email', []), 'kernel');
            EmailHandler::setPlatformPath('dev');
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
