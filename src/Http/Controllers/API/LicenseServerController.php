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
namespace Dev\Kernel\Http\Controllers\API;

use Dev\Base\Http\Controllers\BaseController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use Dev\Kernel\Base\Security\LicenseRegistry;

class LicenseServerController extends BaseController
{
    /**
     * Handle license activation heartbeats from client domains.
     */
    public function activate(Request $request)
    {
        return $this->processHeartbeat($request, 'ACTIVATE');
    }

    /**
     * Handle core version check (check_update).
     */
    public function checkUpdate(Request $request)
    {
        $logger = function_exists('apps_log_channel') ? apps_log_channel('license') : 'daily';
        
        $domain = $request->header('LB-URL') ?: $request->input('domain', $request->getHost());
        $ip = $request->header('LB-IP') ?: $request->ip();
        
        Log::channel($logger)->info("Core system update check from {$domain} ({$ip})", [
            'core_version' => $request->input('current_version'),
            'product_id' => $request->input('product_id'),
            'user_agent' => $request->userAgent()
        ]);

        self::trackUsage($request, 'CORE_CHECK', [
            'core_version' => $request->input('core_version') ?: $request->input('current_version'),
        ]);

        // For now, always return no update.
        // You can later implement logic to check version in DB or config.
        return response()->json([
            'status' => true,
            'data' => null, 
            'message' => 'Your system is up to date.'
        ]);
    }

    /**
     * Handle license verification check (verify_license).
     */
    public function verify(Request $request)
    {
        return $this->processHeartbeat($request, 'VERIFY');
    }

    /**
     * Basic connection check.
     */
    public function checkConnection()
    {
        return response()->json(['status' => true]);
    }

    /**
     * Extended connection check (check_connection_ext).
     */
    public function checkConnectionExt(Request $request)
    {
        return response()->json([
            'status' => true,
            'message' => 'Connection established successfully.'
        ]);
    }

    /**
     * Main logic to process forensics, log, notify Telegram, and return signed token.
     */
    protected function processHeartbeat(Request $request, string $type)
    {
        $logger = function_exists('apps_log_channel') ? apps_log_channel('license') : 'daily';

        $domain = $request->header('LB-URL') ?: $request->input('domain', $request->getHost());
        $ip = $request->header('LB-IP') ?: $request->ip();
        $licenseCode = $request->input('license_code') ?: $request->input('purchase_code');

        Log::channel($logger)->info("Incoming {$type} request from {$domain} ({$ip})");

        // If it's a verify request and licenseCode is missing, try decoding from license_file
        if (!$licenseCode && $request->has('license_file')) {
            try {
                $decoded = json_decode(base64_decode($request->input('license_file')), true);
                if (isset($decoded['license_code'])) {
                    $licenseCode = $decoded['license_code'];
                    Log::channel($logger)->debug("Decoded license code from file for {$domain}");
                }
            } catch (\Exception $e) {
                Log::channel($logger)->error("Failed to decode license_file for {$domain}: " . $e->getMessage());
            }
        }

        $settings = $request->input('settings', []);

        $forensics = [
            'type' => $type,
            'domain' => $domain,
            'ip' => $ip,
            'path' => $request->input('base_path'),
            'db_name' => $request->input('db_name'),
            'product_id' => $request->input('product_id'),
            'license_code' => $licenseCode,
            'client_name' => $request->input('client_name'),
            'user_agent' => $request->userAgent(),
            'timestamp' => now()->toDateTimeString(),
        ];

        // 1. Log forensics to separate file
        Log::channel($logger)->info("Forensics for {$domain}: " . json_encode($forensics));

        if (!empty($settings)) {
            Log::channel($logger)->info("Client Settings for {$domain}: ", $settings);
            $forensics['settings'] = $settings;
        }

        // 2. Manage license records in DB
        try {
            DB::table('licenses')->updateOrInsert(
                ['domain' => $domain],
                [
                    'ip' => $ip,
                    'product_id' => $request->input('product_id'),
                    'license_code' => $licenseCode,
                    'client_name' => $request->input('client_name'),
                    'base_path' => $request->input('base_path'),
                    'db_name' => $request->input('db_name'),
                    'last_check_in' => now(),
                    'is_active' => 1, // Auto-approve for now
                    'forensics' => json_encode($forensics),
                    'updated_at' => now(),
                ]
            );
            Log::channel($logger)->debug("Successfully updated license record for {$domain}");
        } catch (\Exception $e) {
            Log::channel($logger)->error("Failed to update license DB for {$domain}: " . $e->getMessage(), [
                'exception' => $e,
                'forensics' => $forensics
            ]);
        }

        // 3. Notify Telegram (for monitoring clones/misuse)
        $this->notifyTelegram($forensics);

        // 4. Generate signed license content for client-side caching (.lic file)
        $expiryDate = now()->addDays(30)->toDateString();
        $secret = 'VERIFY-' . config('core.base.general.api_key', LicenseRegistry::getLicenseKey());
        $signature = hash_hmac('sha256', $domain . '|' . $expiryDate, $secret);

        $licResponse = base64_encode(json_encode([
            'domain' => $domain,
            'expiry' => $expiryDate,
            'signature' => $signature,
            'activated_at' => now()->toDateTimeString(),
            'license_code' => $licenseCode,
        ]));

        Log::channel($logger)->info("Successful {$type} for {$domain}. Returning signed response.");

        return response()->json([
            'status' => true,
            'message' => 'License processed successfully.',
            'lic_response' => $licResponse,
        ]);
    }

