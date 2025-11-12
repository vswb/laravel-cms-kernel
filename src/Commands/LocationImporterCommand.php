<?php

namespace Dev\Kernel\Commands;

use Exception;
use Throwable;
use Carbon\Carbon;
use EmailHandler;

use Illuminate\Support\Str;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Schema;

use Dev\Kernel\Imports\LocationImport;
use Dev\Location\Models\Country;
use Dev\Location\Models\City;
use Dev\Location\Models\State;
use Dev\Kernel\Models\District;
use Dev\Kernel\Models\Ward;
use Dev\Location\Events\ImportedCityEvent;
use Dev\Location\Events\ImportedCountryEvent;

use Maatwebsite\Excel\Facades\Excel;

use PhpOffice\PhpSpreadsheet\IOFactory;
use PhpOffice\PhpSpreadsheet\Shared\Date;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;
use PhpOffice\PhpSpreadsheet\Cell\DefaultValueBinder;
use PhpOffice\PhpSpreadsheet\Cell\DataType;
use PhpOffice\PhpSpreadsheet\Cell\Cell;

/**
 * Usage: /usr/bin/php -d memory_limit=-1 artisan location:location-import --truncate=1
 * Download excel file from https://danhmuchanhchinh.gso.gov.vn >> "scripts/don_vi_hanh_chinh_2025.xlsx"
 */
class LocationImporterCommand extends Command
{

    protected $logger = 'location-import'; // logger filename

    protected $signature = 'location:location-import
        {--truncate= :  truncate or not}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Import location ';

    public function handle()
    {
        try {
            $this->logger = apps_log_channel($this->logger);
            $excelFile = "scripts/don_vi_hanh_chinh_2025.xlsx";

            $truncate = $this->option('truncate');
            if ($truncate) {
                Schema::disableForeignKeyConstraints();
                Country::truncate();
                
                City::truncate();
                DB::table('cities_translations')->truncate();

                District::truncate();
                Ward::truncate();
                Schema::enableForeignKeyConstraints();
            }

            #region convert xlsx to csv to improve performance
            try {
                $csvFile = "scripts/location_import.csv";
                $inputFileType = IOFactory::identify(base_path($excelFile));
                $reader = IOFactory::createReader($inputFileType);

                $spreadsheet = $reader->load(base_path($excelFile));

                $writer = IOFactory::createWriter($spreadsheet, "Csv");
                $writer->setSheetIndex(0); // Select which sheet to export.
                $writer->setDelimiter(','); // Set delimiter.
                $writer->save(base_path($csvFile));
            } catch (\Throwable $th) {
                Log::channel($this->logger)->error(__CLASS__ . " " . __FUNCTION__, (array) [$th->getFile(), $th->getLine(), $th->getMessage()]);
            }
            #endregion

            $country = Country::firstOrCreate(
                ['code' =>  'VN'],
                ['id' => 1, 'name' => 'Việt Nam', 'nationality' => 'Việt Nam', 'order' => 1, 'is_default' => 1, 'status' => 'published', 'code' => 'VN']
            );
            if ($country->wasRecentlyCreated) {
                event(new ImportedCountryEvent($country->toArray(), $country));
            }

            // https://docs.laravel-excel.com/3.1/imports/custom-csv-settings.html
            Config::set('excel.imports.csv.input_encoding', 'UTF-8'); //gán input_encode thành UTF-8

            // DB::beginTransaction();
            $import = new LocationImport(
                $country
            );
            $import
                ->setLog($this->logger)
                ->import(base_path($csvFile));
            $failures = $import->failures();
            // DB::commit();

            $errors = $failures->map(function ($item) {
                return $item->errors();
            });

            $rows = $failures->map(function ($item) {
                return $item->row();
            });

            $this->info("Imported $csvFile");
            Log::channel($this->logger)->info("Imported $csvFile");
        } catch (\Throwable $th) {
            Log::channel($this->logger)->error(__CLASS__ . " " . __FUNCTION__, (array) [$th->getFile(), $th->getLine(), $th->getMessage()]);
        }
    }
}
