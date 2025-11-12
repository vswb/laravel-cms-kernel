<?php

namespace Platform\Kernel\Notifications;

use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Support\HtmlString;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\URL;
use Illuminate\Queue\InteractsWithQueue;

use Platform\Base\Facades\EmailHandler;

class MemberBirthdayNotification extends Notification implements ShouldQueue
{
    use Queueable;

    /**
     * @var mixed
     */
    public $event;

    /**
     * Create a new notification instance.
     *
     * @return void
     */
    public function __construct($event)
    {
        $this->event = $event;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @param  mixed $notifiable
     * @return array
     */
    public function via($notifiable): array
    {
        return ['mail'];
    }

    /**
     * Get the mail representation of the notification.
     *
     * @param  mixed $notifiable
     * @return MailMessage
     */
    public function toMail($notifiable): MailMessage
    {
        try {
            if (!blank($notifiable->email)) {
                $args = [
                    // 'attachments' => [
                    //     public_path("files/SOL24.0830 [in] NovaWorld Phan Thiet - Server Architecture and Website Deployment V4.pdf"),
                    //     public_path("files/SOL24.0830 [in] NovaWorld Phan Thiet - Server Architecture and Website Deployment V4.pdf")
                    // ]
                ];

                $emailHandler = EmailHandler::setModule(KERNEL_MODULE_SCREEN_NAME);
                if ($emailHandler->templateEnabled('member-birthday-reminder-notification', 'kernel')) {
                    $emailHandler
                        ->setType("kernel")
                        ->setPlatformPath("dev-extensions")
                        ->setVariableValues([
                            'email',
                            $notifiable->email
                        ])
                        ->sendUsingTemplate(
                            'member-birthday-reminder-notification',
                            'toan@visualweber.com' ?: null,
                            $args,
                            true, // debug
                            "kernel"
                        );
                }
            }

            return (new MailMessage())
                ->view(['html' => new HtmlString($emailHandler->getContent())])
                ->subject($emailHandler->getSubject());
        } catch (\Throwable $th) {
            dd($th->getMessage());
        }
    }
}
