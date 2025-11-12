<?php 
// app/Console/Commands/SetupGitHookCommand.php

namespace Platform\Kernel\Commands;

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
