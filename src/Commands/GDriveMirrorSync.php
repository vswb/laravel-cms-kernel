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


/**
 * GOOGLE DRIVE API SETUP GUIDES:
 * 1. How to get Client ID and Secret: https://github.com/ivanvermeyen/laravel-google-drive-demo/blob/master/README/1-getting-your-dlient-id-and-secret.md
 * 2. How to get Refresh Token: https://github.com/ivanvermeyen/laravel-google-drive-demo/blob/master/README/2-getting-your-refresh-token.md
 * 3. How to get Root Folder ID: https://github.com/ivanvermeyen/laravel-google-drive-demo/blob/master/README/3-getting-your-root-folder-id.md
 */

namespace Dev\Kernel\Commands;

use Google\Client;
use Google\Service\Drive;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class GDriveMirrorSync extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'gdrive:mirror:sync
        {folders* : specific folders on Google Drive to mirror, e.g., 2022 2023}
        {--force : Force download all files even if they haven\'t changed}
        {--delete : Delete local files/folders that no longer exist on Google Drive}
        {--retry=3 : Number of retries for each file operation on network failure}';

    /**
     * The console command description.
     */
    protected $description = 'Mirror GDrive to Local (Google Docs to MS Office) with Delta Sync, Streaming, and Retries.';

    protected $log_channel = 'daily';

    /**
     * Google Native MimeTypes to Microsoft Office (OpenXML) Formats
     */
    protected $exportMap = [
        'application/vnd.google-apps.document'   => ['ext' => 'docx', 'mime' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
        'application/vnd.google-apps.spreadsheet' => ['ext' => 'xlsx', 'mime' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
        'application/vnd.google-apps.presentation' => ['ext' => 'pptx', 'mime' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation'],
        'application/vnd.google-apps.drawing'      => ['ext' => 'png',  'mime' => 'image/png'],
        'application/vnd.google-apps.script'       => ['ext' => 'json', 'mime' => 'application/vnd.google-apps.script+json'],
    ];

    /**
     * Helper to get setting from DB (fallback to ENV)
     */
    protected function getGdriveSetting($key, $envKey)
    {
        if (function_exists('setting')) {
            $val = setting($key);
            if ($val !== null && $val !== '') {
                return $val;
            }
        }
        return env($envKey);
    }

    /**
     * Execute the console command.
     */
    public function handle()
    {
        set_time_limit(0); 

        try {
            // 1. Initial Checks
            $isEnabled = $this->getGdriveSetting('social_login_google_drive_enable', 'GOOGLE_DRIVE_ENABLED');
            if (in_array($isEnabled, ['0', 0, false, 'false'], true)) {
                $this->warn("⚠️ GDrive Mirror Sync is disabled.");
                return Command::FAILURE;
            }

            // 2. Prepare Dynamic Disk Configuration
            $this->initGoogleDisk();

            $baseLocalPath = storage_path('app/google_drive_mirror');
            $googleDisk = Storage::disk("google_drive_mirror");
            $targetFolders = (array) $this->argument('folders');

            $stats = ['processed' => 0, 'updated' => 0, 'skipped' => 0, 'deleted' => 0, 'errors' => 0, 'folders' => 0];

            foreach ($targetFolders as $baseFolder) {
                $this->info("\n🚀 SCANNING GOOGLE DRIVE: {$baseFolder}");
                Log::channel($this->log_channel)->info("GDrive Sync Started: {$baseFolder}");

                // Fetch remote items
                $this->info("Fetching remote item list (Recursive)...");
                $iterator = $googleDisk->listContents($baseFolder, true);
                $remoteItems = []; 
                foreach ($iterator as $item) {
                    $remoteItems[$item['path']] = $item;
                }

                $totalItems = count($remoteItems);
                $this->info("Found {$totalItems} items. Starting synchronization...");

                $bar = $this->output->createProgressBar($totalItems);
                $bar->start();

                foreach ($remoteItems as $relativePath => $item) {
                    $stats['processed']++;
                    $absoluteLocalPath = "{$baseLocalPath}/{$relativePath}";
                    $type = $item['type'];

                    if ($type === 'dir') {
                        if (!File::isDirectory($absoluteLocalPath)) {
                            File::makeDirectory($absoluteLocalPath, 0755, true);
                            $stats['folders']++;
                        }
                        $bar->advance();
                        continue;
                    }

                    // FILE SYNC LOGIC
                    if ($type === 'file') {
                        $meta = method_exists($item, 'extraMetadata') ? $item->extraMetadata() : $item;
                        $mimeType = $meta['mimeType'] ?? '';
                        $remoteTimestamp = $item['timestamp'] ?? ($item instanceof \League\Flysystem\StorageAttributes ? $item->lastModified() : 0);
                        
                        // Decide target path (Normal vs Export)
                        $targetLocalPath = $absoluteLocalPath;
                        $exportSpec = $this->exportMap[$mimeType] ?? null;
                        if ($exportSpec) {
                            $targetLocalPath = $absoluteLocalPath . '.' . $exportSpec['ext'];
                        }

                        // Delta Sync Check
                        if (!$this->option('force') && File::exists($targetLocalPath)) {
                            if (File::lastModified($targetLocalPath) >= $remoteTimestamp) {
                                $stats['skipped']++;
                                $bar->advance();
                                continue;
                            }
                        }

                        // Download/Export with Retry Logic
                        $success = $this->withRetry(function() use ($googleDisk, $relativePath, $targetLocalPath, $exportSpec, $meta) {
                            File::ensureDirectoryExists(dirname($targetLocalPath));
                            
                            if ($exportSpec) {
                                // Export Google Native File
                                $service = $googleDisk->getAdapter()->getService();
                                $response = $service->files->export($meta['id'], $exportSpec['mime'], ['alt' => 'media']);
                                File::put($targetLocalPath, $response->getBody()->getContents());
                            } else {
                                // Stream Download for regular files (Memory Efficient)
                                $readStream = $googleDisk->readStream($relativePath);
                                if ($readStream) {
                                    $writeStream = fopen($targetLocalPath, 'w');
                                    stream_copy_to_stream($readStream, $writeStream);
                                    fclose($writeStream);
                                    if (is_resource($readStream)) fclose($readStream);
                                } else {
                                    throw new \Exception("Could not open read stream for {$relativePath}");
                                }
                            }
                            return true;
                        });

                        if ($success) {
                            @touch($targetLocalPath, $remoteTimestamp);
                            $stats['updated']++;
                        } else {
                            $stats['errors']++;
                        }
                    }
                    $bar->advance();
                }
                $bar->finish();
                $this->info("");

                // CLEANUP LOGIC
                if ($this->option('delete')) {
                    $this->cleanupOrphans($baseLocalPath, $baseFolder, $remoteItems, $stats);
                }
            }

            $this->finalReport($stats, $baseLocalPath);

        } catch (\Throwable $th) {
            $this->error("\n💥 Fatal Error: " . $th->getMessage());
            Log::channel($this->log_channel)->error("GDrive Mirror Fatal Exception", ['msg' => $th->getMessage()]);
            return Command::FAILURE;
        }

        return Command::SUCCESS;
    }

    /**
     * Wrapper for retry logic
     */
    protected function withRetry(callable $callback)
    {
        $maxRetries = (int) $this->option('retry');
        $attempts = 0;

        while ($attempts <= $maxRetries) {
            try {
                return $callback();
            } catch (\Throwable $e) {
                $attempts++;
                if ($attempts > $maxRetries) {
                    return false;
                }
                Log::channel($this->log_channel)->warning("GDrive Sync Attempt {$attempts} failed. Retrying...", ['msg' => $e->getMessage()]);
                sleep(1); 
            }
        }
        return false;
    }

    /**
     * Initializing the Google Drive Disk Config
     */
    protected function initGoogleDisk()
    {
        $config = [
            'driver' => 'google',
            'clientId' => $this->getGdriveSetting('social_login_google_drive_client_id', 'GOOGLE_DRIVE_CLIENT_ID'),
            'clientSecret' => $this->getGdriveSetting('social_login_google_drive_client_secret', 'GOOGLE_DRIVE_CLIENT_SECRET'),
            'refreshToken' => $this->getGdriveSetting('social_login_google_drive_refresh_token', 'GOOGLE_DRIVE_REFRESH_TOKEN'),
            'folder' => $this->getGdriveSetting('social_login_google_drive_folder', 'GOOGLE_DRIVE_ROOT_FOLDER'),
            'teamDriveId' => $this->getGdriveSetting('social_login_google_drive_team_drive_id', 'GOOGLE_DRIVE_TEAM_DRIVE_ID'),
            'root' => storage_path(''),
        ];
        config(['filesystems.disks.google_drive_mirror' => $config]);
    }

    /**
     * Delete files locally that are no longer on Drive
     */
    protected function cleanupOrphans($basePath, $baseFolder, $remoteItems, &$stats)
    {
        $this->info("Cleaning up local orphans for '{$baseFolder}'...");
        $localFolder = "{$basePath}/{$baseFolder}";
        if (!File::isDirectory($localFolder)) return;

        $localFiles = File::allFiles($localFolder);
        foreach ($localFiles as $file) {
            $fullPath = $file->getRealPath();
            $relativePath = Str::after($fullPath, $basePath . '/');

            // Handle Office extensions when matching against remote original path
            $checkPath = $relativePath;
            foreach ($this->exportMap as $mime => $spec) {
                if (Str::endsWith($relativePath, '.' . $spec['ext'])) {
                    $potentialOriginal = Str::beforeLast($relativePath, '.' . $spec['ext']);
                    if (isset($remoteItems[$potentialOriginal])) {
                        $checkPath = $potentialOriginal;
                        break;
                    }
                }
            }

            if (!isset($remoteItems[$checkPath])) {
                File::delete($fullPath);
                $stats['deleted']++;
                $this->line("🗑️ Deleted local orphan: {$relativePath}");
            }
        }
    }

    protected function finalReport($stats, $baseLocalPath)
    {
        $this->info("\n" . str_repeat("=", 50));
        $this->info("✨ MIRROR SYNC COMPLETED");
        $this->info(str_repeat("=", 50));
        $this->comment("📂 Folders Created:  {$stats['folders']}");
        $this->comment("✅ Files Updated:    {$stats['updated']}");
        $this->comment("⏭️ Files Skipped:    {$stats['skipped']}");
        if ($this->option('delete')) {
            $this->comment("🗑️ Files Deleted:    {$stats['deleted']}");
        }
        $this->comment("❌ Errors encountered: {$stats['errors']}");
        $this->info(str_repeat("=", 50));
        $this->info("Storage: {$baseLocalPath}");
    }
}

