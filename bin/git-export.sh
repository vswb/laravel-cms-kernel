#!/bin/bash
# git-diff-zip.sh
# Usage: ./git-diff-zip.sh <from_commit> <to_commit>
# Output: diff-<from>-<to>.zip

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <from_commit> <to_commit>"
    exit 1
fi

FROM_COMMIT=$1
TO_COMMIT=$2
EXPORT_DIR="diff_export"
ZIP_FILE="diff-${FROM_COMMIT}-${TO_COMMIT}.zip"

# Tạo thư mục tạm
mkdir -p "$EXPORT_DIR"

# Lấy danh sách file thay đổi và xuất nội dung đúng version
git diff --name-only "$FROM_COMMIT" "$TO_COMMIT" | while read -r file; do
    mkdir -p "$EXPORT_DIR/$(dirname "$file")"
    git show "$TO_COMMIT:$file" > "$EXPORT_DIR/$file" 2>/dev/null || true
done

# Zip toàn bộ thư mục
(cd "$EXPORT_DIR" && zip -r "../$ZIP_FILE" .)

# Xóa thư mục tạm
rm -rf "$EXPORT_DIR"

echo "Created zip: $ZIP_FILE"
