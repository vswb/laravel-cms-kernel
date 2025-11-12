<?php

namespace Platform\Kernel\Jobs;

use Illuminate\Support\Facades\Mail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Fluent;
use Illuminate\Bus\Batchable;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Carbon;

use Platform\Location\Models\Country;
use Platform\Location\Models\City;
use Platform\Location\Models\State;
use Platform\Kernel\Models\District;
use Platform\Kernel\Models\Ward;
use Platform\Location\Events\ImportedCityEvent;
use Platform\Location\Events\ImportedCountryEvent;
use Platform\Location\Events\ImportedStateEvent;

use Exception;
use Throwable;
use EmailHandler;

class LocationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels, Batchable;

    protected $logger = 'location-import'; // logger filename

    /**
     * @var mixed
     */
    public $row;

    /**
     * @var mixed
     */
    public $country;

    /**
     * Create a new job instance.
     */
    public function __construct($row, $country)
    {
        $this->row = $row;
        $this->country = $country;
        $this->logger = apps_log_channel($this->logger);
    }

    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        try {
            $cityData = [
                "code" => $this->row['ma_tp'],
                'type' => null,
                "slug" => Str::slug($this->row['tinh_thanh_pho']),
                "order" => 0,
                "status" => "published"
            ];
            $city = City::firstOrCreate(
                [
                    'name' =>  $this->row['tinh_thanh_pho'],
                    'country_id' => $this->country->id,
                ],
                $cityData,
            );
            if ($city->wasRecentlyCreated) {
                event(new ImportedCityEvent($this->row, $city));
            }

            if ($city && $this->row['ma_qh']) {
                $city->code = $this->row['ma_tp'];
                $city->save(); // code is not define in fillable

                $districtData = [
                    'name' => $this->row['quan_huyen'],
                    'code' => $this->row['ma_qh'],
                    'type' => null,
                    'city_id' => $city->id,
                    'order' => 0,
                    'is_default' => 0,
                    'status' => 'published'
                ];
                $district = District::firstOrCreate(
                    [
                        'code' => $this->row['ma_qh'],
                        'city_id' => $city->id,
                    ],
                    $districtData,
                );

                if ($district && $this->row['ma_px']) {
                    $wardData = [
                        'name' => $this->row['phuong_xa'],
                        'code' => $this->row['ma_px'],
                        'type' => null,
                        'district_id' => $district->id,
                        'order' => 0,
                        'is_default' => 0,
                        'status' => 'published'
                    ];

                    $ward = Ward::firstOrCreate(
                        [
                            'code' => $this->row['ma_px'],
                            'district_id' => $district->id,
                        ],
                        $wardData,
                    );
                }
            }
        } catch (Throwable $th) {
            Log::channel($this->logger)->error(__FUNCTION__ . ": " . $th->getMessage());
        }
    }
}
