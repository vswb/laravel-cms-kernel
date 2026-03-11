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
        {--force : Force re-download/overwrite all files from Drive to Local (SAFE: does NOT delete files)}
        {--retry=3 : Number of retries for each file operation on network failure}
        {--path= : Custom local storage path (defaults to storage/app/google_drive_mirror)}';

    /**
     * The console command description.
     */
    protected $description = 'Mirror GDrive to Local (Google Docs to MS Office) with Delta Sync, Streaming, and Retries.';

    protected $log_channel = 'daily';
    protected $lastError = null;

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
            $this->initGoogleDisk(null, 'google_drive_mirror');

            $rawPath = $this->option('path') ?: storage_path('app/google_drive_mirror');
            $baseLocalPath = realpath($rawPath) ?: $rawPath;
            $googleDisk = Storage::disk("google_drive_mirror");
            $targetIdentifiers = (array) $this->argument('folders');

            $stats = ['processed' => 0, 'updated' => 0, 'skipped' => 0, 'errors' => 0, 'folders' => 0, 'failed_files' => []];

            foreach ($targetIdentifiers as $identifier) {
                $localPrefix = '';
                $currentDiskName = "gdrive_tmp_" . substr(md5($identifier), 0, 8);

                // Check if $identifier is an ID or a Path
                $isId = (strpos($identifier, '/') === false && strlen($identifier) > 20);

                if ($isId) {
                    $this->info("\n🚀 RESOLVING PATH FOR GOOGLE DRIVE ID: {$identifier}");
                    
                    /** @var mixed $googleDisk */
                    $googleDisk = Storage::disk('google_drive_mirror');
                    try {
                        $resolvedPath = $this->getPathFromId($googleDisk, $identifier);
                        if ($resolvedPath) {
                            $this->info("Resolved Path: {$resolvedPath}");
                            $exploringPath = $resolvedPath;
                            // When using resolved path, we don't need a localPrefix because the path itself contains all segments
                            $localPrefix = ''; 
                        } else {
                            $this->warn("Could not resolve path for ID. Falling back to ID direct scan.");
                            $exploringPath = $identifier;
                        }
                    } catch (\Throwable $e) {
                        $this->warn("Path resolution failed: " . $e->getMessage() . ". Falling back to ID direct scan.");
                        $exploringPath = $identifier;
                    }
                } else {
                    $this->info("\n🚀 SCANNING GOOGLE DRIVE PATH: {$identifier}");
                    $this->initGoogleDisk(null, $currentDiskName); // Reset to base root
                    /** @var mixed $googleDisk */
                    $googleDisk = Storage::disk($currentDiskName);
                    $exploringPath = $identifier;
                }

                $this->info("Fetching remote item list (Recursive)...");
                    /** @var mixed $googleDisk */
                    $iterator = $googleDisk->listContents($exploringPath, true);
                    $remoteItems = []; 
                    foreach ($iterator as $item) {
                        // Support both Flysystem 1 (array) and Flysystem 3 (object)
                        $path = is_array($item) ? ($item['path'] ?? null) : (method_exists($item, 'path') ? $item->path() : ($item->path ?? null));
                        if ($path !== null) {
                            $remoteItems[$path] = $item;
                        }
                    }

                    // Fallback for some adapters where ID disk root is '/'
                    if ($isId && count($remoteItems) === 0 && $exploringPath === '') {
                        $this->info("Retrying with root path '/'...");
                        $iterator = $googleDisk->listContents('/', true);
                        foreach ($iterator as $item) {
                            $path = is_array($item) ? ($item['path'] ?? null) : (method_exists($item, 'path') ? $item->path() : ($item->path ?? null));
                            if ($path !== null) {
                                $remoteItems[$path] = $item;
                            }
                        }
                    }

                $totalItems = count($remoteItems);
                $this->info("Found {$totalItems} items. Starting synchronization...");

                if ($totalItems === 0) {
                    continue;
                }

                $bar = $this->output->createProgressBar($totalItems);
                $bar->start();

                foreach ($remoteItems as $relativePath => $item) {
                    $stats['processed']++;
                    
                    // Adjust local path if using ID (prefix with folder name)
                    $syncPath = $localPrefix ? $localPrefix . '/' . $relativePath : $relativePath;
                    $absoluteLocalPath = "{$baseLocalPath}/{$syncPath}";
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

                        // Deep Check for Google Native Files if MimeType is missing or generic
                        if (!$exportSpec && $isId) {
                            try {
                                /** @var mixed $googleDisk */
                                $service = $googleDisk->getAdapter()->getService();
                                $fileMeta = $service->files->get($meta['id'], ['fields' => 'id, name, mimeType']);
                                $mimeType = $fileMeta->getMimeType();
                                $exportSpec = $this->exportMap[$mimeType] ?? null;
                            } catch (\Throwable $e) {}
                        }

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
                        $success = $this->withRetry(function() use ($googleDisk, $relativePath, $targetLocalPath, $exportSpec, $fileMeta) {
                            File::ensureDirectoryExists(dirname($targetLocalPath));
                            
                            if ($exportSpec) {
                                // Export Google Native File
                                /** @var mixed $googleDisk */
                                $service = $googleDisk->getAdapter()->getService();
                                $this->line("\n   ✨ Exporting Google Native: " . basename($targetLocalPath));
                                $response = $service->files->export($fileMeta->getId(), $exportSpec['mime'], ['alt' => 'media']);
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
                                    throw new \Exception("Could not open read stream");
                                }
                            }
                            return true;
                        }, $relativePath);

                        if ($success) {
                            @touch($targetLocalPath, $remoteTimestamp);
                            $stats['updated']++;
                        } else {
                            $stats['errors']++;
                            $reason = $this->lastError ?? 'Unknown Error';
                            $fileId = is_array($meta) ? ($meta['id'] ?? 'N/A') : (method_exists($meta, 'getId') ? $meta->getId() : 'N/A');
                            $stats['failed_files'][] = [
                                'name' => $relativePath,
                                'id' => $fileId,
                                'reason' => $reason
                            ];
                            $this->error("\n   ❌ Failed to sync: {$relativePath} | Reason: {$reason}");
                        }
                    }
                    $bar->advance();
                }
                $bar->finish();
                $this->info("");

                // Cleanup Logic removed for safety
            }

            $this->finalReport($stats, $baseLocalPath);

        } catch (\Throwable $th) {
            $this->error("\n💥 Fatal Error: " . $th->getMessage());
            Log::channel($this->log_channel)->error("GDrive Mirror Fatal Exception", ['msg' => $th->getMessage(), 'trace' => $th->getTraceAsString()]);
            return Command::FAILURE;
        }

        return Command::SUCCESS;
    }

    /**
     * Wrapper for retry logic
     */
    protected function withRetry(callable $callback, $path)
    {
        $maxRetries = (int) $this->option('retry');
        $attempts = 0;

        while ($attempts <= $maxRetries) {
            try {
                return $callback();
            } catch (\Throwable $e) {
                $attempts++;
                $msg = $e->getMessage();
                $this->lastError = $msg;
                
                // Specific check for Google Export Limit
                if (str_contains($msg, 'exportSizeLimitExceeded')) {
                    $this->warn("\n      ⚠️  Google Export Limit Exceeded (File too large). Skipping.");
                    Log::channel($this->log_channel)->error("GDrive Sync: File too large to export", ['path' => $path]);
                    return false;
                }

                if ($attempts > $maxRetries) {
                    Log::channel($this->log_channel)->error("GDrive Sync: Final failure after {$maxRetries} retries", ['path' => $path, 'error' => $msg]);
                    return false;
                }
                
                $this->comment("      ⏳ Attempt {$attempts} failed, retrying...");
                sleep(1); 
            }
        }
        return false;
    }

    /**
     * Initializing the Google Drive Disk Config
     */
    protected function initGoogleDisk($specificFolderId = null, $diskName = 'google_drive_mirror')
    {
        $config = [
            'driver' => 'google',
            'clientId' => $this->getGdriveSetting('social_login_google_app_id', 'GOOGLE_DRIVE_CLIENT_ID'),
            'clientSecret' => $this->getGdriveSetting('social_login_google_app_secret', 'GOOGLE_DRIVE_CLIENT_SECRET'),
            'refreshToken' => $this->getGdriveSetting('social_login_google_drive_refresh_token', 'GOOGLE_DRIVE_REFRESH_TOKEN'),
        ];
        config(["filesystems.disks.{$diskName}" => $config]);
        
        // Force Laravel to forget the disk instance so it picks up the new config
        if (app()->resolved('filesystem')) {
            Storage::forgetDisk($diskName);
        }
    }

    /**
     * Display final report
     */

    protected function finalReport($stats, $baseLocalPath)
    {
        $this->info("\n" . str_repeat("=", 50));
        $this->info("✨ MIRROR SYNC COMPLETED");
        $this->info(str_repeat("=", 50));
        $this->comment("📂 Folders Created:  {$stats['folders']}");
        $this->comment("✅ Files Updated:    {$stats['updated']}");
        $this->comment("⏭️ Files Skipped:    {$stats['skipped']}");
        $this->comment("❌ Errors encountered: {$stats['errors']}");

        // Log Summary
        Log::channel($this->log_channel)->info("GDrive Mirror Sync COMPLETED", [
            'folders' => $stats['folders'],
            'updated' => $stats['updated'],
            'skipped' => $stats['skipped'],
            'errors'  => $stats['errors'],
            'path'    => $baseLocalPath
        ]);
        
        if (!empty($stats['failed_files'])) {
            $this->error("\n🔴 LIST OF FAILED FILES (FOR MANUAL SYNC)");
            
            // Log full error list for persistence
            Log::channel($this->log_channel)->error("GDrive Sync: List of failed files", [
                'failed_files' => $stats['failed_files']
            ]);

            foreach ($stats['failed_files'] as $index => $file) {
                $num = $index + 1;
                $this->line("{$num}. {$file['name']}");
                $this->line("   ↳ ID: {$file['id']}");
                $this->line("   ↳ Reason: {$file['reason']}");
            }
        }

        $this->info("\n" . str_repeat("=", 50));
        $this->info("Storage: {$baseLocalPath}");
    }

    /**
     * Resolve the full path of a Google Drive ID by tracing ancestors
     */
    protected function getPathFromId($googleDisk, $id)
    {
        $service = $googleDisk->getAdapter()->getService();
        $pathSegments = [];
        $currentId = $id;

        while ($currentId) {
            $file = $service->files->get($currentId, ['fields' => 'id, name, parents']);
            if (!$file) break;

            // Stop if we hit the root or a folder without a name (unlikely)
            if ($file->getName() === 'My Drive' || $file->getName() === 'Root') {
                break;
            }

            array_unshift($pathSegments, $file->getName());

            $parents = $file->getParents();
            if (empty($parents)) {
                break;
            }
            $currentId = $parents[0];
        }

        return implode('/', $pathSegments);
    }
}

