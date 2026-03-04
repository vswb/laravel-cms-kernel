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
 
// app/Console/Commands/SetupGitHookCommand.php

namespace Dev\Kernel\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;

class SetupGitHookCommand extends Command
{
    protected $signature = 'git:install-commit-hook';
    protected $description = 'Install Git commit-msg hook to enforce commit message standards';

    public function handle(): int
    {
        $hookPath = base_path('.git/hooks/commit-msg');
        $script = <<<EOT
#!/bin/sh

commit_msg_file="\$1"
commit_msg=\$(cat "\$commit_msg_file")

if ! echo "\$commit_msg" | grep -q '{OP#[0-9]\\+}'; then
  echo "❌ Commit message must include a task ID in the format {OP#123}"
  exit 1
fi

msg_length=\$(echo "\$commit_msg" | wc -m)
if [ "\$msg_length" -lt 10 ]; then
  echo "❌ Commit message is too short (less than 10 characters)"
  exit 1
fi
EOT;

        if (!File::exists(base_path('.git/hooks'))) {
            $this->error("Git hooks directory does not exist. Is this a Git project?");
            return self::FAILURE;
        }

        File::put($hookPath, $script);
        chmod($hookPath, 0755);

        $this->info("✅ commit-msg hook installed successfully.");
        return self::SUCCESS;
    }
}
