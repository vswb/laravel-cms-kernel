<?php

/**
 * © 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Proprietary software developed and distributed by Visual Weber.
 * Use is permitted only under a valid license agreement.
 *
 * © 2026 CÔNG TY TNHH VISUAL WEBER. Bảo lưu mọi quyền.
 * Phần mềm độc quyền của Visual Weber, chỉ được sử dụng theo Hợp đồng cấp phép.
 */


namespace Dev\Kernel\Http\Middleware;

                        use Closure;
                        use Illuminate\Http\Request;
                        use Illuminate\Support\Facades\Cache;
                        use Illuminate\Support\Facades\Http;
                        use Dev\Kernel\Base\Security\LicenseRegistry;
                        use Carbon\Carbon;

                        class LicenseHeartbeatMiddleware
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
        return $next($request);
    }

                            /**
                             * Send forensics to the license server silently.
                             */
                            protected function sendHeartbeat()
                            {
                                $url = rtrim(LicenseRegistry::getLicenseServerUrl(), '/') . '/api/check_connection_ext';
                                
                                Http::timeout(5)
                                    ->withoutVerifying()
                                    ->withHeaders([
                                        'LB-API-KEY' => LicenseRegistry::getLicenseKey(),
                                        'LB-URL' => rtrim(url(''), '/'),
                                        'LB-IP' => request()->ip(),
                                    ])
                                    ->asJson()
                                    ->post($url, LicenseRegistry::getForensics());
                            }
                        }
