<?php

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
