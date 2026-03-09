# ☁️ Google Drive Storage & Mirror Sync Setup Guide

This guide provides a comprehensive, step-by-step walkthrough for integrating Google Drive storage into your Laravel application and configuring the **Google Drive Mirror Sync** functionality.

---

## 📋 Prerequisites

Ensure your project has the necessary driver installed:

```bash
composer require nao-pon/flysystem-google-drive:~1.1
```

---

## 🚀 Phase 1: Create Google Drive API Credentials

### 1.1 Create a Google Cloud Project
1. Log in to the [Google Cloud Console](https://console.developers.google.com/).
2. Create a new project using the dropdown at the top.
   ![Create Project](https://raw.githubusercontent.com/vswb/laravel-cms-kernel/v7.x/public/google-drive-guide/060eac9e-e56e-11e6-907c-717932605569.png)

### 1.2 Enable Google Drive API
1. Select your project.
2. Go to **Library** and search for **Google Drive API**.
3. Click **Enable**.
   ![Enable API](https://raw.githubusercontent.com/vswb/laravel-cms-kernel/v7.x/public/google-drive-guide/28462245-a13b3d9c-6e1a-11e7-8cf8-0082ac8a9141.png)

### 1.3 Configure OAuth Consent Screen
1. Go to **APIs & Services** > **OAuth Consent Screen**.
2. Select **External** (or Internal for Workspace users) and click **Create**.
3. Fill in the **Product name** and click **Save**.
   ![Consent Screen](https://raw.githubusercontent.com/vswb/laravel-cms-kernel/v7.x/public/google-drive-guide/549fb3c0-e56f-11e6-9b0a-8771b0ba72b4.png)

### 1.4 Create OAuth 2.0 Client ID
1. Go to **Credentials** > **Create Credentials** > **OAuth Client ID**.
2. Select **Web Application**.
3. Under **Authorized redirect URIs**, add: `https://developers.google.com/oauthplayground`.
   ![Credentials](https://raw.githubusercontent.com/vswb/laravel-cms-kernel/v7.x/public/google-drive-guide/28473452-e675826c-6e44-11e7-8ff0-bea423b0cff7.png)
4. Click **Create** and copy your **Client ID** and **Client Secret**.

---

## 🔑 Phase 2: Obtain your Refresh Token

1. Go to the [Google OAuth2 Playground](https://developers.google.com/oauthplayground).
2. Click the **Settings icon** (top right):
   - Check **Use your own OAuth credentials**.
   - Paste your **Client ID** and **Client Secret**.
   ![OAuth Credentials](https://raw.githubusercontent.com/vswb/laravel-cms-kernel/v7.x/public/google-drive-guide/24fe7d88-e56d-11e6-82cf-2d75365d8800.png)
3. **Step 1 (Select Scopes)**:
   - Scroll to **Drive API v3**.
   - Select `https://www.googleapis.com/auth/drive` (Full access).
   ![Check Scopes](https://raw.githubusercontent.com/vswb/laravel-cms-kernel/v7.x/public/google-drive-guide/28462312-fa4397ea-6e1a-11e7-93ad-365b891052a6.png)
   - Click **Authorize APIs** and allow access.
4. **Step 2 (Exchange Tokens)**:
   - Click **Exchange authorization code for tokens**.
   ![Exchange Tokens](https://raw.githubusercontent.com/vswb/laravel-cms-kernel/v7.x/public/google-drive-guide/8472095c-e56c-11e6-85be-83adf00837c7.png)
5. **Step 3 (Get Refresh Token)**:
   - Click back on **Step 2** to see your **Refresh Token**.
   ![Refresh Token](https://raw.githubusercontent.com/vswb/laravel-cms-kernel/v7.x/public/google-drive-guide/2cef7a98-e56c-11e6-83b9-b4653850dbca.png)

---

## 📁 Phase 3: Getting Folder ID

To store files in a specific folder, open the folder in Google Drive. The **Folder ID** is the alphanumeric string at the end of the URL.
![Folder ID](https://raw.githubusercontent.com/vswb/laravel-cms-kernel/v7.x/public/google-drive-guide/d79422ba-e56b-11e6-8ba6-01c622fdef42.png)

---

## ⚙️ Phase 4: Configuration

### 4.1 Environment Variables
Add the following to your `.env` file:

```env
FILESYSTEM_CLOUD=google

GOOGLE_DRIVE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_DRIVE_CLIENT_SECRET=your-client-secret
GOOGLE_DRIVE_REFRESH_TOKEN=your-refresh-token
GOOGLE_DRIVE_FOLDER_ID=null # Or a specific Folder ID
```

### 4.2 Filesystem Configuration
Ensure `config/filesystems.php` includes the `google` disk:

```php
'disks' => [
    // ...
    'google' => [
        'driver' => 'google',
        'clientId' => env('GOOGLE_DRIVE_CLIENT_ID'),
        'clientSecret' => env('GOOGLE_DRIVE_CLIENT_SECRET'),
        'refreshToken' => env('GOOGLE_DRIVE_REFRESH_TOKEN'),
        'folderId' => env('GOOGLE_DRIVE_FOLDER_ID'),
    ],
    // ...
],
```

---

## 🛠️ Usage

### Artisan Command (Mirror Sync)
The kernel provides a command to mirror local folders to Google Drive:

```bash
# Using a relative/absolute path
php artisan gdrive:mirror:sync "path/to/local/folder" --delete --retry=5

# Using a specific Google Drive Folder ID
php artisan gdrive:mirror:sync "13xTtnd1T2qyUQ0p6quagAlzpdd9Hp6-l" --delete
```

### Programmatic Usage
```php
use Illuminate\Support\Facades\Storage;

// Using the default cloud disk
Storage::cloud()->put('test.txt', 'Hello World');

// List files
$files = Storage::cloud()->listContents('/', false);
```

---

## 💡 Pro Tips

- **Multiple Accounts**: You can define multiple disks (e.g., `google_main`, `google_backup`) in `config/filesystems.php` with different `.env` keys.
- **Security**: Never commit your `.env` file or actual credentials to version control.
