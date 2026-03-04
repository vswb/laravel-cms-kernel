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
     * Use: php artisan gdrive:mirror:sync folder1 folder2
     * 
     * @var string
     */
    protected $signature = 'gdrive:mirror:sync
        {folders* : specific folders on Google Drive to mirror, e.g., 2022 2023}
        {--force : Force download all files even if they haven\'t changed}
        {--delete : Delete local files/folders that no longer exist on Google Drive}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Mirror files from Google Drive to local storage with Delta Sync, Progress Bar, and optional cleanup.';

    protected $log_channel = 'daily';

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
     *
     * @return int
     */
    public function handle()
    {
        set_time_limit(0); // Prevent timeout for large syncs

        try {
            // Check if feature is enabled
            $isEnabled = $this->getGdriveSetting('social_login_google_drive_enable', 'GOOGLE_DRIVE_ENABLED');
            if ($isEnabled === '0' || $isEnabled === false || $isEnabled === 'false') {
                $this->warn("⚠️ GDrive Mirror Sync is disabled (social_login_google_drive_enable).");
                return Command::FAILURE;
            }

            // Locally register the Google Drive disk configuration
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

            // Logger: Debug configuration (Masked)
            Log::channel($this->log_channel)->info("GDrive Sync: Dynamic Config Initialized", [
                'clientId' => Str::limit($config['clientId'], 10, '***'),
                'folder' => $config['folder'],
                'teamDriveId' => $config['teamDriveId'],
            ]);

            $baseLocalPath = storage_path('app/google_drive_mirror');
            $googleDisk = Storage::disk("google_drive_mirror");
            $targetFolders = (array) $this->argument('folders');

            $stats = [
                'processed' => 0,
                'updated' => 0,
                'skipped' => 0,
                'deleted' => 0,
                'errors' => 0,
                'folders' => 0,
            ];

            foreach ($targetFolders as $baseFolder) {
                $this->info("\n🚀 SCANNING GOOGLE DRIVE: {$baseFolder}");
                Log::channel($this->log_channel)->info("GDrive Sync: Scanning folder: {$baseFolder}");

                // 1. Fetch contents (Recursive)
                // We use an iterator directly to handle large volumes of data efficiently
                $iterator = $googleDisk->listContents($baseFolder, true);
                $remoteItems = []; // Used for cleanup logic if --delete is on

                $this->info("Fetching remote item list...");
                foreach ($iterator as $item) {
                    $remoteItems[$item['path']] = $item;
                }

                $totalItems = count($remoteItems);
                $this->info("Found {$totalItems} items. Starting synchronization...");

                $bar = $this->output->createProgressBar($totalItems);
                $bar->start();

                foreach ($remoteItems as $relativePath => $item) {
                    $absoluteLocalPath = "{$baseLocalPath}/{$relativePath}";
                    $type = $item['type'];
                    $stats['processed']++;

                    // Access metadata correctly based on V1/V2 Flysystem
                    $meta = method_exists($item, 'extraMetadata') ? $item->extraMetadata() : $item;
                    $itemId = $meta['id'] ?? 'unknown';
                    $mimeType = $meta['mimeType'] ?? 'unknown';
                    $remoteTimestamp = $item['timestamp'] ?? ($item instanceof \League\Flysystem\StorageAttributes ? $item->lastModified() : 0);
                    $remoteSize = $item['size'] ?? ($item instanceof \League\Flysystem\FileAttributes ? $item->fileSize() : 0);

                    if ($type === 'dir') {
                        if (!File::isDirectory($absoluteLocalPath)) {
                            File::makeDirectory($absoluteLocalPath, 0755, true);
                            $stats['folders']++;
                        }
                        $bar->advance();
                        continue;
                    }

                    if ($type === 'file') {
                        File::ensureDirectoryExists(dirname($absoluteLocalPath));

                        $isGoogleNative = str_starts_with($mimeType, 'application/vnd.google-apps.');
                        $targetLocalPath = $isGoogleNative ? $absoluteLocalPath . ".pdf" : $absoluteLocalPath;

                        // Delta Sync Check: Skip if file exists and hasn't changed
                        if (!$this->option('force') && File::exists($targetLocalPath)) {
                            $localTimestamp = File::lastModified($targetLocalPath);

                            // For Google Native, we can't easily compare size because export varies, 
                            // so we rely mostly on timestamp.
                            if ($localTimestamp >= $remoteTimestamp) {
                                $stats['skipped']++;
                                $bar->advance();
                                continue;
                            }
                        }

                        // Process File (Export or Download)
                        try {
                            if ($isGoogleNative) {
                                /** @var \Google\Service\Drive $service */
                                $service = $googleDisk->getAdapter()->getService();
                                $export = $service->files->export($itemId, 'application/pdf');
                                $rawData = $export->getBody()->getContents();
                                File::put($targetLocalPath, $rawData);
                            } else {
                                $rawData = $googleDisk->get($relativePath);
                                File::put($targetLocalPath, $rawData);
                            }

                            $stats['updated']++;
                            // Explicitly set timestamp to match remote
                            if ($remoteTimestamp > 0) {
                                @touch($targetLocalPath, $remoteTimestamp);
                            }
                        } catch (\Throwable $e) {
                            $stats['errors']++;
                            Log::channel($this->log_channel)->error("GDrive Sync Error: {$relativePath}", ['msg' => $e->getMessage()]);
                        }
                    }
                    $bar->advance();
                }
                $bar->finish();
                $this->info("");

                // 2. Cleanup Logic (--delete)
                if ($this->option('delete')) {
                    $this->info("Cleaning up local orphans for '{$baseFolder}'...");
                    $localFiles = File::allFiles("{$baseLocalPath}/{$baseFolder}");
                    foreach ($localFiles as $file) {
                        $fullPath = $file->getRealPath();
                        $localRelativePath = Str::after($fullPath, $baseLocalPath . '/');

                        // Handle the .pdf suffix for native exports when checking existence
                        $checkPath = $localRelativePath;
                        if (Str::endsWith($localRelativePath, '.pdf')) {
                            $potentialNativePath = Str::beforeLast($localRelativePath, '.pdf');
                            if (isset($remoteItems[$potentialNativePath])) {
                                $checkPath = $potentialNativePath;
                            }
                        }

                        if (!isset($remoteItems[$checkPath])) {
                            File::delete($fullPath);
                            $stats['deleted']++;
                            $this->line("🗑️ Deleted local orphan: {$localRelativePath}");
                        }
                    }
                }
            }

            // FINAL REPORT
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
            $this->info("Local files at: {$baseLocalPath}");

        } catch (\Throwable $th) {
            $this->error("\n💥 Fatal Error: " . $th->getMessage());
            Log::channel($this->log_channel)->error("GDrive Mirror Fatal Error", [
                'message' => $th->getMessage(),
                'trace' => $th->getTraceAsString()
            ]);
            return Command::FAILURE;
        }

        return Command::SUCCESS;
    }
}
