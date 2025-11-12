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
$skippedCount = 0;
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

    // Skip if target exists and is not a symlink (don't override user files)
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

        // Create symlink (use relative path for portability)
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
echo "  Linked: {$linkedCount} files\n";
if ($skippedCount > 0) {
    echo "  Skipped: {$skippedCount} files (already exists)\n";
}
echo "  Target: {$projectBinDir}\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "\n";

exit(0);

