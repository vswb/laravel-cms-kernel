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
namespace Dev\Kernel\Commands;

use Illuminate\Support\Str;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Validator;

use Dev\Base\Commands\Traits\ValidateCommandInput;
use Dev\Base\Exceptions\LicenseIsAlreadyActivatedException;
use Dev\Base\Supports\Core;
use Dev\Setting\Facades\Setting;

use Dev\AdvancedRole\Models\Member;
use Dev\Kernel\Events\MemberBirthdayEvent;

use Exception;
use Throwable;
use Carbon\Carbon;

class MemberBirthdayNotificationCommand extends Command
{
    private $logger = 'birthday-notification'; // logger filename

    /**
     * The name and signature of the console command.
     * php artisan cms:member:birthday-notification
     *
     * @var string
     */
    protected $signature = 'cms:member:birthday-notification';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'send birthday reminder to the client before and after due date of birthday';

    public function __construct()
    {
        $this->logger = apps_log_channel($this->logger);

        parent::__construct();
    }
    /**
     * Handle the command.
     *
     * All members with an upcoming notified and triggers the "MemberBirthdayEvent".
     */

    public function handle(Member $memberService)
    {
        try {
            $config = app('config')->get('kernel.general');
            $currentDay = now()->format('m-d');

            $members = $memberService->whereRaw('DATE_FORMAT(`dob`, "%m-%d") = "' . $currentDay . '"')->get();
            foreach ($members as $member) :
                $birthday = $member->dob ?: $member->created_at;
                $this->info("Member {$member->name} checking birthday");

                if (
                    $birthday
                    && $birthday->startOfDay()->eq(Carbon::today()->startOfDay())
                ) :
                    $this->info("Sending event to Member {$member->name}");
                    // Log::channel($this->logger)->info("Sending event to Member {$member->name}");

                    event(new MemberBirthdayEvent($member));
                else:
                    $this->info("Member {$member->name} has been notify in ... days");
                    // Log::channel($this->logger)->info("Member {$member->name} has been notify in ... days");
                endif;
            endforeach;
        } catch (Throwable $th) {
            $this->error($th->getMessage());
            Log::channel($this->logger)->error(get_class($this) . '@' . __FUNCTION__, (array) [$th->getFile(), $th->getLine(), $th->getMessage()]);
            Log::channel($this->logger)->error(get_class($this) . '@' . __FUNCTION__, (array) $th->getTraceAsString());
        }

        return Command::SUCCESS;
    }
}
