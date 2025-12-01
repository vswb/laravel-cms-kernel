#!/bin/bash

# ==== Detect PHP version của project hiện tại ====
PROJECT_PHP=$(valet which | awk '{print $1}')
if [ -z "$PROJECT_PHP" ]; then
    echo "Không thể detect PHP version. Dùng php@8.4 làm mặc định."
    PROJECT_PHP="php@8.4"
fi

USER=$(whoami)

echo "=== 1. Stop tất cả PHP services sai user/root ==="
brew services list | grep php | awk '{print $1}' | while read service; do
    if brew services list | grep $service | grep -q "root"; then
        echo "Stopping $service chạy dưới root ..."
        sudo brew services stop $service
    else
        echo "Stopping $service ..."
        brew services stop $service
    fi
done

sleep 2

echo "=== 2. Start PHP-FPM đúng user ($USER) cho project ($PROJECT_PHP) ==="
brew services start $PROJECT_PHP
sleep 3

echo "=== 3. Force switch Valet sang PHP $PROJECT_PHP ==="
valet use $PROJECT_PHP --force
sleep 2

echo "=== 4. Restart Valet (Nginx + PHP-FPM) ==="
valet restart

echo "=== 5. Kiểm tra PHP-FPM đang chạy dưới user $USER ==="
ps aux | grep php | grep -v grep

echo "✅ Hoàn tất. Hãy refresh website local của bạn."
