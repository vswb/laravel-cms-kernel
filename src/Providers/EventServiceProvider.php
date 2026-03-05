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
