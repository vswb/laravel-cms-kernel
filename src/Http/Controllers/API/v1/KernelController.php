<?php

namespace Dev\Kernel\Http\Controllers\API\v1;

use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;
use Illuminate\Routing\Controller as BaseController;
use Illuminate\Support\Facades\Notification;

use chillerlan\QRCode\{QRCode, QROptions};
use chillerlan\QRCode\Common\EccLevel;
use chillerlan\QRCode\Data\QRMatrix;
use chillerlan\QRCode\Output\{QROutputInterface, QRGdImage};

use Dev\Base\Http\Responses\BaseHttpResponse;
use Dev\AdvancedRole\Models\Member;
use Dev\AppQrcode\QRImageWithText;
use Dev\Telegram\Notifications\TelegramRawNotification;

use NotificationChannels\Telegram\TelegramMessage;
use NotificationChannels\Telegram\TelegramChannel;

use Facebook\Facebook;
use Carbon\Carbon;
use Rinvex\Subscriptions\Models\PlanFeature;

use Exception;
use Throwable;
use Symfony\Component\HttpFoundation\Response;
use PhpOffice\PhpSpreadsheet\Style\ConditionalFormatting\Wizard\Blanks;

class KernelController extends Controller
{

    /**
     * Hiện trạng: đang sử dụng. Sử dụng để tạo nhanh mã QR cho khách khi cần
     * 
     * https://github.com/chillerlan/php-qrcode/tree/main/examples
     * 
     * @url: {{app_uld}}/api/v1/test/make-qrcode
     */
    public function makeQrcode(Request $request)
    {
        try {
            $options = new QROptions([
                'version' => 7,
                'eccLevel' => EccLevel::L,
                'scale' => 10,
                'imageBase64' => false,
                'bgColor' => [200, 200, 200],
                'imageTransparent' => false,
                'drawCircularModules' => true,
                'circleRadius' => 0.4,
                'keepAsSquare' => [QRMatrix::M_FINDER | QRMatrix::IS_DARK, QRMatrix::M_FINDER_DOT, QRMatrix::M_ALIGNMENT | QRMatrix::IS_DARK],
                'moduleValues' => [
                    // finder
                    QRMatrix::M_FINDER | QRMatrix::IS_DARK => [0, 63, 255], // dark (true)
                    QRMatrix::M_FINDER => [233, 233, 233], // light (false), white is the transparency color and is enabled by default
                    QRMatrix::M_FINDER_DOT | QRMatrix::IS_DARK => [0, 63, 255], // finder dot, dark (true)
                    // alignment
                    QRMatrix::M_ALIGNMENT | QRMatrix::IS_DARK => [255, 0, 255],
                    QRMatrix::M_ALIGNMENT => [233, 233, 233],
                    // timing
                    QRMatrix::M_TIMING | QRMatrix::IS_DARK => [255, 0, 0],
                    QRMatrix::M_TIMING => [233, 233, 233],
                    // format
                    QRMatrix::M_FORMAT | QRMatrix::IS_DARK => [67, 159, 84],
                    QRMatrix::M_FORMAT => [233, 233, 233],
                    // version
                    QRMatrix::M_VERSION | QRMatrix::IS_DARK => [62, 174, 190],
                    QRMatrix::M_VERSION => [233, 233, 233],
                    // data
                    QRMatrix::M_DATA | QRMatrix::IS_DARK => [0, 0, 0],
                    QRMatrix::M_DATA => [233, 233, 233],
                    // darkmodule
                    QRMatrix::M_DARKMODULE | QRMatrix::IS_DARK => [0, 0, 0],
                    // separator
                    QRMatrix::M_SEPARATOR => [233, 233, 233],
                    // quietzone
                    QRMatrix::M_QUIETZONE => [233, 233, 233],
                    // logo (requires a call to QRMatrix::setLogoSpace()), see QRImageWithLogo
                    QRMatrix::M_LOGO => [233, 233, 233],
                ],
            ]);

            echo '<img src="' . (new QRCode($options))->render('http://imedical.vn/qrcode-doctor.php') . '" alt="QR Code" />';
            exit;
        } catch (\Throwable $th) {
            exit($th->getMessage());
        }
    }

    /**
     * Test only
     */
    public function test()
    {
        // Get subscriptions with period ending in 3 days
        $subscriptions = app('rinvex.subscriptions.plan_subscription')->findEndingPeriod(2)->get();
        return response()
            ->json((array) $subscriptions->toArray())
            ->setStatusCode(Response::HTTP_BAD_REQUEST);
    }