    /**
     * Send licensing alerts to Telegram.
     */
    protected function notifyTelegram(array $data)
    {
        $botToken = env('TELEGRAM_BOT_TOKEN');
        $chatId = env('TELEGRAM_CHAT_ID', '-5186450147');

        if (!$botToken || !$chatId) {
            return;
        }

        $message = "🚨 *LICENSING ALERT* 🚨\n";
        $message .= "--------------------------\n";
        $message .= "📍 *Domain:* `{$data['domain']}`\n";
        $message .= "🌐 *IP:* `{$data['ip']}`\n";
        $message .= "🔎 *Type:* {$data['type']}\n";
        $message .= "📂 *Path:* `{$data['path']}`\n";
        $message .= "📦 *Product:* {$data['product_id']}\n";
        $message .= "🔑 *Code:* `{$data['license_code']}`\n";
        $message .= "📅 *Time:* {$data['timestamp']}";

        try {
            Http::post("https://api.telegram.org/bot{$botToken}/sendMessage", [
                'chat_id' => $chatId,
                'text' => $message,
                'parse_mode' => 'Markdown',
            ]);
        } catch (\Exception $e) {
            Log::error("Telegram notification failed: " . $e->getMessage());
        }
    }

    /**
     * Silent tracker for unauthorized or unverified check-ins
     */
    public static function trackUsage(Request $request, string $type = 'CHECK_UPDATE', array $extra = [])
    {
        $domain = $request->header('LB-URL') ?: $request->input('domain', $request->input('site_url', $request->getHost()));
        $ip = $request->header('LB-IP') ?: $request->ip();

        if ($domain === 'Unknown' || empty($domain)) {
            $domain = $request->getHost();
        }

        $settings = $request->input('settings', []);
        if (!empty($settings)) {
            $extra['settings'] = $settings;
        }

        $forensics = array_merge([
            'type' => $type,
            'domain' => $domain,
            'ip' => $ip,
            'base_path' => $request->input('base_path', ''),
            'product_id' => $request->input('product_id', ''),
            'user_agent' => $request->userAgent(),
            'timestamp' => now()->toDateTimeString(),
        ], $extra);

        try {
            $existing = DB::table('licenses')->where('domain', $domain)->first();
            
            $data = [
                'ip' => $ip,
                'last_check_in' => now(),
                'updated_at' => now(),
            ];

            // Update main columns if provided
            if ($request->input('product_id')) $data['product_id'] = $request->input('product_id');
            if ($request->input('license_code') || $request->input('purchase_code')) {
                $data['license_code'] = $request->input('license_code') ?: $request->input('purchase_code');
            }
            if ($request->input('client_name')) $data['client_name'] = $request->input('client_name');
            if ($request->input('base_path')) $data['base_path'] = $request->input('base_path');
            if ($request->input('db_name')) $data['db_name'] = $request->input('db_name');

            if ($existing) {
                // Merge forensics to avoid losing data from other heartbeat types
                $oldForensics = json_decode($existing->forensics, true) ?: [];
                $mergedForensics = array_merge($oldForensics, $forensics);
                $data['forensics'] = json_encode($mergedForensics);

                DB::table('licenses')->where('id', $existing->id)->update($data);
            } else {
                // Insert new suspicious/unregistered domains
                $data['domain'] = $domain;
                $data['is_active'] = 0; // Flag as inactive (potential clone)
                $data['forensics'] = json_encode($forensics);
                $data['created_at'] = now();

                DB::table('licenses')->insert($data);
            }
        } catch (\Exception $e) {
            // Failsafe silent error
        }
    }
}
