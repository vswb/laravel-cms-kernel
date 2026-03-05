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
namespace Dev\Kernel\Seeders;

use Illuminate\Database\Seeder;

use Dev\Language\Repositories\Interfaces\LanguageInterface;
use Dev\Setting\Repositories\Interfaces\SettingInterface;

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
