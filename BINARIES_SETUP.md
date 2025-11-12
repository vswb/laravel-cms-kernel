# Hướng Dẫn Cài Đặt Binary Scripts Tự Động

## 🎯 Mục Đích

Tự động tạo symlinks cho **TẤT CẢ** files/folders trong `vendor/dev-extensions/kernel/bin/` ra `ROOT/bin/` của project.

---

## 📋 Cách Hoạt Động

### 1. Composer Scripts Hook

File `composer.json` đã được cấu hình:

```json
{
    "scripts": {
        "post-install-cmd": [
            "@php vendor/dev-extensions/kernel/bin/install-binaries.php"
        ],
        "post-update-cmd": [
            "@php vendor/dev-extensions/kernel/bin/install-binaries.php"
        ]
    }
}
```

**Khi nào chạy:**
- ✅ `composer install` - Cài đặt package lần đầu
- ✅ `composer update` - Cập nhật package
- ✅ Manual: `composer run-script post-install-cmd`

### 2. Install Script

File `bin/install-binaries.php` sẽ:

1. **Quét tất cả files/folders** trong `bin/` directory
2. **Tạo symlinks** vào `ROOT/bin/` của project
3. **Set permissions** executable cho các file `.sh`, `.py`, `.php`
4. **Bỏ qua** files đã tồn tại (không phải symlink) để tránh override
5. **Hiển thị summary** về số lượng files đã link

---

## 🔧 Cách Sử Dụng

### Automatic (Khuyến nghị)

Khi cài đặt/update package, scripts sẽ tự động được link:

```bash
# Cài đặt package
composer require dev-extensions/kernel

# Hoặc update
composer update dev-extensions/kernel

# Scripts đã sẵn sàng trong ROOT/bin/
./bin/docker-setup-laravel.sh
./bin/optimize-image.sh
```

### Manual

Chạy installer thủ công nếu cần:

```bash
php vendor/dev-extensions/kernel/bin/install-binaries.php
```

---

## 📁 Cấu Trúc Thư Mục

### Trước khi cài đặt

```
project-root/
├── vendor/
│   └── dev-extensions/
│       └── kernel/
│           └── bin/
│               ├── docker-setup.sh
│               ├── optimize-image.sh
│               ├── scan-malware.sh
│               └── ...
└── (chưa có bin/)
```

### Sau khi cài đặt

```
project-root/
├── vendor/
│   └── dev-extensions/
│       └── kernel/
│           └── bin/
│               ├── docker-setup.sh          [SOURCE]
│               ├── optimize-image.sh        [SOURCE]
│               └── ...
└── bin/                                     [CREATED]
    ├── docker-setup.sh -> ../vendor/...    [SYMLINK]
    ├── optimize-image.sh -> ../vendor/...  [SYMLINK]
    └── ...
```

---

## ✨ Tính Năng

### ✅ Symlink (Không Copy)

- Files được **symlink**, không copy
- Update package → scripts tự động cập nhật
- Không tốn dung lượng disk

### ✅ Recursive (Bao gồm cả thư mục con)

Tất cả files/folders trong `bin/` sẽ được link:

```
bin/
├── script.sh                    → Linked
├── folder/
│   ├── nested-script.sh         → Linked
│   └── deep/
│       └── deep-script.py       → Linked
└── debug/
    └── debug-tool.php           → Linked
```

### ✅ Safe Mode (Không Override)

- ❌ Không override files đã tồn tại (non-symlink)
- ✅ Chỉ tạo symlink mới hoặc update symlink cũ
- 📊 Báo cáo số lượng skipped files

### ✅ Auto Executable

Scripts được tự động set executable permission:
- `.sh` files → `chmod +x`
- `.py` files → `chmod +x`
- `.php` files → `chmod +x`

---

## 🎨 Output Example

Khi chạy installer:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Laravel CMS Kernel - Installing Binaries
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Created bin directory: /path/to/project/bin
  ✓ bootstrap.sh
  ✓ docker-setup-laravel.sh
  ✓ docker-setup.sh
  ✓ optimize-image.sh
  ✓ scan-malware.sh
  ✓ debug/tool.php
  ... (more files)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary:
  Linked: 32 files
  Skipped: 0 files
  Target: /path/to/project/bin
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🔍 Kiểm Tra

### Verify Symlinks

```bash
# List symlinks
ls -la bin/

# Output example:
lrwxr-xr-x  1 user  group  ../vendor/dev-extensions/kernel/bin/docker-setup.sh -> docker-setup.sh
lrwxr-xr-x  1 user  group  ../vendor/dev-extensions/kernel/bin/optimize-image.sh -> optimize-image.sh
```

### Test Scripts

```bash
# Test một script
./bin/docker-setup-laravel.sh --version

# Check executable
which docker-setup-laravel.sh
```

---

## 🚨 Troubleshooting

### Scripts không được link

**Nguyên nhân:** Composer scripts không chạy

**Giải pháp:**
```bash
# Chạy manual
php vendor/dev-extensions/kernel/bin/install-binaries.php

# Hoặc force composer scripts
composer run-script post-install-cmd
```

### Permission denied

**Nguyên nhân:** Script không executable

**Giải pháp:**
```bash
chmod +x bin/*.sh
chmod +x bin/*.py
chmod +x bin/*.php
```

### Symlink error trên Windows

**Nguyên nhân:** Windows cần admin privileges

**Giải pháp:**
1. Chạy terminal as Administrator
2. Enable Developer Mode (Windows 10/11)
3. Hoặc dùng WSL

### Files bị skipped

**Nguyên nhân:** File đã tồn tại và không phải symlink

**Giải pháp:**
```bash
# Xóa file cũ
rm bin/conflicting-file.sh

# Chạy lại installer
php vendor/dev-extensions/kernel/bin/install-binaries.php
```

---

## 🔧 Customization

### Exclude Specific Files

Chỉnh sửa `bin/install-binaries.php`:

```php
$excludeFiles = [
    'install-binaries.php',
    'your-excluded-file.sh',
    'another-excluded.py'
];
```

### Change Target Directory

Mặc định: `ROOT/bin/`

Để thay đổi, chỉnh sửa:

```php
$projectBinDir = $projectRoot . '/scripts'; // Thay vì /bin
```

---

## 📚 Tham Khảo

- **[BINARIES.md](BINARIES.md)** - Chi tiết về từng script
- **[README.md](readme.md)** - Tài liệu chính của package
- **Composer Scripts**: https://getcomposer.org/doc/articles/scripts.md

---

## ✅ Checklist

Sau khi setup, verify:

- [ ] Folder `ROOT/bin/` được tạo
- [ ] Scripts được symlink vào `bin/`
- [ ] Scripts có executable permission
- [ ] Test chạy 1-2 scripts để verify
- [ ] Update package để test auto-update

---

**Created:** 2025-01-12  
**Package:** dev-extensions/kernel  
**Status:** ✅ Production Ready

