<?php

namespace Platform\Kernel\Traits;

use Platform\Language\Facades\Language;

use Platform\LanguageAdvanced\Supports\LanguageAdvancedManager;

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
