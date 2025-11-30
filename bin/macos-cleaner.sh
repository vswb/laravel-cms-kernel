#!/bin/bash

echo "========================================"
echo "         MAC CLEANER MENU"
echo "========================================"
echo "1) Basic Clean (An toàn)"
echo "2) Advanced Clean (Dọn sâu an toàn)"
echo "3) Dev Deep Clean (Lập trình viên)"
echo "========================================"
read -p "Chọn 1, 2 hoặc 3: " choice

folder_size() {
    du -sh "$1" 2>/dev/null | awk '{print $1}'
}

basic_clean() {
    echo "=== BASIC CLEAN START ==="
    TARGETS=(
        "~/.Trash"
        "~/Library/Logs"
        "~/Library/Caches/com.apple.Safari"
        "~/Library/Safari/LocalStorage"
        "~/Library/Safari/Databases"
        "~/Library/Application Support/Google/Chrome/Default/Cache"
    )
    for dir in "${TARGETS[@]}"; do
        if [ -d "$(eval echo $dir)" ]; then
            size_before=$(eval folder_size $dir)
            rm -rf "$(eval echo $dir)"/*
            size_after=$(eval folder_size $dir)
            echo "Cleared $dir: $size_before -> $size_after"
        fi
    done
    echo "=== BASIC CLEAN COMPLETE ==="
}

advanced_clean() {
    echo "=== ADVANCED CLEAN START ==="
    TARGETS=(
        "~/Library/Logs/DiagnosticReports"
        "~/Library/Application Support/*/Cache*"
        "~/Library/Containers/*/Data/Library/Caches"
        "~/Library/Saved Application State/*.savedState"
    )
    for dir in "${TARGETS[@]}"; do
        eval expanded_dir="$dir"
        for d in $expanded_dir; do
            if [ -d "$d" ]; then
                size_before=$(folder_size "$d")
                rm -rf "$d"/*
                size_after=$(folder_size "$d")
                echo "Cleared $d: $size_before -> $size_after"
            fi
        done
    done
    echo "=== ADVANCED CLEAN COMPLETE ==="
}

dev_deep_clean() {
    echo "=== DEV DEEP CLEAN START ==="

    # Homebrew
    if command -v brew &>/dev/null; then
        size_before=$(folder_size "$(brew --cache)")
        echo "Cleaning Homebrew cache..."
        brew cleanup -s
        brew autoremove
        rm -rf "$(brew --cache)"
        size_after=$(folder_size "$(brew --cache)")
        echo "Homebrew cache: $size_before -> $size_after"
    else
        echo "Homebrew not found, skipping."
    fi

    # Node / npm / yarn / pnpm
    echo "Cleaning Node/NPM/Yarn/PNPM caches..."
    npm cache clean --force 2>/dev/null
    yarn cache clean 2>/dev/null
    pnpm store prune 2>/dev/null

    # VSCode / Cursor caches
    CACHE_DIRS=(
        ~/Library/Application\ Support/Code
        ~/Library/Application\ Support/Cursor
    )
    for dir in "${CACHE_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            size_before=$(folder_size "$dir")
            rm -rf "$dir/Cache" "$dir/CachedData" "$dir/User/workspaceStorage" "$dir/Service Worker/CacheStorage" "$dir/logs" 2>/dev/null
            size_after=$(folder_size "$dir")
            echo "Cleared caches in $dir: $size_before -> $size_after"
        fi
    done

    # Docker
    if command -v docker &>/dev/null; then
        echo "Cleaning Docker..."
        docker system prune -a --volumes -f
        docker builder prune -f
    else
        echo "Docker not found, skipping."
    fi

    # Xcode safe cleanup
    XCODE_DERIVED=~/Library/Developer/Xcode/DerivedData
    XCODE_ARCHIVES=~/Library/Developer/Xcode/Archives
    XCODE_DEVICE=~/Library/Developer/Xcode/iOS\ DeviceSupport

    [ -d "$XCODE_DERIVED" ] && size_before=$(folder_size "$XCODE_DERIVED") && rm -rf "$XCODE_DERIVED" && size_after=$(folder_size "$XCODE_DERIVED") && echo "Xcode DerivedData: $size_before -> $size_after"
    [ -d "$XCODE_ARCHIVES" ] && size_before=$(folder_size "$XCODE_ARCHIVES") && rm -rf "$XCODE_ARCHIVES" && size_after=$(folder_size "$XCODE_ARCHIVES") && echo "Xcode Archives: $size_before -> $size_after"

    if [ -d "$XCODE_DEVICE" ]; then
        DEVICES=$(find "$XCODE_DEVICE" -maxdepth 1 -type d -name "1[0-4]*" 2>/dev/null)
        for device in $DEVICES; do
            size_before=$(folder_size "$device")
            rm -rf "$device"
            size_after=$(folder_size "$device")
            echo "Removed DeviceSupport $device: $size_before -> $size_after"
        done
    fi

    # Composer
    if command -v composer &>/dev/null; then
        COMPOSER_CACHE=~/.composer/cache
        size_before=$(folder_size "$COMPOSER_CACHE")
        composer clear-cache
        size_after=$(folder_size "$COMPOSER_CACHE")
        echo "Composer cache: $size_before -> $size_after"
    fi

    # Python pip
    if command -v pip &>/dev/null; then
        PIP_CACHE=~/Library/Caches/pip
        size_before=$(folder_size "$PIP_CACHE")
        pip cache purge 2>/dev/null
        size_after=$(folder_size "$PIP_CACHE")
        echo "Pip cache: $size_before -> $size_after"
    fi

    # Node_modules trong Cursor extensions
    CURSOR_EXT=~/Library/Application\ Support/Cursor/extensions
    if [ -d "$CURSOR_EXT" ]; then
        echo "Listing node_modules in Cursor extensions (no deletion)..."
        find "$CURSOR_EXT" -name "node_modules" -type d -prune 2>/dev/null -exec echo "Found: {}" \;
    fi

    # Simulator cache
    SIM_CACHE=~/Library/Developer/CoreSimulator/Caches
    if [ -d "$SIM_CACHE" ]; then
        size_before=$(folder_size "$SIM_CACHE")
        rm -rf "$SIM_CACHE"
        size_after=$(folder_size "$SIM_CACHE")
        echo "Simulator cache: $size_before -> $size_after"
    fi

    echo "=== DEV DEEP CLEAN COMPLETE ==="
}

case $choice in
    1) basic_clean ;;
    2) advanced_clean ;;
    3) dev_deep_clean ;;
    *) echo "Lựa chọn không hợp lệ!" ;;
esac