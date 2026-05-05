<?php

/**
 * © 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Proprietary software developed and distributed by Visual Weber.
 * Use is permitted only under a valid license agreement.
 *
 * © 2026 CÔNG TY TNHH VISUAL WEBER. Bảo lưu mọi quyền.
 * Phần mềm độc quyền của Visual Weber, chỉ được sử dụng theo Hợp đồng cấp phép.
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
            'core_version' => get_core_version() ?: 'unknown',
            'kernel_version' => 'v7.x-dev',
            'php_version' => PHP_VERSION,
            'laravel_version' => app()->version(),
            'environment' => app()->environment(),
            'timestamp' => now()->toDateTimeString(),
        ];
    }

    /**
     * Get the public IP address of the server.
     */
    protected static function getPublicIp(): string
    {
        return request()->ip() ?: '127.0.0.1';
    }

    /**
     * Get primary license server URL
     */
    public static function getLicenseServerUrl(): string
    {
        return '';
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
        return '';
    }
    /**
     * Get the marketplace API bridge URL
     */
    public static function getMarketplaceUrl(): string
    {
        return '';
    }
}
