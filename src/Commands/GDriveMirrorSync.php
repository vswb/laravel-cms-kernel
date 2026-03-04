<?php
/**
 * GOOGLE DRIVE API SETUP GUIDES:
 * 1. How to get Client ID and Secret: https://github.com/ivanvermeyen/laravel-google-drive-demo/blob/master/README/1-getting-your-dlient-id-and-secret.md
 * 2. How to get Refresh Token: https://github.com/ivanvermeyen/laravel-google-drive-demo/blob/master/README/2-getting-your-refresh-token.md
 * 3. How to get Root Folder ID: https://github.com/ivanvermeyen/laravel-google-drive-demo/blob/master/README/3-getting-your-root-folder-id.md
 * 
 * USEFUL TOOLS:
 * - Google OAuth Playground: https://developers.google.com/oauthplayground
 * - Google Cloud Console (Credentials): https://console.cloud.google.com/apis/credentials
 * - Reference Article (Vietnamese): https://phambinh.net/bai-viet/su-dung-google-drive-lam-filesystem-driver-trong-laravel/
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
        {folders* : specific folders on Google Drive to mirror, e.g., 2022 2023}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Mirror files from Google Drive to local storage while maintaining exact paths/filenames and exporting Google Docs to PDF.';

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

            // Internal local base path for mirroring
            $baseLocalPath = storage_path('app/google_drive_mirror');

            // Connect to Google Drive disk (configured dynamically)
            $googleDisk = Storage::disk("google_drive_mirror");

            $targetFolders = (array) $this->argument('folders');

            foreach ($targetFolders as $folder) {
                $this->info("================================================================");
                $this->info("🚀 SCANNING GOOGLE DRIVE: {$folder}");
                $this->info("================================================================");
                Log::channel($this->log_channel)->info("GDrive Sync: Scanning folder: {$folder}");

                // Recursive listing to capture the entire directory tree from Google Drive
                $contents = collect($googleDisk->listContents($folder, true));
                $this->info("Found " . $contents->count() . " items within '{$folder}'");
                Log::channel($this->log_channel)->info("GDrive Sync: Found {$contents->count()} items in '{$folder}'");

                foreach ($contents as $item) {
                    $relativePath = $item['path'];
                    $absoluteLocalPath = "{$baseLocalPath}/{$relativePath}";
                    $type = $item['type']; // dir or file

                    // Access metadata (compatible with both Flysystem V1 array and V2/V3 object structures)
                    $meta = method_exists($item, 'extraMetadata') ? $item->extraMetadata() : $item;
                    $itemId = $meta['id'] ?? 'unknown_id';
                    $mimeType = $meta['mimeType'] ?? 'unknown_mimetype';

                    // 1. Mirror Directory Structure
                    if ($type === 'dir') {
                        if (!File::isDirectory($absoluteLocalPath)) {
                            File::makeDirectory($absoluteLocalPath, 0755, true);
                            $this->info("📁 Folder Created: {$relativePath}");
                            Log::channel($this->log_channel)->info("GDrive Sync: Created local directory: {$relativePath}");
                        }
                        continue;
                    }

                    if ($type === 'file') {
                        // Ensure parent directory exists locally
                        File::ensureDirectoryExists(dirname($absoluteLocalPath));

                        // 2. Determine if it's a Google Native App (Doc, Sheet, Slide, etc.)
                        $isGoogleNative = str_starts_with($mimeType, 'application/vnd.google-apps.');

                        Log::channel($this->log_channel)->info("GDrive Sync: Processing file", [
                            'path' => $relativePath,
                            'id' => $itemId,
                            'mimeType' => $mimeType,
                            'isGoogleNative' => $isGoogleNative
                        ]);

                        if ($isGoogleNative) {
                            // 3. Google Native: Export to PDF (preserving path and filename + .pdf extension)
                            $this->info("📄 Exporting (PDF): {$relativePath}");
                            $exportPath = $absoluteLocalPath . ".pdf";

                            try {
                                /** @var \Google\Service\Drive $service */
                                $service = $googleDisk->getAdapter()->getService();
                                $export = $service->files->export($itemId, 'application/pdf');
                                $rawData = $export->getBody()->getContents();

                                File::put($exportPath, $rawData);
                                $this->info("✅ Successfully exported: " . basename($exportPath));
                                Log::channel($this->log_channel)->info("GDrive Sync: Exported native file to PDF", ['path' => $exportPath]);
                            } catch (\Throwable $e) {
                                $this->error("❌ ERROR Exporting {$relativePath}: " . $e->getMessage());
                                Log::channel($this->log_channel)->error("GDrive Sync: Export Error", [
                                    'path' => $relativePath,
                                    'id' => $itemId,
                                    'message' => $e->getMessage()
                                ]);
                            }
                        } else {
                            // 4. Binary File: Direct download (Preserve Path and Filename exactly as on Google)
                            $this->info("💾 Downloading: {$relativePath}");

                            try {
                                $rawData = $googleDisk->get($relativePath);
                                File::put($absoluteLocalPath, $rawData);
                                $this->info("✅ Successfully saved: " . basename($absoluteLocalPath));
                                Log::channel($this->log_channel)->info("GDrive Sync: Downloaded binary file", ['path' => $relativePath]);
                            } catch (\Throwable $e) {
                                $this->error("❌ ERROR Downloading {$relativePath}: " . $e->getMessage());
                                Log::channel($this->log_channel)->error("GDrive Sync: Download Error", [
                                    'path' => $relativePath,
                                    'id' => $itemId,
                                    'message' => $e->getMessage()
                                ]);
                            }
                        }
                    }
                }
            }

            $this->info("\n================================================================");
            $this->info("✨ Mirroring process completed successfully.");
            $this->info("Local files at: {$baseLocalPath}");
            $this->info("================================================================");

        } catch (\Throwable $th) {
            $this->error("💥 Fatal Error: " . $th->getMessage());
            Log::channel($this->log_channel)->error("GDrive Mirror Fatal Error", [
                'message' => $th->getMessage(),
                'trace' => $th->getTraceAsString()
            ]);
            return Command::FAILURE;
        }

        return Command::SUCCESS;
    }
}
