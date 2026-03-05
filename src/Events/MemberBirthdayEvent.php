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
