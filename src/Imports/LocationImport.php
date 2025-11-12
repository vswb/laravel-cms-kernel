<?php

namespace Dev\Kernel\Imports;

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
use Illuminate\Support\Collection;

use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\Importable;
use Maatwebsite\Excel\Concerns\WithStartRow;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;
use Maatwebsite\Excel\Concerns\WithChunkReading;
use Maatwebsite\Excel\Concerns\WithMultipleSheets;
use Maatwebsite\Excel\Concerns\OnEachRow;
use Maatwebsite\Excel\Concerns\SkipsFailures;
use Maatwebsite\Excel\Concerns\SkipsOnFailure;
use Maatwebsite\Excel\Concerns\SkipsOnError;
use Maatwebsite\Excel\Row;
use Maatwebsite\Excel\Concerns\WithColumnFormatting;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithCustomValueBinder;
use Maatwebsite\Excel\Concerns\WithEvents;
use Maatwebsite\Excel\Events\ImportFailed;
use Maatwebsite\Excel\Concerns\WithBatchInserts;

use Dev\Location\Models\Country;
use Dev\Location\Models\City;
use Dev\Location\Models\State;
use Dev\Kernel\Models\District;
use Dev\Kernel\Models\Ward;
use Dev\Location\Events\ImportedCityEvent;
use Dev\Location\Events\ImportedCountryEvent;
use Dev\Location\Events\ImportedStateEvent;
use Maatwebsite\Excel\Concerns\WithSkipDuplicates;
use Dev\Kernel\Jobs\LocationJob;

use PhpOffice\PhpSpreadsheet\Shared\Date;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;
use PhpOffice\PhpSpreadsheet\Cell\DefaultValueBinder;
use PhpOffice\PhpSpreadsheet\Cell\DataType;
use PhpOffice\PhpSpreadsheet\Cell\Cell;

class LocationImport extends DefaultValueBinder implements
    WithCustomValueBinder,
    ToModel,
    OnEachRow,
    WithStartRow,
    WithValidation,
    WithHeadingRow,
    WithChunkReading,
    SkipsOnFailure,
    WithColumnFormatting,
    WithBatchInserts,
    WithSkipDuplicates
{
    use Importable, SkipsFailures;

    public $logger = 'location-import'; // logger filename
    public $importedFile;

    /**
     * @var mixed
     */
    private $country;

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct($country)
    {
        $this->country = $country;
        $this->logger = apps_log_channel($this->logger);
    }

    public function setLog($logger)
    {
        $this->logger = apps_log_channel($logger); // validate/check and create new logger if needed;
        Log::channel($this->logger)->info("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        
        return $this;
    }

    #region override functions
    public function prepareForValidation($row, $index)
    {
        return $row;
    }

    public function rules(): array
    {
        return [];
    }

    public function customValidationMessages()
    {
        return [];
    }

    public function customValidationAttributes()
    {
        return [];
    }

    public function startRow(): int
    {
        return 2;
    }

    public function headingRow(): int
    {
        return 1;
    }

    public function onError(\Throwable $th)
    {
        throw $th;
    }

    public function chunkSize(): int
    {
        return 1000;
    }
    #endregion

    public function onRow(Row $row)
    {
        // $rowIndex = $row->getIndex();
        // $row      = $row->toArray();
    }

    public function columnFormats(): array
    {
        return []; // ['D' => '0']; // try this add '0' for specific columns you need to display the full number
    }

    public function bindValue(Cell $cell, $value)
    {
        // comment vì làm mất số 0 ở đầu số điện thoại!?
        // if (is_numeric($value)) {
        //     $value = number_format($value, 0, '', '');
        //     $cell->setValueExplicit($value, DataType::TYPE_NUMERIC);
        //     return true;
        // }

        // else return default behavior
        return parent::bindValue($cell, $value);
    }

    // public function registerEvents(): array
    // {
    //     return [
    //         ImportFailed::class => function (ImportFailed $event) {
    //             $this->importedBy->notify(new ImportHasFailedNotification);
    //         },
    //     ];
    // }

    public function batchSize(): int
    {
        return 1000;
    }

    /**
     * @param Collection $collection
     */
    public function model(array $row)
    {
        try {
            LocationJob::dispatch($row, $this->country);
        } catch (\Throwable $th) {
            Log::error(__FUNCTION__ . ": " . $th->getMessage());
        }
    }
}