    /**
     * Middleware Check - Verify tất cả middleware đã hoạt động
     * 
     * @url: GET /api/v1/test/middleware-check
     * 
     * Kiểm tra:
     * - SecurityHeaders: Xem response headers
     * - TrustProxies: Xem real IP
     * - TrimStrings: Test trim input
     * - EncryptCookies: Xem cookies
     * - StartSession: Xem session
     */
    public function middlewareCheck(Request $request): JsonResponse
    {
        $data = [
            'timestamp' => now()->toIso8601String(),
            'middleware_status' => 'active',
            'checks' => [
                // 1. SecurityHeaders - Kiểm tra response headers
                'security_headers' => [
                    'status' => 'check_response_headers',
                    'note' => 'Kiểm tra response headers: Strict-Transport-Security, CSP, X-Frame-Options, etc.',
                ],
                
                // 2. TrustProxies - Kiểm tra real IP
                'trust_proxies' => [
                    'status' => 'active',
                    'client_ip' => $request->ip(),
                    'real_ip' => $request->header('X-Forwarded-For') ?: $request->ip(),
                    'all_ips' => [
                        'ip()' => $request->ip(),
                        'getClientIp()' => $request->getClientIp(),
                        'X-Forwarded-For' => $request->header('X-Forwarded-For'),
                        'X-Real-IP' => $request->header('X-Real-IP'),
                    ],
                ],
                
                // 3. TrimStrings - Test trim input
                'trim_strings' => [
                    'status' => 'active',
                    'test_input' => $request->input('test', ''),
                    'note' => 'Gửi ?test=  hello  world  để test trim (sẽ trim spaces)',
                ],
                
                // 4. EncryptCookies - Kiểm tra cookies
                'encrypt_cookies' => [
                    'status' => 'active',
                    'cookies_received' => $request->cookies->all(),
                    'note' => 'Cookies sẽ được encrypt/decrypt tự động',
                ],
                
                // 5. StartSession - Kiểm tra session
                'start_session' => [
                    'status' => 'active',
                    'session_id' => session()->getId(),
                    'session_data' => session()->all(),
                    'note' => 'Session đã được start',
                ],
                
                // 6. TrustHosts - Kiểm tra host validation
                'trust_hosts' => [
                    'status' => 'active',
                    'host' => $request->getHost(),
                    'scheme' => $request->getScheme(),
                    'http_host' => $request->getHttpHost(),
                    'note' => 'Host đã được validate',
                ],
                
                // 7. ValidateSignature - Test signed URLs
                'validate_signature' => [
                    'status' => 'active',
                    'note' => 'Dùng URL::signedRoute() để test',
                ],
                
                // 8. VerifyCsrfToken - CSRF protection
                'verify_csrf_token' => [
                    'status' => 'excluded_for_api',
                    'note' => 'API routes đã được exclude khỏi CSRF (xem VerifyCsrfToken::$except)',
                ],
            ],
            
            'request_info' => [
                'method' => $request->method(),
                'url' => $request->fullUrl(),
                'path' => $request->path(),
                'headers' => $request->headers->all(),
                'query_params' => $request->query->all(),
            ],
            
            'instructions' => [
                '1. SecurityHeaders' => 'Kiểm tra response headers trong browser DevTools > Network tab',
                '2. TrustProxies' => 'Gửi header X-Forwarded-For để test',
                '3. TrimStrings' => 'Gửi ?test=  hello  world  để xem có trim không',
                '4. EncryptCookies' => 'Set cookie và xem có được encrypt không',
                '5. StartSession' => 'Session ID đã được tạo',
                '6. TrustHosts' => 'Host đã được validate',
                '7. ValidateSignature' => 'Dùng signed URLs để test',
                '8. VerifyCsrfToken' => 'API routes đã exclude CSRF',
            ],
        ];

        return response()->json($data, 200);
    }

