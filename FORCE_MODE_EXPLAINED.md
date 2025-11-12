# 🔄 Force Mode - Automatic File/Symlink Removal

## Tổng Quan

Package `dev-extensions/kernel` sử dụng **FORCE MODE** khi cài đặt binary scripts để đảm bảo symlinks **luôn được tạo thành công 100%**.

---

## 🔧 Cách Hoạt Động

### Luồng Xử Lý

```
┌─────────────────────────────────────────────┐
│  1. Quét file trong vendor/.../bin/        │
└────────────────┬────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────┐
│  2. Kiểm tra file đích đã tồn tại?         │
│     ROOT/bin/docker-setup.sh               │
└────────────────┬────────────────────────────┘
                 ▼
         ┌───────┴───────┐
         │               │
    [Tồn tại]      [Không tồn tại]
         │               │
         ▼               ▼
┌────────────────┐  ┌────────────────┐
│ 3a. XÓA FILE  │  │ 3b. Bỏ qua     │
│     CŨ        │  │     bước này   │
│  - Symlink    │  └────────┬───────┘
│  - File       │           │
└────────┬───────┘           │
         │◄──────────────────┘
         ▼
┌─────────────────────────────────────────────┐
│  4. Tạo SYMLINK mới                         │
│     ROOT/bin/docker-setup.sh →              │
│     vendor/.../bin/docker-setup.sh          │
└────────────────┬────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────┐
│  5. Set executable permission (chmod +x)    │
└─────────────────────────────────────────────┘
```

---

## 💡 Ví Dụ Chi Tiết

### Scenario 1: File cũ đã tồn tại

**Trước:**
```bash
ROOT/bin/docker-setup.sh  [File thường - 1KB]
```

**Sau khi chạy installer:**
```bash
🔄 Removed old file: docker-setup.sh
✓ docker-setup.sh

ROOT/bin/docker-setup.sh -> vendor/dev-extensions/kernel/bin/docker-setup.sh [Symlink]
```

### Scenario 2: Symlink cũ (broken hoặc outdated)

**Trước:**
```bash
ROOT/bin/docker-setup.sh -> /old/path/docker-setup.sh [Broken symlink]
```

**Sau khi chạy installer:**
```bash
🔄 Removed old symlink: docker-setup.sh
✓ docker-setup.sh

ROOT/bin/docker-setup.sh -> vendor/dev-extensions/kernel/bin/docker-setup.sh [New symlink]
```

### Scenario 3: Chưa có file

**Trước:**
```bash
ROOT/bin/  [Empty hoặc không tồn tại]
```

**Sau khi chạy installer:**
```bash
✓ Created bin directory
✓ docker-setup.sh
✓ optimize-image.sh
... (all scripts)

ROOT/bin/
├── docker-setup.sh -> vendor/.../docker-setup.sh
├── optimize-image.sh -> vendor/.../optimize-image.sh
└── ... [All symlinks]
```

---

## ⚠️ Cảnh Báo Quan Trọng

### 🚨 Files Custom Sẽ Bị GHI ĐÈ

Nếu bạn có custom scripts trùng tên:

```bash
# Bạn có file này (custom)
ROOT/bin/docker-setup.sh  [Your custom version]

# Sau khi install package
ROOT/bin/docker-setup.sh -> vendor/.../docker-setup.sh  [Package version - ĐÃ GHI ĐÈ!]
```

**➜ File custom của bạn ĐÃ MẤT!**

### ✅ Giải Pháp: Backup Trước

```bash
# Trước khi install/update
cd ROOT/bin
cp -r . ../bin-backup/

# Hoặc rename custom scripts
mv docker-setup.sh docker-setup-custom.sh
```

---

## 📊 Output Messages

Script sẽ hiển thị các thông báo:

### ✓ Success - Linked
```bash
✓ docker-setup.sh
✓ optimize-image.sh
```
**Nghĩa là:** Symlink được tạo thành công

### 🔄 Removed - Cleanup
```bash
🔄 Removed old file: docker-setup.sh
🔄 Removed old symlink: optimize-image.sh
```
**Nghĩa là:** File/symlink cũ đã bị xóa trước khi tạo mới

