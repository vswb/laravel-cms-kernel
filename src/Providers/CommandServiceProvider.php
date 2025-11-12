<?php

namespace Platform\Kernel\Providers;

use Illuminate\Support\ServiceProvider;

use Platform\Kernel\Commands\MemberBirthdayNotificationCommand;
use Platform\Kernel\Commands\TestCommand;
use Platform\Kernel\Commands\LocationImporterCommand;
use Platform\Kernel\Commands\SetupGitHookCommand;

class CommandServiceProvider extends ServiceProvider
{
    public function boot()
    {
        if (app()->runningInConsole()) {
            $this->commands([
                LocationImporterCommand::class,
                TestCommand::class,
                MemberBirthdayNotificationCommand::class,
                SetupGitHookCommand::class
            ]);
        }
    }
}
