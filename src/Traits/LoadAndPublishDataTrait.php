<?php
namespace Dev\Kernel\Traits;

use Dev\Base\Supports\Helper;
use Dev\Base\Supports\ServiceProvider;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;
use ReflectionClass;
use Exception;

/**
 * @mixin ServiceProvider
 */
trait LoadAndPublishDataTrait
{
    /**
     * @var string
     */
    protected $namespace = null;

    /**
     * @var string
     */
    protected $basePath = null;

    /**
     * @param string $namespace
     * @return $this
     */
    public function setNamespace(string $namespace): self
    {
        $this->namespace = ltrim(rtrim($namespace, '/'), '/');
        // Reset cached base path when namespace changes
        $this->basePath = null;

        return $this;
    }

    protected function getPath(?string $path = null): string
    {
        // Cache base path to avoid recalculating
        if ($this->basePath === null) {
            $reflection = new ReflectionClass($this);
            $modulePath = str_replace('/src/Providers', '', File::dirname($reflection->getFilename()));

            $baseExtensionsPath = base_path('dev-extensions');
            $baseVendorPath = base_path('vendor/dev-extensions');

            // Hỗ trợ cả 3 trường hợp:
            // 1. Local development: dev-extensions/libs/thumbnail-generator
            // 2. Local development: dev-extensions/packages/thumbnail-generator
            // 3. Composer package: vendor/dev-extensions/thumbnail-generator
            
            $isLocalDev = Str::contains($modulePath, $baseExtensionsPath . '/libs') ||
                          Str::contains($modulePath, $baseExtensionsPath . '/packages');
            $isVendorPackage = Str::contains($modulePath, $baseVendorPath);

            // Nếu đã là local dev hoặc vendor package, dùng luôn
            if ($isLocalDev || $isVendorPackage) {
                $this->basePath = $modulePath;
            } else {
                // Try to locate in packages or libs (only check if needed)
                $dashedNamespace = $this->getDashedNamespace();
                $searchPaths = [
                    $baseExtensionsPath . '/packages/' . $dashedNamespace,
                    $baseExtensionsPath . '/libs/' . $dashedNamespace,
                ];

                foreach ($searchPaths as $searchPath) {
                    if (File::exists($searchPath)) {
                        $this->basePath = $searchPath;
                        break;
                    }
                }

                // Fallback to default if not found
                if ($this->basePath === null) {
                    $this->basePath = $baseExtensionsPath . '/' . $dashedNamespace;
                }
            }
        }

        return $this->basePath . ($path ? '/' . ltrim($path, '/') : '');
    }

    /**
     * Publish the given configuration file name (without extension) and the given module
     * @param array|string $fileNames
     * @return $this
     */
    protected function loadAndPublishConfigurations($fileNames): self
    {
        if (!is_array($fileNames)) {
            $fileNames = [$fileNames];
        }
        foreach ($fileNames as $fileName) {
            $this->mergeConfigFrom($this->getConfigFilePath($fileName), $this->getDotedNamespace() . '.' . $fileName);
            if (app()->runningInConsole()) {
                $this->publishes([
                    $this->getConfigFilePath($fileName) => config_path($this->getDashedNamespace() . '/' . $fileName . '.php'),
                ], 'cms-config');
            }
        }

        return $this;
    }

    /**
     * Get path of the give file name in the given module
     * @param string $file
     * @return string
     * @throws Exception
     */
    protected function getConfigFilePath(string $file): string
    {
        return $this->getPath('config/' . $file . '.php');
    }

    /**
     * @return string
     */
    protected function getDashedNamespace(): string
    {
        return str_replace('.', '/', $this->namespace);
    }

    /**
     * @return string
     */
    protected function getDotedNamespace(): string
    {
        return str_replace('/', '.', $this->namespace);
    }

    /**
     * Publish the given configuration file name (without extension) and the given module
     * @param array|string $fileNames
     * @return $this
     */
    protected function loadRoutes(array|string $fileNames = ['web']): static
    {
        if (! is_array($fileNames)) {
            $fileNames = [$fileNames];
        }

        foreach ($fileNames as $fileName) {
            $filePath = $this->getRouteFilePath($fileName);

            if ($filePath) {
                $this->loadRoutesFrom($filePath);
            }
        }

        return $this;
    }

    /**
     * @param string $file
     * @return string
     */
    protected function getRouteFilePath($file): string
    {
        return $this->getPath('routes/' . $file . '.php');
    }

    /**
     * @return $this
     */
    protected function loadAndPublishViews(): static
    {
        $this->loadViewsFrom($this->getViewsPath(), $this->getDashedNamespace());
        if ($this->app->runningInConsole()) {
            $this->publishes(
                [$this->getViewsPath() => resource_path('views/vendor/' . $this->getDashedNamespace())],
                'cms-views'
            );
        }

        return $this;
    }

    protected function getViewsPath(): string
    {
        return $this->getPath('/resources/views');
    }

    /**
     * @return $this
     */
    protected function loadAndPublishTranslations(): self
    {
        $this->loadTranslationsFrom($this->getTranslationsPath(), $this->getDashedNamespace());
        $this->publishes(
            [$this->getTranslationsPath() => lang_path('vendor/' . $this->getDashedNamespace())],
            'cms-lang'
        );

        return $this;
    }

    protected function getTranslationsPath(): string
    {
        return $this->getPath('/resources/lang');
    }

    /**
     * @return $this
     */
    protected function loadMigrations(): self
    {
        $this->loadMigrationsFrom($this->getMigrationsPath());

        return $this;
    }

    /**
     * @return string
     */
    protected function getMigrationsPath(): string
    {
        return $this->getPath('/database/migrations');
    }

    /**
     * @param string|null $path
     * @return $this
     */
    protected function publishAssets($path = null): self
    {
        if (empty($path)) {
            $path = 'vendor/core/' . $this->getDashedNamespace();
        }

        $this->publishes([$this->getAssetsPath() => public_path($path)], 'cms-public');

        return $this;
    }

    /**
     * @return string
     */
    protected function getAssetsPath(): string
    {
        return $this->getPath('public');
    }

    protected function loadHelpers(): static
    {
        Helper::autoload($this->getPath('/helpers'));

        return $this;
    }

    protected function loadAnonymousComponents(): static
    {
        $this->app['blade.compiler']->anonymousComponentPath(
            $this->getViewsPath() . '/components',
            str_replace('/', '-', $this->namespace)
        );

        return $this;
    }
}
