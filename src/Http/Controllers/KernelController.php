<?php

namespace Platform\Kernel\Http\Controllers;

use Illuminate\Support\Facades\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;
use Illuminate\Routing\Controller as BaseController;
use Illuminate\Support\Facades\Notification;

use chillerlan\QRCode\{QRCode, QROptions};
use chillerlan\QRCode\Common\EccLevel;
use chillerlan\QRCode\Data\QRMatrix;
use chillerlan\QRCode\Output\{QROutputInterface, QRGdImage};

use Platform\AppQrcode\QRImageWithText;
use Platform\Telegram\Notifications\TelegramRawNotification;

use NotificationChannels\Telegram\TelegramMessage;
use NotificationChannels\Telegram\TelegramChannel;

use Facebook\Facebook;
use Carbon\Carbon;

use Exception;
use Throwable;
use Symfony\Component\HttpFoundation\Response;
use PhpOffice\PhpSpreadsheet\Style\ConditionalFormatting\Wizard\Blanks;

class KernelController extends BaseController
{
    public function test(Request $request)
    {
        apps_telegram_send_message([
            "https://developers.facebook.com/docs/graph-api",
            __CLASS__ . " " . __FUNCTION__ . " is running",
        ], 'pull'); // send important message to telegram
    }
}
