<?php

namespace Dev\Kernel\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class SecurityHeaders
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        $response = $next($request);

        /*
        |--------------------------------------------------------------------------
        | Strict-Transport-Security (HSTS)
        |--------------------------------------------------------------------------
        | Bắt buộc trình duyệt chỉ dùng HTTPS trong 1 năm (31536000 giây).
        | includeSubDomains: áp dụng cho toàn bộ subdomain.
        | preload: để có thể submit vào danh sách preload của Chrome.
        */
        $response->headers->set(
            'Strict-Transport-Security',
            'max-age=31536000; includeSubDomains; preload'
        );

        /*
        |--------------------------------------------------------------------------
        | Content-Security-Policy (CSP)
        |--------------------------------------------------------------------------
        | Bạn có thể tùy chỉnh whitelist tuỳ project.
        | Đây là CSP ở mức an toàn mạnh nhưng vẫn không phá CSS inline.
        */
        $response->headers->set(
            'Content-Security-Policy',
            "default-src 'self'; " .
            "img-src 'self' data: https:; " .
            "script-src 'self'; " .
            "style-src 'self' 'unsafe-inline';"
        );

        /*
        |--------------------------------------------------------------------------
        | Permissions-Policy
        |--------------------------------------------------------------------------
        | Giới hạn các API nguy hiểm.
        */
        $response->headers->set(
            'Permissions-Policy',
            'camera=(), microphone=(), geolocation=(), payment=(), usb=()'
        );

        /*
        |--------------------------------------------------------------------------
        | X-Content-Type-Options
        |--------------------------------------------------------------------------
        | Chống trình duyệt tự đoán định dạng file.
        */
        $response->headers->set('X-Content-Type-Options', 'nosniff');

        /*
        |--------------------------------------------------------------------------
        | X-Frame-Options
        |--------------------------------------------------------------------------
        | Chống clickjacking (nhúng website vào iframe).
        */
        $response->headers->set('X-Frame-Options', 'SAMEORIGIN');

        /*
        |--------------------------------------------------------------------------
        | Referrer-Policy
        |--------------------------------------------------------------------------
        | Hạn chế rò rỉ thông tin referrer.
        */
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');

        return $response;
    }
}
