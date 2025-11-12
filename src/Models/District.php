<?php

namespace Platform\Kernel\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

use Platform\Base\Casts\SafeContent;
use Platform\Base\Enums\BaseStatusEnum;
use Platform\Base\Models\BaseModel;
use Platform\Base\Models\Concerns\HasSlug;
use Platform\Location\Models\City;

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
