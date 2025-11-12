<?php

namespace Dev\Kernel\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

use Dev\Base\Casts\SafeContent;
use Dev\Base\Enums\BaseStatusEnum;
use Dev\Base\Models\BaseModel;
use Dev\Base\Models\Concerns\HasSlug;
use Dev\Kernel\Models\District;

class Ward extends BaseModel
{
    use HasSlug;

    protected $table = 'wards';

    protected $fillable = [
        'name',
        'code',
        'type',
        'district_id',
        'record_id',
        'image',
        'order',
        'is_default',
        'status',
    ];

    protected $casts = [
        'status' => BaseStatusEnum::class,
        'name' => SafeContent::class,
        'is_default' => 'bool',
        'order' => 'int',
    ];

    public function district(): BelongsTo
    {
        return $this->belongsTo(District::class)->withDefault();
    }
}
