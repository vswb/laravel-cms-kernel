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


namespace Dev\Kernel\Traits;

use Illuminate\Support\Facades\Log;

trait Benchmarkable
{
    private array $benchmarks = [];

    public function benchmark(string $label, callable $callback, ?string $channel = null, string $level = 'info'): mixed
    {
        $start = microtime(true);
        $result = $callback();
        $duration = round((microtime(true) - $start) * 1000, 2); // ms

        // Chuẩn hoá log: luôn 1 dòng, đẹp, có JSON context ngay trong message
        $log = "├── [BENCH] {$label}: {$duration} ms " . json_encode([
            'label' => $label,
            'duration_ms' => $duration,
        ]);

        // $logger = property_exists($this, 'logger') ? $this->logger : null;
        // $channelToUse = $channel ?? $logger ?? 'daily';
        // Log::channel($channelToUse)->{$level}($log);

        $this->benchmarks[] = $log; // trả log ra và lưu một lần sau khi flush

        return $result;
    }

    public function flushBenchmarks(?string $channel = null, string $level = 'debug'): void
    {
        $logger = property_exists($this, 'logger') ? $this->logger : null;
        $channelToUse = $channel ?? $logger ?? 'daily';

        foreach ($this->benchmarks as $log) {
            Log::channel($channelToUse)->{$level}($log);
        }

        $this->benchmarks = [];
    }
}
