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

use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

use Dev\Kernel\Events\MemberBirthdayEvent;
use Dev\Kernel\Listeners\MemberBirthdayListener;
class EventServiceProvider extends ServiceProvider
{
    /**
     * The event listener mappings for the application.
     * Trước khi đến các bước xử lý trong Event, chúng ta cần đăng ký Event.
     * 
     * @var array
     */
    protected $listen = [
        MemberBirthdayEvent::class => [
            MemberBirthdayListener::class,
        ]
    ];

    protected $observers = [];
}
