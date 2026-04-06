<?php

/**
 * © 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Proprietary software developed and distributed by Visual Weber.
 * Use is permitted only under a valid license agreement.
 *
 * © 2026 CÔNG TY TNHH VISUAL WEBER. Bảo lưu mọi quyền.
 * Phần mềm độc quyền của Visual Weber, chỉ được sử dụng theo Hợp đồng cấp phép.
 */

namespace Dev\Kernel\Http\Controllers;

use Illuminate\Support\Facades\Request;
use Illuminate\Routing\Controller as BaseController;

class KernelController extends BaseController
{
    public function test(Request $request)
    {
        apps_telegram_send_message([
            "https://developers.facebook.com/docs/graph-api",
            get_class($this) . '@' . __FUNCTION__ . " is running",
        ], 'pull'); // send important message to telegram
    }
}
