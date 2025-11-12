#!/bin/bash
# bash gitlab-query.sh "abc"

AUTHOR="$1"

git log --all \
  --author="$AUTHOR" \
  --since="2025-06-01T00:00:00" \
  --until="2025-06-30T23:59:59" \
  --pretty=format:"%ad|%h|%s" \
  --date=format:"%Y-%m-%d %H:%M:%S" | \
awk -F'|' '
{
  split($1, dt, " ");
  date = dt[1];
  time = dt[2];
  split(time, parts, ":");
  hour = parts[1] + 0;
  min = parts[2] + 0;

  if (hour < 8 || hour > 17 || (hour == 17 && min > 30)) {
    printf "📅 %s 🕒 %02d:%02d | 🔗 %s | %s\n", date, hour, min, $2, $3;
  }
}'
