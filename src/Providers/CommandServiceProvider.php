<?php

/**
 * © 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Proprietary software developed and distributed by Visual Weber.
 * Use is permitted only under a valid license agreement.
 *
 * © 2026 CÔNG TY TNHH VISUAL WEBER. Bảo lưu mọi quyền.
 * Phần mềm độc quyền của Visual Weber, chỉ được sử dụng theo Hợp đồng cấp phép.
 */

namespace Dev\Kernel\Providers;

use Illuminate\Support\ServiceProvider;

use Dev\Kernel\Commands\MemberBirthdayNotificationCommand;
use Dev\Kernel\Commands\TestCommand;
use Dev\Kernel\Commands\SetupGitHookCommand;
use Dev\Kernel\Commands\CheckMiddlewareCommand;
use Dev\Kernel\Commands\GDriveMirrorSync;

class CommandServiceProvider extends ServiceProvider
{
    public function boot()
    {
        if (app()->runningInConsole()) {
            $this->commands([
                TestCommand::class,
                MemberBirthdayNotificationCommand::class,
                SetupGitHookCommand::class,
                CheckMiddlewareCommand::class,
                GDriveMirrorSync::class,
            ]);
        }
    }
}
