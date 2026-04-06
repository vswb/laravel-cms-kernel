<?php

/**
 * © 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Proprietary software developed and distributed by Visual Weber.
 * Use is permitted only under a valid license agreement.
 *
 * © 2026 CÔNG TY TNHH VISUAL WEBER. Bảo lưu mọi quyền.
 * Phần mềm độc quyền của Visual Weber, chỉ được sử dụng theo Hợp đồng cấp phép.
 */

namespace Dev\Kernel\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MemberBirthdayEvent
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /**
     * Create a new event instance and Handle the event.
     * 
     * Cách khởi tạo một event: Để bắn ra một sự kiện, Larvel cung cấp 2 phương thức là sử dụng helper Event hoặc static method dispatch
     * Event cần phải sử dụng trait Dispatchable
     * 
     * Lưu ý: ở đây ta có thể gán trực tiếp một Eloquent model Post vào hàm __construct vì đã sử dụng trait SerializesModels.
     * Model sẽ được serialized và unserialized khi job được thực thi.
     * 
     * @param $receiver
     * 
     * @return void
     */

    public function __construct(public $receiver)
    {
        $this->receiver = $receiver;
    }
}
