<?php

namespace Platform\Kernel\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;

use Platform\Base\Casts\SafeContent;
use Platform\Base\Enums\BaseStatusEnum;
use Platform\Base\Models\BaseModel;
use Platform\Base\Models\Concerns\HasSlug;
use Platform\Kernel\Models\District;

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