    /**
     * Test only
     * Create a Plan
     */
    public function createPlan(Request $request, BaseHttpResponse $response)
    {
        $plan = app('rinvex.subscriptions.plan')->create([
            'name' => '123123 123123',
            'description' => 'Pusher Package',
            'price' => 9.99,
            'signup_fee' => 1.99,
            'invoice_period' => 1,
            'invoice_interval' => 'month',
            'trial_period' => 15,
            'trial_interval' => 'day',
            'sort_order' => 1,
            'currency' => 'USD',
        ]);

        // Create multiple plan features at once
        $plan->features()->saveMany([
            new PlanFeature(['name' => 'leadgen_notification_spreadsheet', 'value' => 'Y', 'sort_order' => 1]),
            new PlanFeature(['name' => 'leadgen_notification_external_webhook', 'value' => 'Y', 'sort_order' => 5]),
            new PlanFeature(['name' => 'leadgen_notification_acellemail', 'value' => 'Y', 'sort_order' => 10, 'resettable_period' => 1, 'resettable_interval' => 'month']),
            new PlanFeature(['name' => 'leadgen_notification_callback_extended', 'value' => 'Y', 'sort_order' => 15]),
            new PlanFeature(['name' => 'leadgen_notification_telegram', 'value' => 'Y', 'sort_order' => 15]),
            new PlanFeature(['name' => 'leadgen_notification_metaconversion', 'value' => 'Y', 'sort_order' => 15])
        ]);

        dump($plan);
        dump($plan->features);
        dump($plan->isFree());
        dump($plan->hasTrial());
        dump($plan->hasGrace());
    }
    /**
     * Test only
     * Create a Plan
     */
    public function addFeaturesToPlan(Request $request, BaseHttpResponse $response)
    {
        $plans = app('rinvex.subscriptions.plan')->all();

        foreach ($plans as $key => $plan) {
            // Create multiple plan features at once
            $plan->features()->saveMany([
                new PlanFeature(['name' => 'leadgen_notification_spreadsheet', 'value' => 'Y', 'sort_order' => 1]),
                new PlanFeature(['name' => 'leadgen_notification_external_webhook', 'value' => 'Y', 'sort_order' => 5]),
                new PlanFeature(['name' => 'leadgen_notification_acellemail', 'value' => 'Y', 'sort_order' => 10, 'resettable_period' => 1, 'resettable_interval' => 'month']),
                new PlanFeature(['name' => 'leadgen_notification_callback_extended', 'value' => 'Y', 'sort_order' => 15]),
                new PlanFeature(['name' => 'leadgen_notification_telegram', 'value' => 'Y', 'sort_order' => 15]),
                new PlanFeature(['name' => 'leadgen_notification_metaconversion', 'value' => 'Y', 'sort_order' => 15])
            ]);

            dump($plan->features);
            dump($plan->isFree());
            dump($plan->hasTrial());
            dump($plan->hasGrace());
        }
    }

    /**
     * Test only
     * 
     * Get Plan Details
     * You can query the plan for further details, using the intuitive API as follows
     */
    public function getPlan(Request $request, BaseHttpResponse $response)
    {
        $plan = app('rinvex.subscriptions.plan')->find($request->id);

        // Get all plan features
        $plan->features;

        // Get all plan subscriptions
        $plan->planSubscriptions;

        // Check if the plan is free
        $plan->isFree();

        // Check if the plan has trial period
        $plan->hasTrial();

        // Check if the plan has grace period
        $plan->hasGrace();

        dump($plan->planSubscriptions);
        dump($plan->features);
        dump($plan->isFree());
        dump($plan->hasTrial());
        dump($plan->hasGrace());

        // Use the plan instance to get feature's value
        // $amountOfPictures = $plan->getFeatureBySlug('main')->value;

        // Query the feature itself directly
        // $amountOfPictures = app('rinvex.subscriptions.plan_feature')->where('slug', 'main')->first()->value;

        // Get feature value through the subscription instance
        $amountOfPictures = app('rinvex.subscriptions.plan_subscription')->find(1)->getFeatureValue('listings');

        dump($amountOfPictures);
    }

    /**
     * Test only
     * 
     * Get Feature Value
     * Say you want to show the value of the feature pictures_per_listing from above. You can do so in many ways:
     */
    public function getFeature(Request $request, BaseHttpResponse $response)
    {
        $user = Member::find(3);
        $plan = app('rinvex.subscriptions.plan')->find(1);

        $user->newPlanSubscription('listings', $plan, Carbon::now());
        dump($user, $plan);
    }

    /**
     * Create a Subscription
     * You can subscribe a user to a plan by using the newSubscription() function available in the HasPlanSubscriptions trait. 
     * First, retrieve an instance of your subscriber model, which typically will be your user model and an instance of the plan your user is subscribing to. 
     * Once you have retrieved the model instance, you may use the newSubscription method to create the model's subscription.
     * 
     * The first argument passed to newSubscription method should be the title of the subscription. 
     * If your application offer a single subscription, you might call this main or primary, 
     * while the second argument is the plan instance your user is subscribing to, and there's an optional third parameter 
     * to specify custom start date as an instance of Carbon\Carbon (by default if not provided, it will start now).
     */
    public function createSubscription(Request $request, BaseHttpResponse $response)
    {
        $user = Member::find(3);
        $plan = app('rinvex.subscriptions.plan')->find(1);

        $user->newPlanSubscription('listings', $plan, Carbon::now());
        dump($user, $plan);
    }

    /**
     * Change the Plan
     * You can change subscription plan easily as follows
     */
    public function changePlan(Request $request, BaseHttpResponse $response)
    {
        $plan = app('rinvex.subscriptions.plan')->find(2);
        $subscription = app('rinvex.subscriptions.plan_subscription')->find(1);

        // Change subscription plan
        $subscription->changePlan($plan);
    }
}
