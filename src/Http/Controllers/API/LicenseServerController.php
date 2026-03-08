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
use Illuminate\Support\Str;
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
        $domain = preg_replace('/^https?:\/\//', '', rtrim((string)$domain, '/'));
        $ip = $request->header('LB-IP') ?: $request->ip();

        Log::channel($logger)->info("Core system update check from {$domain} ({$ip})", [
            'core_version' => $request->input('current_version'),
            'product_id'   => $request->input('product_id'),
            'user_agent'   => $request->userAgent(),
        ]);

        self::trackUsage($request, 'CORE_CHECK', [
            'core_version' => $request->input('core_version') ?: $request->input('current_version'),
        ]);

        return response()->json([
            'status'  => true,
            'data'    => null,
            'message' => 'Your system is up to date.',
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
    public function checkConnection(Request $request)
    {
        self::trackUsage($request, 'CONNECTION_CHECK');
        return response()->json(['status' => true]);
    }

    /**
     * Extended connection check (check_connection_ext).
     */
    public function checkConnectionExt(Request $request)
    {
        self::trackUsage($request, 'CONNECTION_CHECK_EXT');
        return response()->json([
            'status'  => true,
            'message' => 'Connection established successfully.',
        ]);
    }

    /**
     * Main logic to process heartbeat, log, notify Telegram, and return signed token.
     */
    protected function processHeartbeat(Request $request, string $type)
    {
        $logger = function_exists('apps_log_channel') ? apps_log_channel('license') : 'daily';

        $domain      = $request->header('LB-URL') ?: $request->input('domain', $request->getHost());
        $domain      = preg_replace('/^https?:\/\//', '', rtrim((string)$domain, '/'));
        $ip          = $request->header('LB-IP') ?: $request->ip();
        $licenseCode = $request->input('license_code') ?: $request->input('purchase_code');

        Log::channel($logger)->info("Incoming {$type} request from {$domain} ({$ip})");

        // Skip recording for self-requests
        if ($this->isSelfRequest($domain)) {
            Log::channel($logger)->debug("Skipping license recording for self-request from {$domain}");
            return response()->json([
                'status'       => true,
                'message'      => 'License processed (self-server bypass).',
                'lic_response' => '',
            ]);
        }

        // If licenseCode is missing, try decoding from license_file
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

        // Build slim forensics for logging/Telegram only — NOT stored to DB
        $forensics = self::buildForensics($request, $type);

        Log::channel($logger)->info("Forensics for {$domain}: " . json_encode($forensics));

        // Manage license records in DB
        try {
            $existing = DB::table('licenses')->where('domain', $domain)->first();

            $data = [
                'ip'           => $ip,
                'last_check_in' => now(),
                'is_active'    => 1,
                'updated_at'   => now(),
            ];

            if ($request->input('product_id'))
                $data['product_id'] = $request->input('product_id');
            if ($licenseCode)
                $data['license_code'] = $licenseCode;
            if ($request->input('client_name'))
                $data['client_name'] = $request->input('client_name');

            if ($existing) {
                $licenseId = $existing->id ?: (string) Str::uuid();
                if (empty($existing->id)) {
                    $data['id'] = $licenseId;
                    DB::table('licenses')->where('domain', $domain)->update($data);
                } else {
                    DB::table('licenses')->where('id', $licenseId)->update($data);
                }
            } else {
                $licenseId          = (string) Str::uuid();
                $data['id']         = $licenseId;
                $data['domain']     = $domain;
                $data['created_at'] = now();
                DB::table('licenses')->insert($data);
            }

            // Record minimal check-in history (no sensitive data stored)
            self::recordHistory($domain, (string) $licenseId, $ip, $request->input('base_path'));

            Log::channel($logger)->debug("Successfully updated license record for {$domain}");
        } catch (\Exception $e) {
            Log::channel($logger)->error("Failed to update license DB for {$domain}: " . $e->getMessage());
        }

        // Notify Telegram (for monitoring clones/misuse)
        $this->notifyTelegram(array_merge($forensics, [
            'domain'       => $domain,
            'ip'           => $ip,
            'type'         => $type,
            'product_id'   => $request->input('product_id'),
            'license_code' => $licenseCode,
            'path'         => $request->input('base_path'),
        ]));

        // Generate signed license content for client-side caching (.lic file)
        $expiryDate = now()->addDays(30)->toDateString();
        $secret     = 'VERIFY-' . config('core.base.general.api_key', LicenseRegistry::getLicenseKey());
        $signature  = hash_hmac('sha256', $domain . '|' . $expiryDate, $secret);

        $licResponse = base64_encode(json_encode([
            'domain'       => $domain,
            'expiry'       => $expiryDate,
            'signature'    => $signature,
            'activated_at' => now()->toDateTimeString(),
            'license_code' => $licenseCode,
        ]));

        Log::channel($logger)->info("Successful {$type} for {$domain}. Returning signed response.");

        return response()->json([
            'status'       => true,
            'message'      => 'License processed successfully.',
            'lic_response' => $licResponse,
        ]);
    }

    /**
     * Send licensing alerts to Telegram.
     */
    protected function notifyTelegram(array $data)
    {
        $logger = function_exists('apps_log_channel') ? apps_log_channel('license') : 'daily';

        $message  = "🚨 <b>LICENSING ALERT</b> 🚨\n";
        $message .= "--------------------------\n";
        $message .= "📍 <b>Domain:</b> <code>" . htmlspecialchars($data['domain'] ?? 'Unknown', ENT_QUOTES, 'UTF-8') . "</code>\n";
        $message .= "🌐 <b>IP:</b> <code>" . htmlspecialchars($data['ip'] ?? 'N/A', ENT_QUOTES, 'UTF-8') . "</code>\n";
        $message .= "🔎 <b>Type:</b> " . htmlspecialchars($data['type'] ?? 'N/A', ENT_QUOTES, 'UTF-8') . "\n";
        $message .= "📂 <b>Path:</b> <code>" . htmlspecialchars($data['path'] ?? 'N/A', ENT_QUOTES, 'UTF-8') . "</code>\n";
        $message .= "📦 <b>Product:</b> " . htmlspecialchars($data['product_id'] ?? 'N/A', ENT_QUOTES, 'UTF-8') . "\n";
        $message .= "🔑 <b>Code:</b> <code>" . htmlspecialchars($data['license_code'] ?? 'N/A', ENT_QUOTES, 'UTF-8') . "</code>\n";
        $message .= "📅 <b>Time:</b> " . htmlspecialchars($data['timestamp'] ?? now()->toDateTimeString(), ENT_QUOTES, 'UTF-8');

        if (function_exists('apps_telegram_send_message')) {
            apps_telegram_send_message([$message], 'pull', $this->logger ?? 'daily', [
                'chat_id'           => '-1003519145353',
                'message_thread_id' => '2',
            ]);
        } else {
            $botToken        = env('TELEGRAM_BOT_TOKEN');
            $chatId          = env('TELEGRAM_CHAT_ID', '-1003519145353');
            $messageThreadId = env('TELEGRAM_MESSAGE_THREAD_ID', '2');

            if (!$botToken || !$chatId) {
                return;
            }

            try {
                $response = Http::post("https://api.telegram.org/bot{$botToken}/sendMessage", [
                    'chat_id'           => $chatId,
                    'message_thread_id' => $messageThreadId,
                    'text'              => $message,
                    'parse_mode'        => 'HTML',
                ]);

                if (!$response->successful()) {
                    Log::channel($logger)->error("Telegram API returned error for {$data['domain']}: " . $response->body());
                }
            } catch (\Exception $e) {
                Log::error("Telegram notification failed: " . $e->getMessage());
            }
        }
    }

    /**
     * Silent tracker for unauthorized or unverified check-ins.
     */
    public static function trackUsage(Request $request, string $type = 'CHECK_UPDATE', array $extra = [])
    {
        $logger = function_exists('apps_log_channel') ? apps_log_channel('license') : 'daily';

        $domain = $request->header('LB-URL') ?: $request->input('domain', $request->input('site_url', $request->getHost()));
        $domain = preg_replace('/^https?:\/\//', '', rtrim((string)$domain, '/'));
        $ip     = $request->header('LB-IP') ?: $request->ip();

        if ($domain === 'Unknown' || empty($domain)) {
            $domain = $request->getHost();
        }

        // Skip recording for self-requests
        if ((new self)->isSelfRequest($domain)) {
            return;
        }

        // Build slim forensics for logging/Telegram only — NOT stored to DB
        $forensics = self::buildForensics($request, $type, $extra);

        try {
            $existing = DB::table('licenses')->where('domain', $domain)->first();

            $data = [
                'ip'           => $ip,
                'last_check_in' => now(),
                'updated_at'   => now(),
            ];

            if ($request->input('product_id'))
                $data['product_id'] = $request->input('product_id');
            if ($request->input('license_code') || $request->input('purchase_code'))
                $data['license_code'] = $request->input('license_code') ?: $request->input('purchase_code');
            if ($request->input('client_name'))
                $data['client_name'] = $request->input('client_name');

            if ($existing) {
                $licenseId = $existing->id ?: (string) Str::uuid();
                if (empty($existing->id)) {
                    $data['id'] = $licenseId;
                    DB::table('licenses')->where('domain', $domain)->update($data);
                } else {
                    DB::table('licenses')->where('id', $licenseId)->update($data);
                }
            } else {
                $licenseId          = (string) Str::uuid();
                $data['id']         = $licenseId;
                $data['domain']     = $domain;
                $data['is_active']  = 0;
                $data['created_at'] = now();
                DB::table('licenses')->insert($data);
            }

            // Record minimal check-in history (no sensitive data stored)
            self::recordHistory($domain, (string) $licenseId, $ip, $request->input('base_path'));

            // Notify Telegram for suspicious or significant check-ins
            (new self)->notifyTelegram(array_merge($forensics, [
                'domain'       => $domain,
                'ip'           => $ip,
                'type'         => $type,
                'product_id'   => $request->input('product_id'),
                'license_code' => $request->input('license_code') ?: $request->input('purchase_code'),
                'path'         => $request->input('base_path'),
                'timestamp'    => now()->toDateTimeString(),
            ]));

            Log::channel($logger)->info("TrackUsage for {$domain}: " . json_encode($forensics));

        } catch (\Exception $e) {
            Log::channel($logger)->error("trackUsage failed for {$domain}: " . $e->getMessage());
        }
    }

    /**
     * Record minimal check-in history.
     * Only stores: domain, license_id, ip, base_path.
     * No sensitive client data (settings/forensics) is persisted.
     */
    protected static function recordHistory(string $domain, string $licenseId, ?string $ip, ?string $basePath)
    {
        try {
            DB::table('license_histories')->insert([
                'id'         => (string) Str::uuid(),
                'license_id' => $licenseId,
                'domain'     => $domain,
                'ip'         => $ip,
                'base_path'  => $basePath,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $logger = function_exists('apps_log_channel') ? apps_log_channel('license') : 'daily';
            Log::channel($logger)->info("Recorded check-in history for {$domain}");
        } catch (\Exception $e) {
            Log::error("Failed to record license history for {$domain}: " . $e->getMessage());
        }
    }

    /**
     * Build slim forensics array for logging/Telegram purposes.
     * This data is NEVER stored in the database.
     */
    protected static function buildForensics(Request $request, string $type, array $extra = []): array
    {
        $data = array_merge($request->except([
            'license_file', '_token', '_method', '_url',
            'license_code', 'purchase_code', 'client_name',
            'domain', 'site_url', 'domain_name',
        ]), [
            'type'       => $type,
            'user_agent' => $request->userAgent(),
        ], $extra);

        // Remove null/empty values
        return array_filter($data, fn($v) => !is_null($v) && $v !== '');
    }

    /**
     * Check if the request is from the server itself.
     */
    protected function isSelfRequest(string $domain): bool
    {
        if (!LicenseRegistry::isLicenseServer()) {
            return false;
        }

        $serverDomain = parse_url(config('app.url'), PHP_URL_HOST);

        return $domain === $serverDomain || $domain === request()->getHost();
    }
}
