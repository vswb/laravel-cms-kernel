<?php

namespace Dev\Kernel\Commands;

use Dev\Base\Enums\BaseStatusEnum;
use Dev\ACL\Models\User;

use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Console\Command;

use Illuminate\Support\Facades\Log;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

use Dev\Base\Http\Controllers\BaseController;
use Dev\Base\Http\Responses\BaseHttpResponse;
use Dev\AdvancedRole\Repositories\Interfaces\MemberInterface;
use Dev\Setting\Supports\SettingStore;
use Dev\Base\Facades\Assets;
use Dev\Media\Facades\AppMedia;
use Dev\Lead\Repositories\Interfaces\ConnectionInterface;
use Dev\ThumbnailGenerator\Facades\ThumbnailMediaFacade as ThumbnailMedia;

use Rinvex\Subscriptions\Models\PlanFeature;

use Symfony\Component\HttpFoundation\Response;
use Carbon\CarbonInterface;
use Exception;
use Throwable;

class TestCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'cms:test-command';

    private $logger = 'test-log'; // logger filename

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Test laravel command';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
        $this->logger = apps_log_channel($this->logger); // validate/check and create new logger if needed;

    }

    /**
     * Ex: APPLICATION_ENV=development && php -d memory_limit=-1 artisan test:test
     *
     */
    public function handle()
    {
        try {
            dd(ThumbnailMedia::getImageUrl('storage/uploads/1730574600-1730574600.jpg', '300x200'));

            $options["abc"] = [
                "error" => true,
                "code" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                "statusCode" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                "data" => "",
                "message" => "The form  has been excluded",
                "provider" => "leadgen_notification_callback_extended",
            ];
            $options["asdasd"] = [
                "error" => true,
                "code" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                "statusCode" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                "data" => "",
                "message" => "The form  has been excluded",
                "provider" => "leadgen_notification_callback_extended",
            ];

            $options = [
                ...$options,
                "leadgen_notification_callback_extended" => [
                    "error" => true,
                    "code" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                    "statusCode" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                    "data" => "",
                    "message" => "The form  has been excluded",
                    "provider" => "leadgen_notification_callback_extended",
                ],
                "leadgen_notification_external_webhook" => [
                    "error" => true,
                    "code" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                    "statusCode" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                    "data" => "",
                    "message" => "The form  has been excluded",
                    "provider" => "leadgen_notification_external_webhook",
                ],
                "leadgen_notification_acellemail" => [
                    "error" => true,
                    "code" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                    "statusCode" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                    "data" => "",
                    "message" => "The form  has been excluded",
                    "provider" => "leadgen_notification_acellemail",
                ],
                "leadgen_notification_metaconversion" => [
                    "error" => true,
                    "code" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                    "statusCode" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                    "data" => "",
                    "message" => "The form  has been excluded",
                    "provider" => "leadgen_notification_metaconversion",
                ],
                "leadgen_notification_spreadsheet" => [
                    "error" => true,
                    "code" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                    "statusCode" => BaseHttpResponse::HTTP_NOT_ACCEPTABLE,
                    "data" => "",
                    "message" => "The form  has been excluded",
                    "provider" => "leadgen_notification_spreadsheet",
                ],
            ];


            dd($options);
            $sOptions = json_decode('{"choose_all_forms":true,"leadgen_forms":[{"id":"648435454677448","locale":"en_US","name":"##22##Hilux 2025##HiluxFY25##DGM##fb_lead##CPL##Price","status":"ACTIVE"}]}', true);
            dd(
                array_key_exists('choose_all_forms', $sOptions),
                (Arr::get($sOptions, 'choose_all_forms') == true && // all forms are selected by default, except those manually excluded
                    collect(Arr::get($sOptions, 'leadgen_forms'))->doesntContain('id', '648435454677448')) ||
                    (Arr::get($sOptions, 'choose_all_forms') == false && // all forms are exclued by default, except those manually indclued
                        collect(Arr::get($sOptions, 'leadgen_forms'))->contains('id', '648435454677448'))
            );

            $collection = Str::of('74@@Bình Dương')->explode('@@');
            $data = Arr::get(
                $collection->all(), // CITY_IT@@CITY_NAME
                0,
                null
            );
            dd($collection->all(), $data);

            $str = '{"time":1744901415655,"id":"283404554854017","messaging":[{"sender":{"id":"9456407007811292"},"recipient":{"id":"283404554854017"},"timestamp":1744901414728,"message":{"mid":"m_WTwgstCmENHxVWpfmoLbRKK1uSaFNqL6Pdig6j520YChhksGxvsE_tarcfE_QL1Fztwm7u_y9fKVis91W-4psw","text":"Phone number: 090 628 27 90 Showroom Peugeot gần nhất: Peugeot Phú Nhuận - Q. Phú Nhuận Full name: Nguyễn Hoàng Hiệp"}}]}';
            $json = json_decode($str);
            // $array = preg_split("/\r\n|\n|\r/", $str);
            dd($json);

            $json = '{"leadgen_forms":[{"target":"id","key":"form-contact","id":"1309052413508036","locale":"vi_VN","name":"form-contact","status":"publised","fields":[{"id":"IdProvince","key":"IdProvince","label":"IdProvince","target":"id","type":"select","mappings":["province"]},{"id":"IdDistrict","key":"IdDistrict","label":"IdDistrict","target":"id","type":"select","mappings":["district"]}],"params":[{"key":"utm_source","value":"Zalo_lead"},{"key":"utm_campaign","value":"BPMV_VelozCKD_2025"},{"key":"utm_content","value":"Promotion"}]}]}';
            dd(apps_json_to_database([], ['abc' => 'cdef']));

            // $str = 'xin cảm ơn chương trình dùng thử miễn phí trang phục linh plus dc của mình là nhà số 1 ngo 61 nguyễn thiện thuật thị trấn khoái châu huyện khoái châu tỉnh hưng yên sdt+84943999819';
            // $str = 'Cho tôi xin một liệu trình dùng thử 0974176981';
            // $str = '0989846680 tổ 12 ấp minh phong xã bình an huyện châu thành tỉnh kiên giang';
            // $str = 'Phone number: 090-363-79 -91 Showroom Peugeot gần nhất: Peugeot Phú Nhuận - Q. Phú Nhuận Full name: Mạnh Kha';
            // $p = apps_phone_extraction($str);
            // dd($p);

            // Normal
            // $str = 'xin cảm ơn chương trình dùng thử miễn phí trang phục linh plus dc của mình là nhà số 1 ngo 61 nguyễn thiện thuật thị trấn khoái châu huyện khoái châu tỉnh hưng yên sdt+84943999819';
            // // preg_match_all('/(\+\d{1,3})?\s?\(?\d{1,4}\)?[\s.-]?\d{3}[\s.-]?\d{4}/', $str, $matches1); // original pattern
            // preg_match_all('/(\+\d{1,2})?\s?\(?\d{1,4}\)?[\s.-]?\d{3}[\s.-]?\d{4}/', $str, $matches1); // custom pattern

            // // Validating Specific Country and Area Codes
            // // preg_match_all('/(\+84)?\s?\(?(2\d{2}|[3-9]\d{2})\)?[\s.-]?\d{3}[\s.-]?\d{4}/', $str, $matches2); // original pattern
            // preg_match_all('/(\+84)?\s?\(?(2\d{2}|[3-9]\d{1})\)?[\s.-]?\d{3}[\s.-]?\d{4}/', $str, $matches2); // custom pattern

            // // Using Named Groups for Better Readability
            // // preg_match_all('/(?P<country_code>\+\d{1,3})?\s?\(?(?P<area_code>\d{1,4})\)?[\s.-]?(?P<local_number>\d{3}[\s.-]?\d{4})/', $str, $matches3); // original pattern
            // preg_match_all('/(?P<country_code>\+\d{1,2})?\s?\(?(?P<area_code>\d{1,4})\)?[\s.-]?(?P<local_number>\d{3}[\s.-]?\d{4})/', $str, $matches3); // custom pattern
            // dd($matches1, $matches2, $matches3);


            $exchangeToken = zalooa_get_access_token("none", "refresh_token", 'uYhDJ-DBpXpZ8yDDxap86UianKdiKuf9bNx17SP6e1YLM-qBvtAG6hj_cHJdJibBfNYHREXGss6tOuSnv5Nb7eLgjm230xum_YEyCQ5DyWJWK-GjxLYiBhPDxWRTLQC3irJ_8yrd_1IpR98pmN_SUBPXa6l1ICDhltMURhXrt3ZJ6e0RedNr5EKPYZEz1DajlMsA7lXhon2aUgSOtKdc3zj5jm7TPiual4l2DC9UdJICIzSbqLsqETPmuZoI7giN_shF9uPOkX7HSRGEkc_b0DrHg3AOCUGHwXYy0_CP_WY1DkWxu3wM6-1AwmMEAlqQZakSF-9UyHUXTAO4zspr3APqdm30TSCKeKwf9T5L-ZMhMemqzJRd8BO1YnVq6jr0XnMhKzW7vtkcDkjrmGwYIvzbwHGrTpHPEsRYNSSU');
            dd($exchangeToken);

            $model = app(ConnectionInterface::class)->getModel();
            $flight = $model->updateOrCreate(
                ['name' => 'London to Paris'],
                ['description' => 2, 'arrival_time' => '11:30']
            );
            dd(get_class_methods($model));
            // test commit
            // test commit
            // test
            // test
            // test commit
            // test
            dd(Str::contains(Arr::get(
                json_decode('{"error":false,"code":200,"statusCode":200,"data":{"workbookId":"1rKqI0SxDu7X33IupNzGfsy68fWoAqjU0NKQqP5WrY3Q","sheetId":0,"sheetName":"LIST DATA","spreadsheetId":"1rKqI0SxDu7X33IupNzGfsy68fWoAqjU0NKQqP5WrY3Q","tableRange":"\'LIST DATA\'!A1:W5688","updates":{"spreadsheetId":"1rKqI0SxDu7X33IupNzGfsy68fWoAqjU0NKQqP5WrY3Q","updatedCells":23,"updatedColumns":23,"updatedRange":"\'LIST DATA\'!A5689:W5689","updatedRows":1}},"message":"Request has been successfully processed","provider":"leadgen_notification_spreadsheet"}', true),
                'provider',
                ''
            ), 'leadgen_notification_spreadsheet'));


            dump(app('es-makeindex'));
            dd("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

            dump(response()->json('my msg')->setStatusCode(Response::HTTP_BAD_REQUEST));
            dd("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

            // logger()->channel($this->logger)->info("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            // app('log')->channel($this->logger)->error('asasdasdads');
            dd("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

            apps_telegram_send_message([
                "⚠️⚠️⚠️ Application: " . env("APP_NAME"),
                __CLASS__ . " " . __FUNCTION__ . " is running",
                app('url')->full(),
            ], 'pullerrors', $this->logger); // send important message to telegram

            dd("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

            $notification = '{"authorization":{"type":"bearer","key":null,"value":"dzBIIkgSQSz8DQOBIGhOnUG1hBoA2txvy43U0HaMXLLyPKBc2H5hX5aDqlGLK45PO5AlBb3rQc4ezKtw"},"params":"[{\"key\":\"key1\",\"value\":\"val1\"},{\"key\":\"key2\",\"value\":\"val2\"}]","headers":"[{\"key\":\"key1\",\"value\":\"val1\"},{\"key\":\"key2\",\"value\":\"val2\"}]","status":"published","method":"POST","api_endpoint":"https://kiavietnam.com.vn/api/v1/leadgen"}';
            $notification = json_decode($notification, true);
            $whHeaders = json_decode(Arr::get($notification, 'headers', '{}'), TRUE);
            if (!blank($whHeaders)) {
                $whHeaders = array_reduce($whHeaders, function ($headers, $value) {
                    $headers[$value['key']] = $value['value'];
                    return $headers;
                }, []);
            }
            $whParams = json_decode(Arr::get($notification, 'params', '{}'), TRUE);
            if (!blank($whParams)) {
                $whParams = array_reduce($whParams, function ($params, $value) {
                    $params[$value['key']] = $value['value'];
                    return $params;
                }, []);
            }
            $var['name'] = '';
            dd("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

            $arr = [
                'code' => 200
            ];
            dump(
                [
                    ...$arr,
                    'code' => 400
                ]
            ); // test vị trí ưu tiên khi merge array
            dd("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

            dump(apps_get_provinces_districts_rawdata('Thanh Hoá'));
            dump(apps_province_detection('(Thanh Hoá) ĐL Thanh Hoá_TTH')); // return Thanh Hoá
            dd("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

            $text = 'ignore everything except this (text)';
            preg_match('#\((.*?)\)#', $text, $match);
            dump(blank($match), $match);
            dd("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

            $commitTimestamp = '30-12-2024';
            $dt = Carbon::now();
            $dt = Carbon::parse($commitTimestamp);
            dump($dt->isWeekend());
            dd("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

            $lead['email'] = "somead@dress22.c111om";
            dump(filter_var($lead['email'], FILTER_VALIDATE_EMAIL));
            dd("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

            $commitTimestamp = '27-12-2024'; // '2024-12-24' (OK) '2024-12-24 02:47:26' (OK); '27-12-2024' (OK) // '27/12/2024 (NOK)';
            $committedAt = Carbon::parse($commitTimestamp);
            $commitTimestamp = '2024-12-19T13:21:37+07:00';
            $committedAt = Carbon::parse($commitTimestamp);
            dump($committedAt);
            dump(
                $committedAt->startOfDay(),
                $wkDayTimeBegin = Carbon::parse($commitTimestamp)->startOfDay()->addHours(8)->addMinutes(45)->toString(),
                $wkDayTimeEnd = Carbon::parse($commitTimestamp)->startOfDay()->addHours(18)->addMinutes(45)->toString(),
                $committedAt->gt($wkDayTimeBegin),
                $committedAt->lt($wkDayTimeEnd)
            );
            dd("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

            $lspreadsheet = $lpusher = $loptions = false;
            $str = '{"result":{"statusCode":"200","message":"Success"},"targetUrl":null,"success":true,"error":null,"unAuthorizedRequest":false,"__abp":true}';
            $responseData = json_decode($str, TRUE);
            dump(
                ceil(round(1281.01)),
                ceil(1281.01),
                [
                    ...Arr::get(
                        $responseData,
                        'result',
                        false
                    ),
                    "error" => false,
                    "code" => Arr::get(
                        $responseData,
                        'result.statusCode',
                        false
                    ),
                    "data" => $responseData
                ],
                Arr::get(
                    $responseData,
                    'success',
                    false
                ),
                Arr::get(
                    $responseData,
                    'result.statusCode',
                    false
                )
            );
            dd("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        } catch (\Throwable $th) {
            dd($th);
        }
    }
}
