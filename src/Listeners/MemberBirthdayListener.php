<?php

namespace Dev\Kernel\Listeners;

use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Support\HtmlString;
use Illuminate\Support\Facades\Notification;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Contracts\Queue\ShouldQueue;

use Dev\Base\Facades\EmailHandler;
use Dev\Kernel\Events\MemberBirthdayEvent;
use Dev\Kernel\Notifications\MemberBirthdayNotification;

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
