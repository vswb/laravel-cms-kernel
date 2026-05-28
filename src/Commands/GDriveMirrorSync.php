<?php

/**
 * © 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Proprietary software developed and distributed by Visual Weber.
 * Use is permitted only under a valid license agreement.
 *
 * © 2026 CÔNG TY TNHH VISUAL WEBER. Bảo lưu mọi quyền.
 * Phần mềm độc quyền của Visual Weber, chỉ được sử dụng theo Hợp đồng cấp phép.
 */

/**
 * ============================================================
 *  GDriveMirrorSync — Hướng dẫn sử dụng
 * ============================================================
 *
 * CHỨC NĂNG
 * ---------
 *  Đồng bộ một chiều: Google Drive → Local.
 *  - Delta sync: chỉ tải file mới/thay đổi (so sánh MD5 trước, fallback timestamp).
 *  - Tự động convert Google Docs/Sheets/Slides → .docx / .xlsx / .pptx.
 *  - Stream download (không load toàn bộ file vào RAM).
 *  - Retry tự động với exponential backoff khi lỗi mạng.
 *  - Xử lý trùng tên file (name collision) bằng cách thêm Drive ID.
 *  - KHÔNG xoá file local — chỉ thêm/cập nhật.
 *
 * ============================================================
 *  CẤU HÌNH XÁC THỰC — chọn 1 trong 2 cách
 * ============================================================
 *
 *  GOOGLE_DRIVE_ENABLED=true
 *
 *  Cách A — Service Account (KHUYẾN NGHỊ, không cần refresh token):
 *    - Đặt file JSON tại: config/google-service-account-credentials.json
 *      (hoặc set env GOOGLE_SERVICE_ACCOUNT_JSON_LOCATION=/absolute/path.json)
 *    - QUAN TRỌNG: share folder Drive cần sync với email của service account
 *      (vd: adstool@ads-tools-207818.iam.gserviceaccount.com) ở mức Viewer trở lên.
 *      Service account KHÔNG tự thấy được folder cá nhân nếu chưa được share.
 *
 *  Cách B — OAuth2 (cũ, fallback khi không có service account file):
 *    GOOGLE_DRIVE_CLIENT_ID=<OAuth2 Client ID>
 *    GOOGLE_DRIVE_CLIENT_SECRET=<OAuth2 Client Secret>
 *    GOOGLE_DRIVE_REFRESH_TOKEN=<Refresh Token>
 *
 *    Hướng dẫn lấy credentials (chỉ cho Cách B):
 *    - Client ID & Secret : https://github.com/ivanvermeyen/laravel-google-drive-demo/blob/master/README/1-getting-your-dlient-id-and-secret.md
 *    - Refresh Token      : https://github.com/ivanvermeyen/laravel-google-drive-demo/blob/master/README/2-getting-your-refresh-token.md
 *    - Root Folder ID     : https://github.com/ivanvermeyen/laravel-google-drive-demo/blob/master/README/3-getting-your-root-folder-id.md
 *
 * ============================================================
 *  CÁCH LẤY FOLDER ID / PATH
 * ============================================================
 *
 *  Cách 1 — Folder ID (từ URL trình duyệt):
 *    Mở folder trên drive.google.com → URL có dạng:
 *    https://drive.google.com/drive/folders/0Bw6yYZTQJcm3aGoxTGJuY1p1ZU0
 *                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 *    Phần sau "/folders/" chính là Folder ID.
 *
 *  Cách 2 — Đường dẫn tương đối (dùng khi biết tên folder):
 *    Dùng cú pháp "Tên Folder Cha/Tên Folder Con"
 *    Ví dụ: "Báo cáo 2025/Tháng 1"
 *
 * ============================================================
 *  CÚ PHÁP LỆNH
 * ============================================================
 *
 *  php artisan gdrive:mirror:sync {folder_id_hoặc_path...}
 *      [--path=<local_dir>]   Thư mục đích local (mặc định: storage/app/google_drive_mirror)
 *      [--retry=<n>]          Số lần retry khi lỗi mạng (mặc định: 3, tối đa nên dùng: 10)
 *      [--force]              Tải lại tất cả file dù đã tồn tại (bỏ qua delta check)
 *
 * ============================================================
 *  VÍ DỤ SỬ DỤNG
 * ============================================================
 *
 *  --- Cơ bản ---
 *
 *  # Sync 1 folder theo ID, lưu vào đường dẫn mặc định
 *  php artisan gdrive:mirror:sync 0Bw6yYZTQJcm3aGoxTGJuY1p1ZU0
 *
 *  # Sync 1 folder theo ID, lưu vào ổ cứng ngoài
 *  php artisan gdrive:mirror:sync 0Bw6yYZTQJcm3aGoxTGJuY1p1ZU0 \
 *      --path="/Volumes/WD-DATA1/GDrive-Mirror"
 *
 *  # Sync theo đường dẫn tên folder (không cần ID)
 *  php artisan gdrive:mirror:sync "Báo cáo 2025" \
 *      --path="/home/backup/gdrive"
 *
 *  # Sync folder con theo path lồng nhau
 *  php artisan gdrive:mirror:sync "Projects/Client A/Assets" \
 *      --path="/var/www/storage/assets"
 *
 *  --- Nhiều folder cùng lúc ---
 *
 *  # Sync 2 folder ID cùng lúc vào cùng 1 thư mục đích
 *  php artisan gdrive:mirror:sync \
 *      0Bw6yYZTQJcm3aGoxTGJuY1p1ZU0 \
 *      1Cx7zATRKdm4bHpuYSKvZ2q2AW1 \
 *      --path="/Volumes/WD-DATA1/OneDrive"
 *
 *  # Sync hỗn hợp: 1 folder ID + 1 folder path
 *  php artisan gdrive:mirror:sync \
 *      0Bw6yYZTQJcm3aGoxTGJuY1p1ZU0 \
 *      "Marketing/Creatives" \
 *      --path="/var/www/html/public/files"
 *
 *  --- Retry & Force ---
 *
 *  # Tăng retry khi đường truyền yếu (ví dụ: tải qua 4G)
 *  php artisan gdrive:mirror:sync 0Bw6yYZTQJcm3aGoxTGJuY1p1ZU0 \
 *      --retry=10 \
 *      --path="/Volumes/WD-DATA1/OneDrive"
 *
 *  # Force tải lại toàn bộ (dùng khi nghi ngờ file local bị corrupt)
 *  php artisan gdrive:mirror:sync 0Bw6yYZTQJcm3aGoxTGJuY1p1ZU0 \
 *      --force \
 *      --path="/Volumes/WD-DATA1/OneDrive"
 *
 *  # Force + retry cao (dùng khi cần rebuild toàn bộ mirror sau sự cố)
 *  php artisan gdrive:mirror:sync 0Bw6yYZTQJcm3aGoxTGJuY1p1ZU0 \
 *      --force --retry=10 \
 *      --path="/Volumes/WD-DATA1/OneDrive"
 *
 *  --- Chạy tự động (Cron / Laravel Scheduler) ---
 *
 *  # Thêm vào app/Console/Kernel.php để chạy mỗi giờ:
 *  $schedule->command('gdrive:mirror:sync 0Bw6yYZTQJcm3aGoxTGJuY1p1ZU0 --retry=5 --path=/Volumes/WD-DATA1/OneDrive')
 *           ->hourly()
 *           ->withoutOverlapping()
 *           ->runInBackground();
 *
 *  # Hoặc thêm vào crontab hệ thống (chạy mỗi 30 phút):
 *  *\/30 * * * * php /var/www/html/artisan gdrive:mirror:sync 0Bw6yYZTQJcm3aGoxTGJuY1p1ZU0 \
 *      --path="/Volumes/WD-DATA1/OneDrive" --retry=5 >> /var/log/gdrive-sync.log 2>&1
 *
 * ============================================================
 *  CONVERT TỰ ĐỘNG GOOGLE NATIVE → MICROSOFT OFFICE
 * ============================================================
 *
 *  Google Docs       → .docx  (Word)
 *  Google Sheets     → .xlsx  (Excel)
 *  Google Slides     → .pptx  (PowerPoint)
 *  Google Drawings   → .png
 *  Google Apps Script → .json
 *
 *  File thông thường (PDF, JPG, MP4, ZIP…) được tải nguyên bản.
 *
 * ============================================================
 *  OUTPUT VÀ LOG
 * ============================================================
 *
 *  Sau mỗi lần chạy, lệnh in bảng tổng kết:
 *    📂 Folders Created   — Số thư mục mới được tạo
 *    ✅ Files Updated     — Số file được tải/cập nhật
 *    ⏭  Files Skipped    — Số file không thay đổi (delta skip)
 *    ⚠  Collisions       — Số file trùng tên (đã tự xử lý bằng cách thêm Drive ID)
 *    ❌ Errors            — Số file thất bại kèm lý do
 *
 *  Log chi tiết ghi vào channel "daily" (storage/logs/laravel-YYYY-MM-DD.log).
 *  Danh sách file lỗi được log riêng để tiện manual retry.
 *
 * ============================================================
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
     * php /Users/eugene/Sites/pull-server/artisan gdrive:mirror:sync 0Bw6yYZTQJcm3aGoxTGJuY1p1ZU0 --path="/Volumes/WD-DATA1/OneDrive" --retry=10 --force
     */
    protected $signature = 'gdrive:mirror:sync
        {folders* : Google_Folder_ID}
        {--force : Force re-download/overwrite all files from Drive to Local (SAFE: does NOT delete files)}
        {--retry=3 : Number of retries for each file operation on network failure}
        {--path= : Custom local storage path (defaults to storage/app/google_drive_mirror)}';

    /**
     * The console command description.
     */
    protected $description = 'Mirror GDrive to Local (Google Docs to MS Office) with Delta Sync, Streaming, and Retries.';

    protected $log_channel = 'daily';
    protected $lastError = null;
    protected ?string $serviceAccountFile = null;

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

            $stats = ['processed' => 0, 'updated' => 0, 'skipped' => 0, 'errors' => 0, 'folders' => 0, 'failed_files' => [], 'collisions' => 0];

            foreach ($targetIdentifiers as $identifier) {
                $usedLocalPaths = []; // Reset per-folder to avoid cross-folder collision false-positives
                $localPrefix = '';
                $currentDiskName = "gdrive_tmp_" . substr(md5($identifier), 0, 8);

                // Check if $identifier is an ID or a Path
                $isId = (strpos($identifier, '/') === false && strlen($identifier) > 20);

                if ($this->serviceAccountFile && $isId) {
                    // Service account: configure disk with folder ID as root; bypass path resolution.
                    // Why: service account has no "My Drive" of the user, so getPathFromId returns a
                    // folder name that listContents() can't resolve. Using the ID as the adapter root
                    // works regardless of who shared the folder.
                    $this->initGoogleDisk($identifier, $currentDiskName);
                    /** @var mixed $googleDisk */
                    $googleDisk = Storage::disk($currentDiskName);

                    try {
                        $folderInfo = $googleDisk->getAdapter()->getService()->files->get($identifier, ['fields' => 'name']);
                        $localPrefix = $folderInfo->getName();
                        $this->info("\n🚀 SYNCING (Service Account) — Folder: {$localPrefix} ({$identifier})");
                    } catch (\Throwable $e) {
                        $localPrefix = $identifier;
                        $this->warn("\n🚀 SYNCING (Service Account) — Folder ID: {$identifier} (name lookup failed: {$e->getMessage()})");
                    }
                    $exploringPath = '';
                } elseif ($this->serviceAccountFile && !$isId) {
                    $this->warn("\n⚠️ Skipping '{$identifier}': service account mode requires a Folder ID, not a path.");
                    continue;
                } elseif ($isId) {
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
                        $remoteItems[] = $item;
                    }

                    // Fallback for some adapters where ID disk root is '/'
                    if ($isId && count($remoteItems) === 0 && $exploringPath === '') {
                        $this->info("Retrying with root path '/'...");
                        $iterator = $googleDisk->listContents('/', true);
                        foreach ($iterator as $item) {
                            $remoteItems[] = $item;
                        }
                    }

                $totalItems = count($remoteItems);
                $this->info("Found {$totalItems} items. Starting synchronization...");

                if ($totalItems === 0) {
                    continue;
                }

                $bar = $this->output->createProgressBar($totalItems);
                $bar->start();

                foreach ($remoteItems as $item) {
                    $stats['processed']++;

                    // Support both Flysystem 1 (array) and Flysystem 3 (object)
                    $relativePath = is_array($item) ? ($item['path'] ?? null) : (method_exists($item, 'path') ? $item->path() : ($item->path ?? null));
                    if ($relativePath === null) {
                        $bar->advance();
                        continue;
                    }
                    
                    // Adjust local path if using ID (prefix with folder name)
                    $syncPath = $localPrefix ? $localPrefix . '/' . $relativePath : $relativePath;
                    $absoluteLocalPath = "{$baseLocalPath}/{$syncPath}";
                    $type = is_array($item) ? ($item['type'] ?? 'file') : (method_exists($item, 'type') ? $item->type() : 'file');

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
                        $fileId = is_array($meta) ? ($meta['id'] ?? 'N/A') : (method_exists($meta, 'getId') ? $meta->getId() : 'N/A');
                        $mimeType = $meta['mimeType'] ?? '';
                        $remoteTimestamp = $item['timestamp'] ?? ($item instanceof \League\Flysystem\StorageAttributes ? $item->lastModified() : 0);
                        $remoteMd5 = $meta['md5Checksum'] ?? null;
                        
                        // Decide target path (Normal vs Export)
                        $targetLocalPath = $absoluteLocalPath;
                        $exportSpec = $this->exportMap[$mimeType] ?? null;

                        // Deep Check for Google Native Files if MimeType is missing or generic
                        $fileMeta = null;
                        if (!$exportSpec && $isId) {
                            try {
                                /** @var mixed $googleDisk */
                                $service = $googleDisk->getAdapter()->getService();
                                $fileMeta = $service->files->get($fileId, ['fields' => 'id, name, mimeType, md5Checksum']);
                                $mimeType = $fileMeta->getMimeType();
                                $remoteMd5 = $fileMeta->getMd5Checksum();
                                $exportSpec = $this->exportMap[$mimeType] ?? null;
                            } catch (\Throwable $e) {}
                        }

                        if ($exportSpec) {
                            $targetLocalPath = $absoluteLocalPath . '.' . $exportSpec['ext'];
                        }

                        // IMPROVEMENT 1 & 3: Handle Name Collisions
                        if (isset($usedLocalPaths[$targetLocalPath])) {
                            $stats['collisions']++;
                            $this->warn("\n   ⚠️ Collision: " . basename($targetLocalPath) . " already exists in this sync. Appending ID.");
                            
                            $info = pathinfo($targetLocalPath);
                            $ext = $info['extension'] ?? '';
                            $newName = $info['filename'] . '_' . substr($fileId, 0, 8);
                            $targetLocalPath = $info['dirname'] . DIRECTORY_SEPARATOR . $newName . ($ext ? "." . $ext : "");
                            
                            Log::channel($this->log_channel)->warning("GDrive Sync Collision", [
                                'original' => $absoluteLocalPath,
                                'new' => $targetLocalPath,
                                'id' => $fileId
                            ]);
                        }
                        $usedLocalPaths[$targetLocalPath] = $fileId;

                        // Delta Sync: MD5 is authoritative; timestamp is fallback when MD5 unavailable
                        if (!$this->option('force') && File::exists($targetLocalPath)) {
                            if ($remoteMd5) {
                                // MD5 available: skip only if content is identical
                                if (md5_file($targetLocalPath) === $remoteMd5) {
                                    $stats['skipped']++;
                                    $bar->advance();
                                    continue;
                                }
                                // MD5 mismatch means file changed → must re-download, ignore timestamp
                            } elseif (File::lastModified($targetLocalPath) >= $remoteTimestamp) {
                                // No MD5: fall back to timestamp
                                $stats['skipped']++;
                                $bar->advance();
                                continue;
                            }
                        }

                        // Download/Export with Retry Logic
                        $success = $this->withRetry(function() use ($googleDisk, $relativePath, $targetLocalPath, $exportSpec, $fileId) {
                            File::ensureDirectoryExists(dirname($targetLocalPath));
                            
                            if ($exportSpec) {
                                // Export Google Native File
                                /** @var mixed $googleDisk */
                                $service = $googleDisk->getAdapter()->getService();
                                $this->line("\n   ✨ Exporting Google Native: " . basename($targetLocalPath));
                                $response = $service->files->export($fileId, $exportSpec['mime'], ['alt' => 'media']);
                                File::put($targetLocalPath, $response->getBody()->getContents());
                            } else {
                                // Stream Download for regular files (Memory Efficient)
                                $readStream = $googleDisk->readStream($relativePath);
                                if (!$readStream) {
                                    throw new \Exception("Could not open read stream");
                                }
                                $writeStream = fopen($targetLocalPath, 'w');
                                try {
                                    stream_copy_to_stream($readStream, $writeStream);
                                } finally {
                                    fclose($writeStream);
                                    if (is_resource($readStream)) fclose($readStream);
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
                
                $delay = min(2 ** $attempts, 30); // Exponential backoff: 2s, 4s, 8s… max 30s
                $this->comment("      ⏳ Attempt {$attempts} failed, retrying in {$delay}s...");
                sleep($delay);
            }
        }
        return false;
    }

    /**
     * Recursively list a folder via Drive API. Returns items in masbug-compatible shape
     * (arrays with type/path/id/mimeType/md5Checksum/timestamp). Used in service-account mode
     * because masbug's listContents on a folder-id root returns nothing.
     */
    protected function listFolderRecursiveViaApi($service, string $folderId, string $relativePath = ''): array
    {
        $items = [];
        $pageToken = null;
        $query = sprintf("'%s' in parents and trashed = false", str_replace("'", "\\'", $folderId));

        do {
            $response = $service->files->listFiles([
                'q' => $query,
                'pageSize' => 1000,
                'fields' => 'nextPageToken, files(id, name, mimeType, modifiedTime, md5Checksum, size)',
                'pageToken' => $pageToken,
                'supportsAllDrives' => true,
                'includeItemsFromAllDrives' => true,
            ]);

            foreach ($response->getFiles() as $file) {
                $isFolder = $file->getMimeType() === 'application/vnd.google-apps.folder';
                $childPath = $relativePath !== '' ? $relativePath . '/' . $file->getName() : $file->getName();

                $items[] = [
                    'type' => $isFolder ? 'dir' : 'file',
                    'path' => $childPath,
                    'id' => $file->getId(),
                    'mimeType' => $file->getMimeType(),
                    'md5Checksum' => $file->getMd5Checksum(),
                    'timestamp' => $file->getModifiedTime() ? strtotime($file->getModifiedTime()) : 0,
                    'size' => (int) ($file->getSize() ?? 0),
                ];

                if ($isFolder) {
                    foreach ($this->listFolderRecursiveViaApi($service, $file->getId(), $childPath) as $child) {
                        $items[] = $child;
                    }
                }
            }

            $pageToken = $response->getNextPageToken();
        } while ($pageToken);

        return $items;
    }

    /**
     * Stream-download a regular (non Google-native) file via Drive API to disk.
     * Avoids loading the whole file into memory.
     */
    protected function streamDownloadViaApi($service, string $fileId, string $targetLocalPath): void
    {
        $httpClient = $service->getClient()->authorize();
        $url = sprintf('https://www.googleapis.com/drive/v3/files/%s?alt=media&supportsAllDrives=true', urlencode($fileId));

        $response = $httpClient->request('GET', $url, ['stream' => true]);
        $body = $response->getBody();

        $writeStream = fopen($targetLocalPath, 'w');
        try {
            while (! $body->eof()) {
                fwrite($writeStream, $body->read(8192));
            }
        } finally {
            fclose($writeStream);
        }
    }

    /**
     * Resolve service account JSON file path. Returns null if not present/readable.
     * Priority: env GOOGLE_SERVICE_ACCOUNT_JSON_LOCATION → config('google.service.file') → config_path default.
     */
    protected function resolveServiceAccountFile(): ?string
    {
        $candidates = array_filter([
            env('GOOGLE_SERVICE_ACCOUNT_JSON_LOCATION'),
            function_exists('config') ? config('google.service.file') : null,
            function_exists('config_path') ? config_path('google-service-account-credentials.json') : null,
        ]);

        foreach ($candidates as $path) {
            $resolved = str_starts_with($path, DIRECTORY_SEPARATOR) ? $path : (function_exists('config_path') ? config_path($path) : $path);
            if (is_file($resolved) && is_readable($resolved)) {
                return $resolved;
            }
        }
        return null;
    }

    /**
     * Initializing the Google Drive Disk Config
     */
    protected function initGoogleDisk($specificFolderId = null, $diskName = 'google_drive_mirror')
    {
        $serviceAccountFile = $this->resolveServiceAccountFile();
        $this->serviceAccountFile = $serviceAccountFile;

        if ($serviceAccountFile) {
            $config = [
                'driver' => 'google',
                'serviceAccountFile' => $serviceAccountFile,
            ];
        } else {
            $config = [
                'driver' => 'google',
                'clientId' => $this->getGdriveSetting('social_login_google_app_id', 'GOOGLE_DRIVE_CLIENT_ID'),
                'clientSecret' => $this->getGdriveSetting('social_login_google_app_secret', 'GOOGLE_DRIVE_CLIENT_SECRET'),
                'refreshToken' => $this->getGdriveSetting('social_login_google_drive_refresh_token', 'GOOGLE_DRIVE_REFRESH_TOKEN'),
            ];
        }

        if ($specificFolderId) {
            $config['folder'] = $specificFolderId;
        }

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
        $this->comment("⚠️ Collisions:       {$stats['collisions']}");
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
        $maxDepth = 25; // Guard against unexpected circular references

        while ($currentId && $maxDepth-- > 0) {
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

