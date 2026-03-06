<?php

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
                                // Skip if this is the license server itself or if it's a console request
                                if (LicenseRegistry::isLicenseServer() || app()->runningInConsole()) {
                                    return $next($request);
                                }

                                // Check once every 4 hours (active enough to catch changes but not spammy)
                                $cacheKey = 'kernel_license_heartbeat_check';
                                if (!Cache::has($cacheKey)) {
                                    try {
                                        $this->sendHeartbeat();
                                        Cache::put($cacheKey, true, Carbon::now()->addHours(4));
                                    } catch (\Exception $e) {
                                        // Fail silently to not disrupt the user's site
                                    }
                                }

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
