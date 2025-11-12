# Binary Scripts Documentation

This package includes a comprehensive collection of utility scripts that are automatically installed to your project's `bin/` directory.

## 📦 Automatic Installation

All scripts are **automatically symlinked** during:
- `composer install`
- `composer update`

The scripts will be available at: `ROOT/bin/`

---

## 📜 Available Scripts

### 🐳 Docker & Infrastructure

#### `docker-setup-laravel.sh`
Setup Docker environment specifically for Laravel applications.

```bash
./bin/docker-setup-laravel.sh
```

#### `docker-setup.sh`
General Docker environment setup script.

```bash
./bin/docker-setup.sh
```

---

### 🚀 Deployment & Setup

#### `make-deployment.sh`
Create and prepare deployment packages.

```bash
./bin/make-deployment.sh
```

#### `bootstrap.sh`
Bootstrap and initialize the application environment.

```bash
./bin/bootstrap.sh
```

#### `make-directory.sh`
Create necessary directory structures with proper permissions.

```bash
./bin/make-directory.sh
```

---

### 🔐 GitLab CI/CD

#### `gitlab-cicd-setup.sh`
Setup GitLab CI/CD pipelines for the project.

```bash
./bin/gitlab-cicd-setup.sh
```

#### `gitlab-install-commit-hook.sh`
Install GitLab commit hooks for enforcing commit message standards.

```bash
./bin/gitlab-install-commit-hook.sh
```

#### `gitlab-commits-export.py`
Export GitLab commit history to various formats.

```bash
python ./bin/gitlab-commits-export.py
```

#### `gitlab-commits-callapi.py`
Call GitLab API to retrieve commit information.

```bash
python ./bin/gitlab-commits-callapi.py
```

#### `gitlab-query.sh`
Query GitLab for project information.

```bash
./bin/gitlab-query.sh
```

---

### 🖼️ Image & Document Optimization

#### `optimize-image.sh`
Optimize image files (JPG, PNG, etc.) for web use.

```bash
./bin/optimize-image.sh path/to/image.jpg
./bin/optimize-image.sh path/to/directory/
```

#### `optimize-pdfcompress.py`
Compress PDF files to reduce file size.

```bash
python ./bin/optimize-pdfcompress.py input.pdf output.pdf
```

#### `optimize-shrinkpdf.sh`
Alternative PDF compression using Ghostscript.

```bash
./bin/optimize-shrinkpdf.sh input.pdf output.pdf
```

---

### 📱 Barcode & QR Code Processing

#### `decode_barcode.py`
Decode barcodes from image files.

```bash
python ./bin/decode_barcode.py image.jpg
```

#### `decode_barcode_debug.py`
Debug version of barcode decoder with verbose output.

```bash
python ./bin/decode_barcode_debug.py image.jpg
```

#### `decode_qr.py`
Decode QR codes from image files.

```bash
python ./bin/decode_qr.py qrcode.png
```

---

### 🔍 Security & Maintenance

#### `scan-malware.sh`
Scan project files for potential malware and security threats.

```bash
./bin/scan-malware.sh
./bin/scan-malware.sh /path/to/scan
```

#### `search-replace.sh`
Search and replace text across multiple files.

```bash
./bin/search-replace.sh "old-text" "new-text" "*.php"
```

---

### 📄 Data Processing

#### `convert-number-to-words.php`
Convert numbers to words (useful for invoices, reports).

```bash
php ./bin/convert-number-to-words.php 12345
# Output: twelve thousand three hundred forty-five
```

---

### 🖨️ Scanner Integration

#### `scanner-ricoh_gdrive.sh`
Setup Ricoh scanner integration with Google Drive.

```bash
./bin/scanner-ricoh_gdrive.sh
```

#### `scanner-ricoh_nextcloud.sh`
Setup Ricoh scanner integration with Nextcloud.

```bash
./bin/scanner-ricoh_nextcloud.sh
```

---

### 🔧 Utilities

#### `search.loop-and-zip.sh`
Search files, process them in a loop, and create archives.

```bash
./bin/search.loop-and-zip.sh
```

#### `test.sh`
General testing script for various functionalities.

```bash
./bin/test.sh
```

#### `letsencryp.sh`
Let's Encrypt SSL certificate management.

```bash
./bin/letsencryp.sh
```

---

### 🧹 Cleanup Scripts

#### `remove-bb-change-structure.sh`
Remove Botble CMS and restructure the application.

```bash
./bin/remove-bb-change-structure.sh
```

#### `remove-bb-sql.sh`
Clean up Botble CMS database tables.

```bash
./bin/remove-bb-sql.sh
```

#### `remove-bb-theme.sh`
Remove Botble CMS theme files.

```bash
./bin/remove-bb-theme.sh
```

---

### 🌐 WordPress

#### `wordpress_auto_install.sh`
Automated WordPress installation script.

```bash
./bin/wordpress_auto_install.sh
```

---

## 🐛 Debug Tools

The package includes debug utilities in `bin/debug/` and `bin/debug_ocr/` directories:

- OCR debugging tools
- Image processing debug utilities
- Various development helpers

---

## ⚙️ Configuration

### Making Scripts Executable

All scripts are automatically made executable during installation. If needed, you can manually set permissions:

```bash
chmod +x bin/*.sh
chmod +x bin/*.py
chmod +x bin/*.php
```

### Python Scripts Requirements

Some Python scripts may require additional dependencies:

```bash
pip install -r requirements.txt  # if provided
```

Common Python packages used:
- `Pillow` - Image processing
- `pyzbar` - Barcode/QR code decoding
- `requests` - API calls

---

## 🔄 Manual Installation

If automatic installation doesn't work, you can manually run:

```bash
php vendor/dev-extensions/kernel/bin/install-binaries.php
```

---

## 📝 Notes

1. **Symlinks**: All binaries are symlinked, not copied. Updates to the package automatically reflect in your project.

2. **Conflicts**: If a file already exists in `ROOT/bin/` (and is not a symlink), it won't be overwritten.

3. **Platform Compatibility**: 
   - Shell scripts (`.sh`) work on Linux/macOS
   - Python scripts require Python 3.x
   - PHP scripts require PHP 7.4+

4. **Removal**: To remove symlinked binaries:
   ```bash
   rm bin/*  # Be careful with this command
   ```

---

## 🆘 Troubleshooting

### Scripts not found after installation

```bash
# Manually run the installer
php vendor/dev-extensions/kernel/bin/install-binaries.php

# Check if bin directory exists
ls -la bin/
```

### Permission denied errors

```bash
# Make scripts executable
chmod +x bin/*.sh bin/*.py bin/*.php
```

### Symlink errors on Windows

Windows may require administrator privileges for symlinks. Consider:
- Running as administrator
- Enabling Developer Mode in Windows 10/11
- Using WSL (Windows Subsystem for Linux)

---

## 📄 License

All binary scripts are included under the same MIT license as the package.

---

**Package**: dev-extensions/kernel  
**Documentation**: [README.md](readme.md)

