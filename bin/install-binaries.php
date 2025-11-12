#!/usr/bin/env php
<?php
/**
 * Install script to link all binaries to project root bin/
 * 
 * This script automatically creates symlinks from package bin/ to ROOT/bin
 * Run automatically by Composer post-install and post-update scripts
 */

// Determine paths
$packageDir = dirname(__DIR__);
$vendorDir = dirname(dirname(dirname($packageDir)));
$projectRoot = dirname($vendorDir);
$packageBinDir = $packageDir . '/bin';
$projectBinDir = $projectRoot . '/bin';

echo "\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "📦 Laravel CMS Kernel - Installing Binaries\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "\n";

// Check if package bin directory exists
if (!is_dir($packageBinDir)) {
    echo "⚠️  Package bin directory not found: {$packageBinDir}\n";
    exit(0);
}

// Create project bin directory if not exists
if (!is_dir($projectBinDir)) {
    mkdir($projectBinDir, 0755, true);
    echo "✓ Created bin directory: {$projectBinDir}\n";
}

$linkedCount = 0;
$removedCount = 0;
$excludeFiles = ['install-binaries.php']; // Don't link this installer itself

// Get all items in package bin/
$items = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($packageBinDir, RecursiveDirectoryIterator::SKIP_DOTS),
    RecursiveIteratorIterator::SELF_FIRST
);

foreach ($items as $item) {
    $relativePath = str_replace($packageBinDir . '/', '', $item->getPathname());
    
    // Skip excluded files
    if (in_array(basename($item->getPathname()), $excludeFiles)) {
        continue;
    }
    
    $targetPath = $projectBinDir . '/' . $relativePath;
    $sourcePath = $item->getPathname();

    if ($item->isDir()) {
        // Create directory if not exists
        if (!is_dir($targetPath)) {
            mkdir($targetPath, 0755, true);
        }
    } else {
        // Create parent directory if needed
        $targetDir = dirname($targetPath);
        if (!is_dir($targetDir)) {
            mkdir($targetDir, 0755, true);
        }

        // ✅ FORCE MODE: Remove any existing file/symlink to ensure symlink creation
        if (file_exists($targetPath) || is_link($targetPath)) {
            // Check if it's a symlink first (symlinks return true for is_link even if broken)
            if (is_link($targetPath)) {
                unlink($targetPath);
                $removedCount++;
                echo "  🔄 Removed old symlink: {$relativePath}\n";
            } 
            // If it's a regular file (not symlink), remove it too
            elseif (is_file($targetPath)) {
                unlink($targetPath);
                $removedCount++;
                echo "  🔄 Removed old file: {$relativePath}\n";
            }
        }

        // Create symlink
        if (symlink($sourcePath, $targetPath)) {
            // Make executable for scripts
            $extension = pathinfo($item->getFilename(), PATHINFO_EXTENSION);
            if (in_array($extension, ['sh', 'py', 'php']) || !$extension) {
                @chmod($sourcePath, 0755);
            }
            $linkedCount++;
            echo "  ✓ {$relativePath}\n";
        } else {
            echo "  ✗ Failed: {$relativePath}\n";
        }
    }
}

echo "\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "Summary:\n";
echo "  ✓ Linked: {$linkedCount} files\n";
if ($removedCount > 0) {
    echo "  🔄 Removed: {$removedCount} old files/symlinks\n";
}
echo "  📁 Target: {$projectBinDir}\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "\n";

exit(0);

