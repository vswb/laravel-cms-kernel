<?php

namespace Platform\Kernel\Seeders;

use Illuminate\Database\Seeder;

use Platform\Language\Repositories\Interfaces\LanguageInterface;
use Platform\Setting\Repositories\Interfaces\SettingInterface;

class SettingSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $settingResponsitory = app(SettingInterface::class);

        $settingResponsitory->createOrUpdate([
            'key' => 'admin_email',
            'value' => 'dev@fsofts.com'
        ], [
            'key' => 'admin_email'
        ]);
        $settingResponsitory->createOrUpdate([
            'key' => 'admin_title',
            'value' => 'A CMS Platform based on Laravel Framework! Make by Visual Weber Vietnam'
        ], [
            'key' => 'admin_title'
        ]);
        $settingResponsitory->createOrUpdate([
            'key' => 'theme--site_title',
            'value' => 'A CMS Platform based on Laravel Framework'
        ], [
            'key' => 'theme--site_title'
        ]);
        $settingResponsitory->createOrUpdate([
            'key' => 'theme--seo_title',
            'value' => 'A CMS Platform based on Laravel Framework'
        ], [
            'key' => 'theme--seo_title'
        ]);
        $settingResponsitory->createOrUpdate([
            'key' => 'theme--seo_description',
            'value' => 'A CMS Platform based on Laravel Framework - Descritpion'
        ], [
            'key' => 'theme--seo_description'
        ]);
        $settingResponsitory->createOrUpdate([
            'key' => 'time_zone',
            'value' => 'Asia/Ho_Chi_Minh'
        ], [
            'key' => 'time_zone'
        ]);
        $settingResponsitory->createOrUpdate([
            'key' => 'locale',
            'value' => 'en'
        ], [
            'key' => 'locale'
        ]);
        $settingResponsitory->createOrUpdate([
            'key' => 'theme--cookie_consent_enable',
            'value' => 'no'
        ], [
            'key' => 'theme--cookie_consent_enable'
        ]);
        $settingResponsitory->createOrUpdate([
            'key' => 'show_admin_bar',
            'value' => 0
        ], [
            'key' => 'show_admin_bar'
        ]);

        $languageRepository = app(LanguageInterface::class);

        $languageRepository->update(['lang_is_default' => 1], ['lang_is_default' => 0]);
        $language = $languageRepository->getFirstBy(['lang_id' => 2]);
        if ($language) {
            $language->lang_is_default = 1;
            $languageRepository->createOrUpdate($language);
        }
    }
}
