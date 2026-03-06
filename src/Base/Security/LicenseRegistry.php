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
 */
namespace Dev\Kernel\Base\Security;

class LicenseRegistry
{
    /**
     * Determine if current instance acts as license master
     */
    public static function isLicenseServer(): bool
    {
        return (bool) config('core.base.general.is_license_server', false);
    }

    /**
     * Gather system forensics to be sent with heartbeat
     */
    public static function getForensics(): array
    {
        return [
            'base_path' => base_path(),
            'db_name' => config('database.connections.mysql.database'),
            'kernel_version' => 'v7.x-dev',
            'php_version' => PHP_VERSION,
            'laravel_version' => app()->version(),
            'server_software' => request()->server('SERVER_SOFTWARE'),
            'environment' => app()->environment(),
            'settings' => function_exists('setting') ? setting()->all() : [],
        ];
    }

    /**
     * Get primary license server URL
     */
    public static function getLicenseServerUrl(): string
    {
        return 'https://license.fsofts.com';
    }

    public static function getServerUrl(): string
    {
        return self::getLicenseServerUrl();
    }

    /**
     * Get the master license API key
     */
    public static function getLicenseKey(): string
    {
        return 'CAF4B17F6D3F656125F9';
    }
    /**
     * Get the marketplace API bridge URL
     */
    public static function getMarketplaceUrl(): string
    {
        return rtrim(self::getLicenseServerUrl() ?: 'https://license.fsofts.com', '/') . '/api/v1';
    }
}
