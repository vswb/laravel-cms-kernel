<?php
/**
 * (c) Copyright 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Distributed by: VISUAL WEBER CO., LTD.
 * * [PRODUCT INFORMATION]
 * This software is a proprietary product developed by Visual Weber.
 * All rights to the software and its components are reserved under 
 * Intellectual Property laws.
 * * [TERMS OF USE]
 * Usage is permitted strictly according to the License Agreement 
 * between Visual Weber and the Client.
 * -------------------------------------------------------------------------
 * (c) Bản quyền thuộc về CÔNG TY TNHH VISUAL WEBER 2026. Bảo lưu mọi quyền.
 * Phát hành bởi: Công ty TNHH Visual Weber.
 * * [THÔNG TIN SẢN PHẨM]
 * Phần mềm này là sản phẩm độc quyền được phát triển bởi Visual Weber.
 * Mọi quyền đối với phần mềm và các thành phần cấu thành đều được bảo hộ 
 * theo luật Sở hữu trí tuệ.
 * * [ĐIỀU KHOẢN SỬ DỤNG]
 * Việc sử dụng được giới hạn nghiêm ngặt theo Hợp đồng cung cấp dịch vụ/phần mềm 
 * giữa Visual Weber và Khách hàng.
 */


namespace Dev\Kernel\Traits;

use Dev\Language\Facades\Language;

use Dev\LanguageAdvanced\Supports\LanguageAdvancedManager;

/**
 * @deprecated 5.9
 */
trait LanguageAdvancedTrait
{
    public function scopeLanguageSearch($query)
    {
        // v2
        $model = $query->getModel();

        $currentLocale = Language::getCurrentLocaleCode();

        if ($currentLocale == Language::getDefaultLocaleCode()) {
            return $query;
        }

        if (!LanguageAdvancedManager::isSupported($model)) {
            return $query;
        }

        $table = $model->getTable();

        $translationTable = $table . '_translations';

        return $query->with([
            'translations' => function ($query) use ($translationTable, $currentLocale) {
                $query->where($translationTable . '.lang_code', $currentLocale);
            },
        ]);

        // v1
        // return $query->join('language_meta', 'language_meta.reference_id', "{$model->getTable()}.id")
        //     ->where('language_meta.reference_type', get_class($model))
        //     ->where('language_meta.lang_meta_code', \Language::getCurrentLocaleCode());
    }
}
