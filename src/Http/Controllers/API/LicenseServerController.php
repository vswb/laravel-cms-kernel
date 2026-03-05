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
     * Handle license verification heartbeats.
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
     * Main logic to process forensics, log, notify Telegram, and return signed token.
     */
    protected function processHeartbeat(Request $request, string $type)
    {
        $domain = $request->header('LB-URL') ?: $request->input('domain', $request->getHost());
        $ip = $request->header('LB-IP') ?: $request->ip();
        $licenseCode = $request->input('license_code') ?: $request->input('purchase_code'); // Try both

        // If it's a verify request and licenseCode is missing, try decoding from license_file
        if (!$licenseCode && $request->has('license_file')) {
            try {
                $decoded = json_decode(base64_decode($request->input('license_file')), true);
                if (isset($decoded['license_code'])) {
                    $licenseCode = $decoded['license_code'];
                }
            } catch (\Exception $e) {
            }
        }

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
        Log::channel('license')->info("License Heartbeat: " . json_encode($forensics));

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
                    'is_active' => 1, // Auto-approve for now based on user request
                    'forensics' => json_encode($forensics),
                    'updated_at' => now(),
                ]
            );
        } catch (\Exception $e) {
            Log::error("Failed to update license DB: " . $e->getMessage());
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
        $chatId = env('TELEGRAM_CHAT_ID');

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
}