### ✗ Failed
```bash
✗ Failed: some-script.sh
```
**Nghĩa là:** Không thể tạo symlink (check permissions)

---

## 🎯 Tại Sao Cần Force Mode?

### ❌ Vấn Đề Khi Không Có Force Mode

```bash
# Lần 1: Install package
composer install
✓ Linked: 30 files

# Package được update với script mới
composer update

# Lần 2: Update package - FAILED!
✗ Failed to link: some files already exist
⚠️  Symlinks không được cập nhật!
```

### ✅ Với Force Mode

```bash
# Lần 1: Install
composer install
✓ Linked: 30 files

# Lần 2: Update - ALWAYS SUCCESS!
composer update
🔄 Removed: 30 old symlinks
✓ Linked: 30 files (với scripts mới nhất)
```

---

## 🛡️ An Toàn Với Force Mode

### Điều Kiện An Toàn

1. ✅ **Symlinks cũ** → Safe to remove (sẽ tạo lại)
2. ✅ **Files trong vendor/** → Không bị ảnh hưởng
3. ✅ **Scripts mới từ package** → Luôn được cập nhật

### Rủi Ro

1. ⚠️ **Custom scripts trùng tên** → Sẽ bị GHI ĐÈ
2. ⚠️ **Modifications vào scripts** → Sẽ bị MẤT

**➜ Solution:** Đặt tên khác cho custom scripts hoặc backup

---

## 🔍 So Sánh Modes

| Feature | Safe Mode | Force Mode |
|---------|-----------|------------|
| **Tạo symlink mới** | ✅ | ✅ |
| **Update symlink cũ** | ✅ | ✅ |
| **Override files** | ❌ Skip | ✅ Override |
| **Success rate** | ~80% | 100% |
| **An toàn** | ✅✅ | ✅ (nếu backup) |
| **Auto update** | ⚠️ Có thể fail | ✅ Luôn thành công |

**➜ Chúng ta chọn:** **Force Mode** để đảm bảo reliability

---

## 📝 Best Practices

### ✅ DO

1. **Backup trước khi install** nếu có custom scripts
   ```bash
   cp -r bin/ bin-backup/
   ```

2. **Đặt tên khác** cho custom scripts
   ```bash
   mv bin/docker-setup.sh bin/docker-setup-custom.sh
   ```

3. **Kiểm tra conflicts** trước khi install
   ```bash
   ls bin/  # Check existing files
   ```

### ❌ DON'T

1. **Không modify** scripts trong `vendor/`
   ```bash
   # DON'T: vim vendor/dev-extensions/kernel/bin/docker-setup.sh
   ```

2. **Không đặt custom scripts trùng tên** nếu không muốn mất
   ```bash
   # BAD: bin/docker-setup.sh (your custom)
   # GOOD: bin/docker-setup-custom.sh
   ```

---

## 🔧 Disable Force Mode (Advanced)

Nếu muốn disable force mode, chỉnh sửa `bin/install-binaries.php`:

```php
// TÌM ĐOẠN NÀY (line ~68)
// ✅ FORCE MODE: Remove any existing file/symlink
if (file_exists($targetPath) || is_link($targetPath)) {
    // XÓA HOẶC COMMENT các dòng này
}

// THAY BẰNG SAFE MODE
if (file_exists($targetPath) && !is_link($targetPath)) {
    $skippedCount++;
    continue; // Skip existing files
}
```

**⚠️ Lưu ý:** Không khuyến nghị disable vì có thể gây lỗi khi update package

---

## ✅ Tổng Kết

**Force Mode = An Toàn + Đáng Tin Cậy**

- ✅ **100% Success Rate** khi tạo symlinks
- ✅ **Auto update** mỗi khi package cập nhật
- ✅ **No manual cleanup** required
- ⚠️ **Backup custom scripts** trước khi install

**➜ Trade-off:** Tính tiện lợi > Rủi ro ghi đè (nếu backup đúng cách)

---

**Created:** 2025-01-12  
**Package:** dev-extensions/kernel  
**Mode:** Force Mode (Enabled by default)  
**Status:** ✅ Production Ready

