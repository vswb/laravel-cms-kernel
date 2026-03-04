<?php
/**
 * (c) Copyright 2026 VISUAL WEBER COMPANY LIMITED. All rights reserved.
 * Distributed by: VISUAL WEBER CO., LTD.
 * * [PRODUCT INFORMATION]
 * This software is a proprietary product developed by Visual Weber.
 * All rights to the software and its components are reserved under 
 * Intellectual Property laws.
 * * [TERMS OF USE]
 * Usage is permitted strictly according to the License Agreement 
 * between Visual Weber and the Client.
 * -------------------------------------------------------------------------
 * (c) Bản quyền thuộc về CÔNG TY TNHH VISUAL WEBER 2026. Bảo lưu mọi quyền.
 * Phát hành bởi: Công ty TNHH Visual Weber.
 * * [THÔNG TIN SẢN PHẨM]
 * Phần mềm này là sản phẩm độc quyền được phát triển bởi Visual Weber.
 * Mọi quyền đối với phần mềm và các thành phần cấu thành đều được bảo hộ 
 * theo luật Sở hữu trí tuệ.
 * * [ĐIỀU KHOẢN SỬ DỤNG]
 * Việc sử dụng được giới hạn nghiêm ngặt theo Hợp đồng cung cấp dịch vụ/phần mềm 
 * giữa Visual Weber và Khách hàng.
 */


namespace Dev\Kernel\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Route;
use Illuminate\Routing\Router;

class CheckMiddlewareCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'kernel:check-middleware 
                            {--group=api : Middleware group to check (api, web)}
                            {--list : List all middleware in the group}
                            {--detail : Show detailed information}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Check middleware configuration and status for API or Web group';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $group = $this->option('group');
        $list = $this->option('list');
        $detail = $this->option('detail');

        $this->info("🔍 Checking middleware for group: {$group}");
        $this->newLine();

        /** @var Router $router */
        $router = app('router');

        // Get middleware groups
        $middlewareGroups = $router->getMiddlewareGroups();

        if (!isset($middlewareGroups[$group])) {
            $this->error("❌ Middleware group '{$group}' not found!");
            $this->info("Available groups: " . implode(', ', array_keys($middlewareGroups)));
            return 1;
        }

        $middlewares = $middlewareGroups[$group];

        $this->info("✅ Found " . count($middlewares) . " middleware(s) in '{$group}' group:");
        $this->newLine();

        // Expected middleware from KernelServiceProvider
        $expectedMiddlewares = [
            'Dev\Kernel\Http\Middleware\TrustHosts',
            'Dev\Kernel\Http\Middleware\TrustProxies',
            'Dev\Kernel\Http\Middleware\EncryptCookies',
            'Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse',
            'Illuminate\Session\Middleware\StartSession',
            'Illuminate\View\Middleware\ShareErrorsFromSession',
            'Dev\Kernel\Http\Middleware\TrimStrings',
            'Dev\Kernel\Http\Middleware\ValidateSignature',
            'Dev\Kernel\Http\Middleware\VerifyCsrfToken',
            'Dev\Kernel\Http\Middleware\SecurityHeaders',
        ];

        $table = [];
        foreach ($middlewares as $index => $middleware) {
            $class = is_string($middleware) ? $middleware : get_class($middleware);
            $isExpected = in_array($class, $expectedMiddlewares);
            $status = $isExpected ? '✅' : '⚠️';

            $table[] = [
                $index + 1,
                $status,
                $class,
                $isExpected ? 'Expected' : 'Other',
            ];
        }

        $this->table(
            ['#', 'Status', 'Middleware Class', 'Type'],
            $table
        );

        // Check if all expected middlewares are present
        $this->newLine();
        $this->info("📋 Expected Middleware Check:");

        $missing = [];
        foreach ($expectedMiddlewares as $expected) {
            $found = false;
            foreach ($middlewares as $middleware) {
                $class = is_string($middleware) ? $middleware : get_class($middleware);
                if ($class === $expected) {
                    $found = true;
                    break;
                }
            }

            if ($found) {
                $this->line("  ✅ {$expected}");
            } else {
                $this->line("  ❌ {$expected} - MISSING");
                $missing[] = $expected;
            }
        }

        if (!empty($missing)) {
            $this->newLine();
            $this->warn("⚠️  Missing " . count($missing) . " expected middleware(s):");
            foreach ($missing as $m) {
                $this->line("   - {$m}");
            }
        } else {
            $this->newLine();
            $this->info("✅ All expected middleware are present!");
        }

        // Show detail if requested
        if ($detail) {
            $this->newLine();
            $this->info("📝 Detailed Information:");
            $this->newLine();

            foreach ($expectedMiddlewares as $expected) {
                $this->line("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                $this->line("📦 {$expected}");

                // Check if class exists
                if (class_exists($expected)) {
                    $this->line("   ✅ Class exists");

                    // Get file path
                    $reflection = new \ReflectionClass($expected);
                    $this->line("   📁 File: " . $reflection->getFileName());

                    // Check if it's in the middleware list
                    $inList = false;
                    foreach ($middlewares as $middleware) {
                        $class = is_string($middleware) ? $middleware : get_class($middleware);
                        if ($class === $expected) {
                            $inList = true;
                            break;
                        }
                    }

                    if ($inList) {
                        $this->line("   ✅ Active in '{$group}' group");
                    } else {
                        $this->line("   ❌ NOT active in '{$group}' group");
                    }
                } else {
                    $this->line("   ❌ Class does not exist!");
                }
                $this->newLine();
            }
        }

        // Show test instructions
        $this->newLine();
        $this->info("🧪 How to Test:");
        $this->line("   1. Run: curl -v http://your-domain/api/v1/test/middleware-check");
        $this->line("   2. Check response headers for SecurityHeaders");
        $this->line("   3. Or visit: /api/v1/test/middleware-check in browser");
        $this->line("   4. Check browser DevTools > Network tab for headers");

        return 0;
    }
}

