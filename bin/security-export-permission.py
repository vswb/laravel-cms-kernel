#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Security Export Permission Script
Export file/folder permissions to Excel file
"""

import os
import sys
import argparse
import fnmatch
from datetime import datetime
from openpyxl import Workbook

# Fix encoding for Python 3.x on systems with ASCII locale
if sys.stdout.encoding is None or sys.stdout.encoding.lower() == 'ascii':
    import io
    # Force UTF-8 encoding for stdout/stderr
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

def main():
    parser = argparse.ArgumentParser(
        description='Export file and folder permissions to Excel'
    )
    parser.add_argument(
        '--base-dir',
        default='.',
        help='Base directory to scan (default: current directory)'
    )
    parser.add_argument(
        '--output',
        '-o',
        help='Output file path (default: permissions_report_YYYYMMDD_HHMMSS.xlsx in current directory)'
    )
    parser.add_argument(
        '--exclude',
        nargs='+',
        default=['.git', 'lang', 'public/ui', 'routes', 'scripts', 'stubs', 'resources', 'tests', 'app', 'public/storage', 'dev', 'dev-extensions', 'bin', 'database', 'bootstrap', 'docker-example', 'docker', 'storage/framework', 'storage/views', 'storage/logs', 'storage/app', 'storage/debugbar', 'storage/cache', 'node_modules', 'vendor', '.idea', '.vscode'],
        help='Directories/paths to exclude (default: .git, node_modules, vendor, .idea, .vscode). Supports paths with slashes like "storage/framework"'
    )
    parser.add_argument(
        '--exclude-files',
        nargs='+',
        default=["*.log", "*.tmp", "*.json", "composer.lock", "*.jpg", "*.webp", "*.png", "*.gif", "*.bmp", "*.svg", "*.ico", "*.css", "*.js", "*.env.example", "*.env.local", ".editorconfig", ".gitattributes", ".gitignore", ".gitlab-ci.yml-template.yml", ".rnd", "Dockerfile", "Makefile", "composer.phar", "database.sql", "docker-compose.yml", "laravel-echo-server.json-sample", "laravel-queue-worker.yml", "package-lock.json", "phpunit.xml", "pm2.json-sample", "yarn.lock", "tsconfig.json", "*.md"],
        help='File patterns to exclude (e.g., "*.log", "*.tmp", ".env", "composer.lock"). Supports wildcards and exact filenames'
    )
    parser.add_argument(
        '--skip-symlinks',
        action='store_true',
        help='Skip symlinks (default: follow symlinks)'
    )
    parser.add_argument(
        '--skip-broken',
        action='store_true',
        default=True,
        help='Skip broken symlinks (default: True)'
    )
    
    args = parser.parse_args()
    
    # Get absolute path of base directory
    base_dir = os.path.abspath(args.base_dir)
    
    if not os.path.exists(base_dir):
        print(f"Error: Base directory does not exist: {base_dir}")
        sys.exit(1)
    
    if not os.path.isdir(base_dir):
        print(f"Error: Base path is not a directory: {base_dir}")
        sys.exit(1)
    
    # Determine output path
    if args.output:
        output_path = os.path.abspath(args.output)
    else:
        # Default: save in current directory with timestamp
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_path = os.path.join(os.getcwd(), f'permissions_report_{timestamp}.xlsx')
    
    # Create output directory if it doesn't exist
    output_dir = os.path.dirname(output_path)
    if output_dir and not os.path.exists(output_dir):
        try:
            os.makedirs(output_dir, exist_ok=True)
            print(f"Created output directory: {output_dir}")
        except Exception as e:
            print(f"Error: Cannot create output directory: {e}")
            sys.exit(1)
    
    print(f"Scanning directory: {base_dir}")
    print(f"Output file: {output_path}")
    print(f"Excluding directories/paths: {', '.join(args.exclude) if args.exclude else 'none'}")
    if args.exclude_files:
        print(f"Excluding files: {', '.join(args.exclude_files)}")
    print("Processing...")
    
    # Create workbook
    wb = Workbook()
    ws = wb.active
    ws.title = "Permissions"
    
    # Header
    ws.append(["Path", "Type", "Permissions (octal)", "Permissions (rwx)", "Owner", "Group"])
    
    file_count = 0
    dir_count = 0
    
    # Walk through directory with error handling
    def handle_walk_error(error):
        """Handle errors during os.walk()"""
        print(f"Warning: {error.filename}: {error.strerror}")
        # Return None to continue walking, or raise to stop
        return None
    
    try:
        for root, dirs, files in os.walk(base_dir, onerror=handle_walk_error, followlinks=not args.skip_symlinks):
            # Filter out excluded directories (check both name and full path)
            valid_dirs_by_exclude = []
            for d in dirs:
                dir_path = os.path.join(root, d)
                if not should_exclude_path(dir_path, base_dir, args.exclude):
                    valid_dirs_by_exclude.append(d)
            dirs[:] = valid_dirs_by_exclude
            
            # Filter out broken symlinks and non-existent paths before os.walk() tries to enter them
            valid_dirs = []
            for d in dirs:
                dir_path = os.path.join(root, d)
                try:
                    # Skip if it's a symlink and we're skipping symlinks
                    if args.skip_symlinks and os.path.islink(dir_path):
                        continue
                    # Skip if path doesn't exist (broken symlink or deleted)
                    if not os.path.exists(dir_path):
                        if args.skip_broken:
                            continue
                    # Check if it's actually a directory (not a broken symlink)
                    # Use lstat for symlinks to avoid following broken ones
                    if os.path.islink(dir_path):
                        # It's a symlink, check if we should follow it
                        if args.skip_symlinks:
                            continue
                        # Try to check if target exists
                        try:
                            target = os.readlink(dir_path)
                            if not os.path.exists(dir_path):
                                if args.skip_broken:
                                    continue
                        except (OSError, PermissionError):
                            if args.skip_broken:
                                continue
                    elif not os.path.isdir(dir_path):
                        # Not a directory and not a symlink, skip
                        continue
                    valid_dirs.append(d)
                except (OSError, PermissionError, FileNotFoundError) as e:
                    # Skip if we can't check the path
                    if args.skip_broken:
                        continue
            dirs[:] = valid_dirs
            
            # Filter files similarly (also check exclude patterns)
            valid_files = []
            for f in files:
                file_path = os.path.join(root, f)
                try:
                    # Check if file should be excluded by path patterns (directories/paths)
                    if should_exclude_path(file_path, base_dir, args.exclude):
                        continue
                    
                    # Check if file should be excluded by file patterns (e.g., *.log, .env)
                    if should_exclude_file(file_path, base_dir, args.exclude_files):
                        continue
                    
                    # Skip if it's a symlink and we're skipping symlinks
                    if args.skip_symlinks and os.path.islink(file_path):
                        continue
                    
                    # Skip if path doesn't exist (broken symlink or deleted)
                    if not os.path.exists(file_path):
                        if args.skip_broken:
                            continue
                    valid_files.append(f)
                except (OSError, PermissionError, FileNotFoundError):
                    # Skip if we can't check the path
                    continue
            files[:] = valid_files
            
            # Process directories
            for d in dirs:
                path = os.path.join(root, d)
                
                # Skip if it's a symlink and we're skipping symlinks
                if args.skip_symlinks and os.path.islink(path):
                    continue
                
                # Skip if path doesn't exist (broken symlink)
                if not os.path.exists(path):
                    if args.skip_broken:
                        continue
                    else:
                        # Try to get symlink info even if broken
                        try:
                            link_target = os.readlink(path)
                            rel_path = os.path.relpath(path, base_dir)
                            ws.append([rel_path, "symlink (broken)", "---", "---", "---", "---"])
                            continue
                        except (OSError, PermissionError):
                            continue
                
                try:
                    stat = os.stat(path)
                    perm_octal = oct(stat.st_mode)[-3:]
                    perm_rwx = get_permission_string(stat.st_mode)
                    owner = get_owner_name(stat.st_uid)
                    group = get_group_name(stat.st_gid)
                    
                    # Make path relative to base_dir
                    rel_path = os.path.relpath(path, base_dir)
                    item_type = "symlink" if os.path.islink(path) else "folder"
                    ws.append([rel_path, item_type, perm_octal, perm_rwx, owner, group])
                    dir_count += 1
                except (OSError, PermissionError, FileNotFoundError) as e:
                    print(f"Warning: Cannot access {path}: {e}")
            
            # Process files
            for f in files:
                path = os.path.join(root, f)
                
                # Skip if it's a symlink and we're skipping symlinks
                if args.skip_symlinks and os.path.islink(path):
                    continue
                
                # Skip if path doesn't exist (broken symlink)
                if not os.path.exists(path):
                    if args.skip_broken:
                        continue
                    else:
                        # Try to get symlink info even if broken
                        try:
                            link_target = os.readlink(path)
                            rel_path = os.path.relpath(path, base_dir)
                            ws.append([rel_path, "symlink (broken)", "---", "---", "---", "---"])
                            continue
                        except (OSError, PermissionError):
                            continue
                
                try:
                    stat = os.stat(path)
                    perm_octal = oct(stat.st_mode)[-3:]
                    perm_rwx = get_permission_string(stat.st_mode)
                    owner = get_owner_name(stat.st_uid)
                    group = get_group_name(stat.st_gid)
                    
                    # Make path relative to base_dir
                    rel_path = os.path.relpath(path, base_dir)
                    item_type = "symlink" if os.path.islink(path) else "file"
                    ws.append([rel_path, item_type, perm_octal, perm_rwx, owner, group])
                    file_count += 1
                except (OSError, PermissionError, FileNotFoundError) as e:
                    print(f"Warning: Cannot access {path}: {e}")
    except (OSError, PermissionError) as e:
        print(f"Error walking directory: {e}")
        sys.exit(1)
    
    # Save workbook
    try:
        wb.save(output_path)
        print(f"\n[OK] Success!")
        print(f"  Files scanned: {file_count}")
        print(f"  Directories scanned: {dir_count}")
        print(f"  Output saved to: {output_path}")
    except Exception as e:
        print(f"\n[ERROR] Error saving file: {e}")
        sys.exit(1)

def get_permission_string(mode):
    """Convert permission mode to rwx string"""
    # Extract permission bits (last 9 bits)
    perm_bits = mode & 0o777
    
    # Convert to rwx string
    perm = ''
    for bit in [6, 3, 0]:  # owner, group, other
        perm += 'r' if (perm_bits >> (bit + 2)) & 1 else '-'
        perm += 'w' if (perm_bits >> (bit + 1)) & 1 else '-'
        perm += 'x' if (perm_bits >> bit) & 1 else '-'
    
    return perm

def get_owner_name(uid):
    """Get owner name from UID"""
    try:
        import pwd
        try:
            return pwd.getpwuid(uid).pw_name
        except KeyError:
            return str(uid)
    except ImportError:
        # pwd module not available (Windows)
        return str(uid)

def get_group_name(gid):
    """Get group name from GID"""
    try:
        import grp
        try:
            return grp.getgrgid(gid).gr_name
        except KeyError:
            return str(gid)
    except ImportError:
        # grp module not available (Windows)
        return str(gid)

def is_valid_path(path):
    """Check if path exists and is accessible"""
    try:
        return os.path.exists(path) or os.path.islink(path)
    except (OSError, PermissionError):
        return False

def should_exclude_path(path, base_dir, exclude_patterns):
    """
    Check if a path should be excluded based on exclude patterns.
    Supports both simple names and paths with slashes.
    
    Args:
        path: Full absolute path to check
        base_dir: Base directory for relative path calculation
        exclude_patterns: List of patterns to exclude (can be names or paths)
    
    Returns:
        True if path should be excluded, False otherwise
    """
    # Get relative path from base_dir
    try:
        rel_path = os.path.relpath(path, base_dir)
    except ValueError:
        # Path is not under base_dir, use absolute path
        rel_path = path
    
    # Normalize paths (use forward slashes for consistency)
    rel_path_normalized = rel_path.replace(os.sep, '/')
    path_name = os.path.basename(path)
    
    # Check each exclude pattern
    for pattern in exclude_patterns:
        # Normalize pattern
        pattern_normalized = pattern.replace(os.sep, '/')
        
        # Check 1: Exact match with folder/file name
        if path_name == pattern or path_name == os.path.basename(pattern):
            return True
        
        # Check 2: Match relative path (exact or pattern)
        if rel_path_normalized == pattern_normalized:
            return True
        
        # Check 3: Pattern matching with wildcards (e.g., "storage/*")
        if fnmatch.fnmatch(rel_path_normalized, pattern_normalized):
            return True
        
        # Check 4: Check if path starts with pattern (e.g., "storage/framework" matches "storage/framework/cache")
        if rel_path_normalized.startswith(pattern_normalized + '/'):
            return True
        
        # Check 5: Check if any parent directory matches (e.g., "storage" in "storage/framework/cache")
        path_parts = rel_path_normalized.split('/')
        pattern_parts = pattern_normalized.split('/')
        # Check if pattern matches any segment of the path
        for i in range(len(path_parts)):
            if '/'.join(path_parts[:i+1]) == pattern_normalized:
                return True
            # Also check with wildcard
            if fnmatch.fnmatch('/'.join(path_parts[:i+1]), pattern_normalized):
                return True
    
    return False

def should_exclude_file(file_path, base_dir, exclude_file_patterns):
    """
    Check if a file should be excluded based on file patterns.
    Supports wildcards (e.g., *.log, *.tmp) and exact filenames.
    
    Args:
        file_path: Full absolute path to the file
        base_dir: Base directory for relative path calculation
        exclude_file_patterns: List of file patterns to exclude (e.g., ["*.log", ".env"])
    
    Returns:
        True if file should be excluded, False otherwise
    """
    if not exclude_file_patterns:
        return False
    
    # Get relative path from base_dir
    try:
        rel_path = os.path.relpath(file_path, base_dir)
    except ValueError:
        rel_path = file_path
    
    # Normalize paths (use forward slashes for consistency)
    rel_path_normalized = rel_path.replace(os.sep, '/')
    file_name = os.path.basename(file_path)
    
    # Check each file exclude pattern
    for pattern in exclude_file_patterns:
        # Normalize pattern
        pattern_normalized = pattern.replace(os.sep, '/')
        
        # Check 1: Exact filename match
        if file_name == pattern or file_name == os.path.basename(pattern):
            return True
        
        # Check 2: Wildcard pattern matching on filename (e.g., "*.log")
        if fnmatch.fnmatch(file_name, pattern_normalized):
            return True
        
        # Check 3: Wildcard pattern matching on relative path (e.g., "logs/*.log")
        if fnmatch.fnmatch(rel_path_normalized, pattern_normalized):
            return True
        
        # Check 4: Check if relative path matches pattern (e.g., ".env" matches "app/.env")
        if rel_path_normalized.endswith('/' + pattern_normalized) or rel_path_normalized == pattern_normalized:
            return True
        
        # Check 5: Pattern with path (e.g., "storage/*.log")
        if '/' in pattern_normalized:
            if fnmatch.fnmatch(rel_path_normalized, pattern_normalized):
                return True
            # Also check if path ends with pattern
            if rel_path_normalized.endswith(pattern_normalized):
                return True
    
    return False

if __name__ == '__main__':
    main()
