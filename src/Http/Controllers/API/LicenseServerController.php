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
        $domain = preg_replace('/^https?:\/\//', '', rtrim((string) $domain, '/'));

        // 1. Prioritize Server IP sent by client, fallback to request connection IP
        $ip = $request->input('server_ip') ?: ($request->header('LB-IP') ?: $request->ip());

        Log::channel($logger)->info("Core system update check from {$domain} ({$ip})", [
            'core_version' => $request->input('current_version'),
            'product_id' => $request->input('product_id'),
            'user_agent' => $request->userAgent(),
        ]);

        self::trackUsage($request, 'CORE_CHECK', [
            'core_version' => $request->input('core_version') ?: $request->input('current_version'),
        ]);

        return response()->json([
            'status' => true,
            'data' => null,
            'message' => 'Congratulations! Your core system is running the latest official version. Your platform is fully optimized for maximum performance and protected with the latest security enhancements.',
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
            'status' => true,
            'message' => 'Connection established successfully.',
        ]);
    }

    /**
     * Main logic to process heartbeat, log, notify Telegram, and return signed token.
     */
    protected function processHeartbeat(Request $request, string $type)
    {
        $logger = function_exists('apps_log_channel') ? apps_log_channel('license') : 'daily';

        $domain = $request->header('LB-URL') ?: $request->input('domain', $request->getHost());
        $domain = preg_replace('/^https?:\/\//', '', rtrim((string) $domain, '/'));

        // 1. Prioritize Server IP sent by client, fallback to request connection IP
        $ip = $request->input('server_ip') ?: ($request->header('LB-IP') ?: $request->ip());

        $licenseCode = $request->input('license_code') ?: $request->input('purchase_code');

        Log::channel($logger)->info("Incoming {$type} request from {$domain} ({$ip})");

        // Skip recording for self-requests
        if ($this->isSelfRequest($domain)) {
            Log::channel($logger)->debug("Skipping license recording for self-request from {$domain}");
            return response()->json([
                'status' => true,
                'message' => 'License processed (self-server bypass).',
                'lic_response' => '',
            ]);
        }

        $forensics = self::buildForensics($request, $type);

        // 2. Strict License File Verification (If provided)
        if ($request->has('license_file')) {
            try {
                $fileContent = base64_decode($request->input('license_file'));
                $decoded = json_decode($fileContent, true);
                
                if ($decoded && isset($decoded['signature'], $decoded['domain'], $decoded['expiry'])) {
                    $secret = 'VERIFY-' . config('core.base.general.api_key', LicenseRegistry::getLicenseKey());
                    $expectedSignature = hash_hmac('sha256', $decoded['domain'] . '|' . $decoded['expiry'], $secret);

                    // 1. Skip Legal Alerts for Development/Local environments
                    if ($this->isDevelopmentDomain($domain)) {
                         Log::channel($logger)->debug("Development domain detected ({$domain}), skipping legal check.");
                    } else {
                        // 2. Intelligent Domain Matching (Allow subdomains of the licensed domain)
                        $isOriginal = trim(strtolower($decoded['domain']));
                        $isCurrent  = trim(strtolower($domain));
                        
                        // Check if current is same as original OR a subdomain of original
                        $isMatch = ($isCurrent === $isOriginal) || (str_ends_with($isCurrent, '.' . $isOriginal));

                        if (!$isMatch) {
                            Log::channel($logger)->warning("UNLICENSED CLONE DETECTED! File belongs to {$isOriginal} but request came from {$isCurrent} ({$ip})");
                            
                            // Send legal alert for real production clones only
                            $this->notifyTelegram(array_merge($forensics, [
                                'legal_alert'     => true,
                                'original_domain' => $isOriginal,
                                'domain'          => $isCurrent,
                                'ip'              => $ip,
                                'type'            => 'LEGAL_DETECTION',
                                'license_code'    => $decoded['license_code'] ?? 'N/A',
                            ]));

                            return response()->json([
                                'status'       => true,
                                'message'      => 'Connection verified.',
                                'lic_response' => $request->input('license_file')
                            ]);
                        }
                    }

                    // 3. Passive Renewal: If it's a valid match, always return a fresh signed response to extend storage cache
                    if (hash_equals($expectedSignature, $decoded['signature'])) {
                        $licenseCode = $decoded['license_code'] ?? $licenseCode;
                        Log::channel($logger)->debug("Verified valid license for {$domain}. Issuing passive renewal.");
                    } else {
                        Log::channel($logger)->error("Tampered license file detected for {$domain}");
                    }
                }
            } catch (\Exception $e) {
                Log::channel($logger)->error("License file verification failed for {$domain}: " . $e->getMessage());
            }
        }

        // Manage license records in DB
        try {
            $existing = DB::table('licenses')->where('domain', $domain)->first();

            $data = [
                'ip' => $ip,
                'last_check_in' => now(),
                'status' => 'pending', // Requires audit
                'updated_at' => now(),
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
                $licenseId = (string) Str::uuid();
                $data['id'] = $licenseId;
                $data['domain'] = $domain;
                $data['created_at'] = now();
                DB::table('licenses')->insert($data);
            }

            self::recordHistory($domain, (string) $licenseId, $ip);

            Log::channel($logger)->debug("Successfully updated license record for {$domain}");
        } catch (\Exception $e) {
            Log::channel($logger)->error("Failed to update license DB for {$domain}: " . $e->getMessage());
        }

        // Notify Telegram (for monitoring clones/misuse)
        $this->notifyTelegram(array_merge($forensics, [
            'domain' => $domain,
            'ip' => $ip,
            'type' => $type,
            'product_id' => $request->input('product_id'),
            'license_code' => $licenseCode,
        ]));

        // Generate signed license content for client-side caching (.lic file)
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
        $logger = function_exists('apps_log_channel') ? apps_log_channel('license') : 'daily';

        if (!empty($data['legal_alert'])) {
            $message  = "⚖️ <b>LEGAL EVIDENCE DETECTED</b> ⚖️\n";
            $message .= "--------------------------\n";
            $message .= "🚩 <b>Unlicensed Domain:</b> <code>" . htmlspecialchars($data['domain'] ?? 'Unknown', ENT_QUOTES, 'UTF-8') . "</code>\n";
            $message .= "🔒 <b>Locked to Domain:</b> <code>" . htmlspecialchars($data['original_domain'] ?? 'Unknown', ENT_QUOTES, 'UTF-8') . "</code>\n";
            $message .= "🌐 <b>Server IP:</b> <code>" . htmlspecialchars($data['ip'] ?? 'N/A', ENT_QUOTES, 'UTF-8') . "</code>\n";
            $message .= "🚨 <b>Action:</b> Forwarding to Legal Department.\n";
        } else {
            $message  = "🚨 <b>LICENSING ALERT</b> 🚨\n";
            $message .= "--------------------------\n";
            $message .= "📍 <b>Domain:</b> <code>" . htmlspecialchars($data['domain'] ?? 'Unknown', ENT_QUOTES, 'UTF-8') . "</code>\n";
            $message .= "🌐 <b>IP:</b> <code>" . htmlspecialchars($data['ip'] ?? 'N/A', ENT_QUOTES, 'UTF-8') . "</code>\n";
        }

        // Thêm cảnh báo nếu IP này đang được dùng bởi các domain khác
        $ip = $data['ip'] ?? null;
        $isPublicIp = filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE);

        if ($ip && $isPublicIp) {
            $others = DB::table('licenses')
                ->where('ip', $ip)
                ->where('domain', '!=', $data['domain'] ?? '')
                ->pluck('domain')
                ->toArray();

            if (!empty($others)) {
                $message .= "⚠️ <b>Hệ thống phát hiện các Domain khác cùng IP này:</b>\n";
                foreach ($others as $other) {
                    $message .= "  • <code>" . htmlspecialchars($other, ENT_QUOTES, 'UTF-8') . "</code>\n";
                }
            }
        }

        $message .= "🔎 <b>Type:</b> " . htmlspecialchars($data['type'] ?? 'N/A', ENT_QUOTES, 'UTF-8') . "\n";
        $message .= "📦 <b>Product:</b> " . htmlspecialchars($data['product_id'] ?? 'N/A', ENT_QUOTES, 'UTF-8') . "\n";
        $message .= "🔑 <b>Code:</b> <code>" . htmlspecialchars($data['license_code'] ?? 'N/A', ENT_QUOTES, 'UTF-8') . "</code>\n";
        $message .= "📅 <b>Time:</b> " . htmlspecialchars($data['timestamp'] ?? now()->toDateTimeString(), ENT_QUOTES, 'UTF-8');

        if (function_exists('apps_telegram_send_message')) {
            apps_telegram_send_message([$message], 'pull', $this->logger ?? 'daily', [
                'chat_id' => '-1003519145353',
                'message_thread_id' => '2',
            ]);
        } else {
            $botToken = env('TELEGRAM_BOT_TOKEN');
            $chatId = env('TELEGRAM_CHAT_ID', '-1003519145353');
            $messageThreadId = env('TELEGRAM_MESSAGE_THREAD_ID', '2');

            if (!$botToken || !$chatId) {
                return;
            }

            try {
                $response = Http::post("https://api.telegram.org/bot{$botToken}/sendMessage", [
                    'chat_id' => $chatId,
                    'message_thread_id' => $messageThreadId,
                    'text' => $message,
                    'parse_mode' => 'HTML',
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
        $domain = preg_replace('/^https?:\/\//', '', rtrim((string) $domain, '/'));

        // 1. Prioritize Server IP sent by client, fallback to request connection IP
        $ip = $request->input('server_ip') ?: ($request->header('LB-IP') ?: $request->ip());

        if ($domain === 'Unknown' || empty($domain)) {
            $domain = $request->getHost();
        }

        // Skip recording for self-requests
        if ((new self)->isSelfRequest($domain)) {
            return;
        }

        $forensics = self::buildForensics($request, $type, $extra);

        try {
            $existing = DB::table('licenses')->where('domain', $domain)->first();

            $data = [
                'ip' => $ip,
                'last_check_in' => now(),
                'status' => 'tracked', // Just monitoring
                'updated_at' => now(),
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
                $licenseId = (string) Str::uuid();
                $data['id'] = $licenseId;
                $data['domain'] = $domain;
                $data['created_at'] = now();
                DB::table('licenses')->insert($data);
            }

            self::recordHistory($domain, (string) $licenseId, $ip);

            // Notify Telegram for suspicious or significant check-ins
            (new self)->notifyTelegram(array_merge($forensics, [
                'domain' => $domain,
                'ip' => $ip,
                'type' => $type,
                'product_id' => $request->input('product_id'),
                'license_code' => $request->input('license_code') ?: $request->input('purchase_code'),
                'timestamp' => now()->toDateTimeString(),
            ]));

            Log::channel($logger)->info("TrackUsage for {$domain} ({$ip})");

        } catch (\Exception $e) {
            Log::channel($logger)->error("trackUsage failed for {$domain}: " . $e->getMessage());
        }
    }

    /**
     * Record check-in history.
     */
    protected static function recordHistory(string $domain, string $licenseId, ?string $ip)
    {
        try {
            // Kiểm tra bản ghi gần nhất để tránh lưu trùng lặp dữ liệu không đổi
            $lastHistory = DB::table('license_histories')
                ->where('domain', $domain)
                ->orderBy('created_at', 'desc')
                ->first();

            // Nếu IP không đổi, không cần ghi thêm để tiết kiệm tài nguyên
            if ($lastHistory && $lastHistory->ip === $ip) {
                return;
            }

            DB::table('license_histories')->insert([
                'id' => (string) Str::uuid(),
                'license_id' => $licenseId,
                'domain' => $domain,
                'ip' => $ip,
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
     * Build forensics array for logging/Telegram purposes.
     */
    protected static function buildForensics(Request $request, string $type, array $extra = []): array
    {
        // 1. Only allow safe, non-sensitive fields from client
        $safeFields = [
            'core_version',
            'kernel_version',
            'php_version',
            'laravel_version',
            'server_software',
            'environment',
            'hostname',
            'server_ip',
            'timestamp',
            'product_id',
            'error',
        ];

        $data = array_merge($request->only($safeFields), [
            'type' => $type,
            'user_agent' => $request->userAgent(),
        ], $extra);

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

    /**
     * Identify if a domain is a local or development environment.
     */
    protected function isDevelopmentDomain(string $domain): bool
    {
        $domain = strtolower($domain);
        $devKeywords = [
            'localhost', '127.0.0.1', '.test', '.example', '.invalid', '.localhost',
            'staging.', 'dev.', 'test.', 'local.', 'demo.'
        ];

        foreach ($devKeywords as $keyword) {
            if (str_contains($domain, $keyword)) {
                return true;
            }
        }

        return false;
    }
}
