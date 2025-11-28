<?php

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
