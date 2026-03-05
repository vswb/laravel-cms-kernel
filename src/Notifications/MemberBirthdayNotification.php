<?php
/**
 * (c) Copyright 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Distributed by: VISUAL WEBER CO., LTD.
 * * [PRODUCT INFORMATION]
 * This software is a proprietary product developed by Visual Weber.
 * All rights to the software and its components are reserved under 
 * Intellectual Property laws.
 * * [TERMS OF USE]
 * Usage is permitted strictly according to the License Agreement 
 * between Visual Weber and the Client.
 * -------------------------------------------------------------------------
 * (c) Bản quyền thuộc về CÔNG TY TNHH VISUAL WEBER 2026. Bảo lưu mọi quyền.
 * Phát hành bởi: Công ty TNHH Visual Weber.
 * * [THÔNG TIN SẢN PHẨM]
 * Phần mềm này là sản phẩm độc quyền được phát triển bởi Visual Weber.
 * Mọi quyền đối với phần mềm và các thành phần cấu thành đều được bảo hộ 
 * theo luật Sở hữu trí tuệ.
 * * [ĐIỀU KHOẢN SỬ DỤNG]
 * Việc sử dụng được giới hạn nghiêm ngặt theo Hợp đồng cung cấp dịch vụ/phần mềm 
 * giữa Visual Weber và Khách hàng.
 */
namespace Dev\Kernel\Notifications;

use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Support\HtmlString;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\URL;
use Illuminate\Queue\InteractsWithQueue;

use Dev\Base\Facades\EmailHandler;

class MemberBirthdayNotification extends Notification implements ShouldQueue
{
    use Queueable;

    /**
     * Create a new notification instance.
     *
     * @return void
     */

    public function __construct(public $event)
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
