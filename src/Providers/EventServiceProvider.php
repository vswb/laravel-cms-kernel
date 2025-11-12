<?php

namespace Platform\Kernel\Providers;

use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

use Platform\Kernel\Events\MemberBirthdayEvent;
use Platform\Kernel\Listeners\MemberBirthdayListener;
use Platform\AdvancedRole\Models\Member;

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
