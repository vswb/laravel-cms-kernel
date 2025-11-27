# 🧪 Hướng dẫn Test Middleware

## 📋 Tổng quan

Có 3 cách để kiểm tra middleware đã hoạt động:

1. **Artisan Command** - Kiểm tra cấu hình middleware
2. **Test Route** - Test thực tế qua HTTP request
3. **Manual Check** - Kiểm tra thủ công từng middleware

---

## 1️⃣ Artisan Command (Recommended)

### Chạy command để kiểm tra middleware:

```bash
# Kiểm tra middleware group 'api'
php artisan kernel:check-middleware --group=api

# Xem chi tiết
php artisan kernel:check-middleware --group=api --detail

# List tất cả middleware
php artisan kernel:check-middleware --group=api --list
```

### Output sẽ hiển thị:

- ✅ Danh sách middleware trong group
- ✅ Middleware nào đã có, middleware nào thiếu
- ✅ Thứ tự middleware
- ✅ File path của từng middleware

---

## 2️⃣ Test Route (Thực tế)

### Test qua HTTP request:

```bash
# Test cơ bản
curl http://your-domain/api/v1/test/middleware-check

# Test với headers
curl -v http://your-domain/api/v1/test/middleware-check

# Test TrimStrings (gửi input có spaces)
curl "http://your-domain/api/v1/test/middleware-check?test=  hello  world  "

# Test với X-Forwarded-For (TrustProxies)
curl -H "X-Forwarded-For: 192.168.1.100" http://your-domain/api/v1/test/middleware-check
```

### Hoặc mở trong browser:

```
http://your-domain/api/v1/test/middleware-check
```

### Response sẽ trả về:

```json
{
  "timestamp": "2024-01-01T12:00:00+00:00",
  "middleware_status": "active",
  "checks": {
    "security_headers": {
      "status": "check_response_headers",
      "note": "Kiểm tra response headers..."
    },
    "trust_proxies": {
      "status": "active",
      "client_ip": "127.0.0.1",
      "real_ip": "192.168.1.100"
    },
    "trim_strings": {
      "status": "active",
      "test_input": "hello world"
    },
    ...
  }
}
```

---

## 3️⃣ Manual Check (Từng Middleware)

### 3.1. SecurityHeaders ✅

**Cách test:**
```bash
curl -I http://your-domain/api/v1/test/middleware-check
```

**Kiểm tra headers:**
- ✅ `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- ✅ `Content-Security-Policy: default-src 'self'; ...`
- ✅ `X-Frame-Options: SAMEORIGIN`
- ✅ `X-Content-Type-Options: nosniff`
- ✅ `Referrer-Policy: strict-origin-when-cross-origin`

**Hoặc trong browser:**
- Mở DevTools > Network tab
- Click vào request
- Xem Response Headers

---

### 3.2. TrustProxies ✅

**Cách test:**
```bash
# Gửi request với X-Forwarded-For
curl -H "X-Forwarded-For: 192.168.1.100" \
     http://your-domain/api/v1/test/middleware-check
```

**Kiểm tra:**
- Response `client_ip` phải là `192.168.1.100` (real IP)
- Không phải IP của proxy

---

### 3.3. TrimStrings ✅

**Cách test:**
```bash
# Gửi input có spaces
curl "http://your-domain/api/v1/test/middleware-check?test=  hello  world  "
```

**Kiểm tra:**
- Response `test_input` phải là `"hello world"` (đã trim)
- Không còn spaces ở đầu/cuối

---

### 3.4. EncryptCookies ✅

**Cách test:**
```bash
# Set cookie và xem response
curl -c cookies.txt -b cookies.txt \
     http://your-domain/api/v1/test/middleware-check
```

**Kiểm tra:**
- Cookies trong request phải được decrypt
- Cookies trong response phải được encrypt

---

### 3.5. StartSession ✅

**Cách test:**
```bash
curl -c cookies.txt -b cookies.txt \
     http://your-domain/api/v1/test/middleware-check
```

**Kiểm tra:**
- Response có `session_id`
- Session được tạo và lưu

---

### 3.6. TrustHosts ✅

**Cách test:**
```bash
# Test với host khác (sẽ bị reject)
curl -H "Host: evil.com" \
     http://your-domain/api/v1/test/middleware-check
```

**Kiểm tra:**
- Request với host không được trust sẽ bị reject
- Chỉ accept host đã config

---

### 3.7. ValidateSignature ✅

**Cách test:**
```php
// Tạo signed URL
$url = URL::signedRoute('kernel.api.v1.test.middleware-check');

// Test URL này
curl $url
```

**Kiểm tra:**
- Signed URL hoạt động
- URL không có signature sẽ bị reject

---

### 3.8. VerifyCsrfToken ✅

**Cách test:**
```bash
# API routes đã được exclude, nên không cần CSRF token
curl -X POST http://your-domain/api/v1/test/middleware-check
```

**Kiểm tra:**
- API routes không cần CSRF token
- Không bị lỗi 419 (CSRF token mismatch)

**Note:** Nếu muốn test CSRF, dùng web routes thay vì API routes.

---

## 🔍 Debug Tips

### 1. Xem middleware stack trong Laravel:

```php
// Trong tinker hoặc controller
Route::getRoutes()->getMiddlewareGroups()['api']
```

### 2. Log middleware execution:

Thêm vào middleware để log:

```php
public function handle($request, Closure $next)
{
    \Log::info('Middleware executed: ' . get_class($this));
    return $next($request);
}
```

### 3. Xem response headers:

```bash
# -v để xem verbose (headers)
curl -v http://your-domain/api/v1/test/middleware-check

# -I để chỉ xem headers
curl -I http://your-domain/api/v1/test/middleware-check
```

### 4. Test với Postman:

1. Import collection
2. Gửi request đến `/api/v1/test/middleware-check`
3. Xem Response Headers tab
4. Xem Response Body để check middleware status

---

## ✅ Checklist

- [ ] Chạy `php artisan kernel:check-middleware --group=api`
- [ ] Test route `/api/v1/test/middleware-check`
- [ ] Kiểm tra SecurityHeaders trong response headers
- [ ] Test TrustProxies với X-Forwarded-For
- [ ] Test TrimStrings với input có spaces
- [ ] Verify API routes không cần CSRF token
- [ ] Check session được tạo

---

## 🐛 Troubleshooting

### Middleware không chạy?

1. **Clear cache:**
   ```bash
   php artisan config:clear
   php artisan route:clear
   php artisan cache:clear
   ```

2. **Check service provider:**
   - Đảm bảo `KernelServiceProvider` đã được register
   - Check `config/app.php` providers array

3. **Check route middleware:**
   - Đảm bảo route dùng middleware group `api`
   - Check route definition

### SecurityHeaders không xuất hiện?

- Check middleware có được push vào group không
- Check response có được return đúng không
- Check middleware có throw exception không

### TrustProxies không hoạt động?

- Check `$proxies` config trong middleware
- Check server có set X-Forwarded-For không
- Check middleware có được chạy trước các middleware khác không

---

## 📚 References

- [Laravel Middleware Documentation](https://laravel.com/docs/middleware)
- [Security Headers Guide](https://securityheaders.com/)
- [Trust Proxies Guide](https://laravel.com/docs/requests#configuring-trusted-proxies)

