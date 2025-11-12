<?php

namespace Platform\Kernel\Listeners;

use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Support\HtmlString;
use Illuminate\Support\Facades\Notification;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Contracts\Queue\ShouldQueue;

use Platform\Base\Facades\EmailHandler;
use Platform\Kernel\Events\MemberBirthdayEvent;
use Platform\Kernel\Notifications\MemberBirthdayNotification;

class MemberBirthdayListener
{

    /**
     * Handle the event.
     * 
     * @param MemberBirthdayEvent $event
     * @return void
     */
    public function handle(MemberBirthdayEvent $event): void
    {
        Notification::send($event->receiver, new MemberBirthdayNotification($event));
    }
}
