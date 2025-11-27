# Security Headers Fix - Giải quyết Missing Headers

## 🔍 Vấn đề

Báo cáo thiếu các headers:
- ❌ Strict-Transport-Security
- ❌ Content-Security-Policy
- ❌ Permissions-Policy

## ✅ Đã sửa

### 1. Middleware chỉ chạy cho API routes

**Vấn đề:**
- `SecurityHeaders` middleware chỉ được push vào `api` group
- Web routes không có security headers

**Giải pháp:**
```php
// Push vào cả API và Web groups
$router->pushMiddlewareToGroup('api', \Dev\Kernel\Http\Middleware\SecurityHeaders::class);
$router->pushMiddlewareToGroup('web', \Dev\Kernel\Http\Middleware\SecurityHeaders::class);
```

### 2. HSTS chỉ set khi HTTPS

**Vấn đề:**
- HSTS header được set cả khi HTTP, gây lỗi hoặc warning

**Giải pháp:**
```php
// Chỉ set HSTS khi HTTPS
if ($request->secure() || $request->header('X-Forwarded-Proto') === 'https') {
    $response->headers->set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');
}
```

### 3. CSP quá strict

**Vấn đề:**
- CSP `script-src 'self'` block CDN scripts
- Không cho phép inline styles/scripts

**Giải pháp:**
```php
// CSP linh hoạt hơn, cho phép CDN và inline
"script-src 'self' 'unsafe-inline' 'unsafe-eval' https: http:"
"style-src 'self' 'unsafe-inline' https: http:"
```

### 4. Headers bị ghi đè

**Vấn đề:**
- Headers có thể bị ghi đè bởi middleware khác

**Giải pháp:**
```php
// Sử dụng parameter thứ 3 = false để không replace nếu đã tồn tại
$response->headers->set('Header-Name', 'value', false);
```

### 5. Chỉ set cho HTTP Response

**Vấn đề:**
- Headers được set cho mọi response type (redirects, JSON, etc.)

**Giải pháp:**
```php
// Chỉ set cho HTTP Response
if (!$response instanceof Response) {
    return $response;
}
```

## 📋 Headers được set

### ✅ Strict-Transport-Security
- **Khi nào:** Chỉ khi HTTPS
- **Giá trị:** `max-age=31536000; includeSubDomains; preload`
- **Mục đích:** Bắt buộc trình duyệt chỉ dùng HTTPS

### ✅ Content-Security-Policy
- **Khi nào:** Luôn luôn
- **Giá trị:** Dynamic, có thể config
- **Mục đích:** Chống XSS attacks

### ✅ Permissions-Policy
- **Khi nào:** Luôn luôn
- **Giá trị:** `camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=()`
- **Mục đích:** Giới hạn browser APIs

### ✅ X-Content-Type-Options
- **Giá trị:** `nosniff`
- **Mục đích:** Chống MIME type sniffing

### ✅ X-Frame-Options
- **Giá trị:** `SAMEORIGIN`
- **Mục đích:** Chống clickjacking

### ✅ Referrer-Policy
- **Giá trị:** `strict-origin-when-cross-origin`
- **Mục đích:** Hạn chế rò rỉ referrer

### ✅ X-XSS-Protection
- **Giá trị:** `1; mode=block`
- **Mục đích:** Enable XSS filter (legacy support)

## 🧪 Cách test

### 1. Test qua curl:
```bash
# Test headers
curl -I https://your-domain.com

# Hoặc với verbose
curl -v https://your-domain.com
```

### 2. Test trong browser:
- Mở DevTools > Network tab
- Click vào request
- Xem Response Headers

### 3. Test với test route:
```bash
curl -I https://your-domain.com/api/v1/test/middleware-check
```

### 4. Online tools:
- https://securityheaders.com/
- https://observatory.mozilla.org/

## ⚙️ Configuration

### Tùy chỉnh CSP:

Tạo file config: `config/kernel/kernel.php`

```php
return [
    'security' => [
        'csp' => [
            "script-src 'self' 'unsafe-inline' https://cdn.example.com",
            "style-src 'self' 'unsafe-inline' https://cdn.example.com",
            // ... thêm directives khác
        ],
    ],
];
```

### Override middleware:

Nếu cần custom CSP, có thể extend middleware:

```php
namespace App\Http\Middleware;

use Dev\Kernel\Http\Middleware\SecurityHeaders;

class CustomSecurityHeaders extends SecurityHeaders
{
    protected function buildCsp($request): string
    {
        // Custom CSP logic
        return "default-src 'self'; script-src 'self' https://cdn.example.com;";
    }
}
```

## 🔧 Troubleshooting

### Headers không xuất hiện?

1. **Clear cache:**
   ```bash
   php artisan config:clear
   php artisan route:clear
   php artisan cache:clear
   ```

2. **Check middleware có chạy:**
   ```bash
   php artisan kernel:check-middleware --group=web
   php artisan kernel:check-middleware --group=api
   ```

3. **Check response type:**
   - Headers chỉ set cho HTTP Response
   - Redirects, JSON responses vẫn có headers

4. **Check server config:**
   - Nginx/Apache có thể remove headers
   - Check server config files

### HSTS không xuất hiện?

- **Chỉ set khi HTTPS:** Đảm bảo request là HTTPS
- **Check proxy:** Nếu dùng proxy, check `X-Forwarded-Proto` header

### CSP block resources?

- **Check CSP violations:** Mở DevTools > Console
- **Adjust CSP:** Sửa trong `buildCsp()` method hoặc config
- **Report-Only mode:** Có thể dùng `Content-Security-Policy-Report-Only` để test

## 📚 References

- [MDN: Strict-Transport-Security](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security)
- [MDN: Content-Security-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy)
- [MDN: Permissions-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Permissions-Policy)
- [Security Headers](https://securityheaders.com/)
- [CSP Evaluator](https://csp-evaluator.withgoogle.com/)

