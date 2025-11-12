<?php

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
