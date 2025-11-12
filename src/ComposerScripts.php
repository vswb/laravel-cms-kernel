<?php

namespace Dev\Kernel;

use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;

class ComposerScripts
{
    /**
     * Link all binaries from package bin/ directory to ROOT/bin
     * 
     * This method will automatically create symlinks for all files
     * in the package's bin/ directory to the project's root bin/ directory
     *
     * @return void
     */
    public static function linkBinaries()
    {
        // Determine paths
        $vendorDir = dirname(dirname(dirname(__DIR__))); // vendor/
        $projectRoot = dirname($vendorDir); // project root
        $packageBinDir = __DIR__ . '/../bin';
        $projectBinDir = $projectRoot . '/bin';

        // Check if package bin directory exists
        if (!is_dir($packageBinDir)) {
            echo "⚠️  Package bin directory not found: {$packageBinDir}\n";
            return;
        }

        // Create project bin directory if not exists
        if (!is_dir($projectBinDir)) {
            mkdir($projectBinDir, 0755, true);
            echo "✓ Created bin directory: {$projectBinDir}\n";
        }

        $linkedCount = 0;
        $skippedCount = 0;

        // Get all files and directories in package bin/
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($packageBinDir, RecursiveDirectoryIterator::SKIP_DOTS),
            RecursiveIteratorIterator::SELF_FIRST
        );

        foreach ($iterator as $item) {
            $relativePath = str_replace($packageBinDir . '/', '', $item->getPathname());
            $targetPath = $projectBinDir . '/' . $relativePath;
            $sourcePath = $item->getPathname();

            // Skip if target already exists and is not a symlink
            if (file_exists($targetPath) && !is_link($targetPath)) {
                $skippedCount++;
                continue;
            }

            // Remove existing symlink if exists
            if (is_link($targetPath)) {
                unlink($targetPath);
            }

            if ($item->isDir()) {
                // Create directory
                if (!is_dir($targetPath)) {
                    mkdir($targetPath, 0755, true);
                }
            } else {
                // Create parent directory if needed
                $targetDir = dirname($targetPath);
                if (!is_dir($targetDir)) {
                    mkdir($targetDir, 0755, true);
                }

                // Create symlink
                if (symlink($sourcePath, $targetPath)) {
                    // Make executable for shell scripts
                    if (preg_match('/\.(sh|py|php)$/', $item->getFilename())) {
                        chmod($sourcePath, 0755);
                    }
                    $linkedCount++;
                    echo "✓ Linked: bin/{$relativePath}\n";
                } else {
                    echo "✗ Failed to link: bin/{$relativePath}\n";
                }
            }
        }

        echo "\n";
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
        echo "📦 Laravel CMS Kernel - Binary Links Summary\n";
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
        echo "✓ Linked: {$linkedCount} files\n";
        if ($skippedCount > 0) {
            echo "⊘ Skipped: {$skippedCount} files (already exists)\n";
        }
        echo "📁 Target: {$projectBinDir}\n";
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
        echo "\n";
    }

    /**
     * Alternative method: Link only specific files (not directories)
     * 
     * @return void
     */
    public static function linkBinariesFlat()
    {
        $vendorDir = dirname(dirname(dirname(__DIR__)));
        $projectRoot = dirname($vendorDir);
        $packageBinDir = __DIR__ . '/../bin';
        $projectBinDir = $projectRoot . '/bin';

        if (!is_dir($packageBinDir)) {
            echo "⚠️  Package bin directory not found\n";
            return;
        }

        if (!is_dir($projectBinDir)) {
            mkdir($projectBinDir, 0755, true);
        }

        $linkedCount = 0;
        $files = glob($packageBinDir . '/*');

        foreach ($files as $file) {
            if (!is_file($file)) {
                continue;
            }

            $filename = basename($file);
            $targetPath = $projectBinDir . '/' . $filename;

            // Skip if target exists and is not a symlink
            if (file_exists($targetPath) && !is_link($targetPath)) {
                continue;
            }

            // Remove existing symlink
            if (is_link($targetPath)) {
                unlink($targetPath);
            }

            // Create symlink
            if (symlink($file, $targetPath)) {
                if (preg_match('/\.(sh|py|php)$/', $filename)) {
                    chmod($file, 0755);
                }
                $linkedCount++;
                echo "✓ Linked: bin/{$filename}\n";
            }
        }

        echo "\n✓ Linked {$linkedCount} binaries to {$projectBinDir}\n\n";
    }
}

