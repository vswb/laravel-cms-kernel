#!/bin/bash

# tìm thư mục root của git repo (dù chạy từ đâu)
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ ! -d "$GIT_ROOT/.git/hooks" ]; then
  echo "❌ This script must be run within a Git repository."
  exit 1
fi

HOOK_FILE="$GIT_ROOT/.git/hooks/commit-msg"

# nội dung của commit-msg hook
cat > "$HOOK_FILE" <<'EOF'
#!/bin/sh

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# kiểm tra có chứa mã task dạng {OP#123}
if ! echo "$COMMIT_MSG" | grep -qE '\{OP#[0-9]+\}'; then
  echo "❌ Commit message must include a task ID in the format: {OP#123}"
  exit 1
fi

# lấy phần comment sau {OP#123}
COMMENT_BODY=$(echo "$COMMIT_MSG" | sed -E 's/.*\{OP#[0-9]+\}[[:space:]]*//')

# kiểm tra độ dài comment (trên 10 ký tự)
COMMENT_LENGTH=$(echo "$COMMENT_BODY" | wc -m)

if [ "$COMMENT_LENGTH" -le 10 ]; then
  echo "❌ Commit message must have a descriptive comment (more than 10 characters) after {OP#123}"
  exit 1
fi

exit 0
EOF

chmod +x "$HOOK_FILE"
echo "✅ Git commit-msg hook has been installed in: $HOOK_FILE"
