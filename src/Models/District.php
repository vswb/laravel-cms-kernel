<?php

namespace Dev\Kernel\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

use Dev\Base\Casts\SafeContent;
use Dev\Base\Enums\BaseStatusEnum;
use Dev\Base\Models\BaseModel;
use Dev\Base\Models\Concerns\HasSlug;
use Dev\Location\Models\City;

class District extends BaseModel
{
    use HasSlug;

    protected $table = 'districts';

    protected $fillable = [
        'name',
        'code',
        'type',
        'city_id',
        'record_id',
        'order',
        'is_default',
        'status'
    ];

    protected $casts = [
        'status' => BaseStatusEnum::class,
        'name' => SafeContent::class,
        'is_default' => 'bool',
        'order' => 'int',
    ];
    
    public function city(): BelongsTo
    {
        return $this->belongsTo(City::class)->withDefault();
    }
}
