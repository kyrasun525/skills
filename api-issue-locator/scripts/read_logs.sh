#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
KEYWORD="${2:-}"

FIND_EXCLUDES=(
  -not -path '*/vendor/*'
  -not -path '*/node_modules/*'
  -not -path '*/.git/*'
  -not -path '*/__pycache__/*'
  -not -path '*/venv/*'
)

RG_EXCLUDES=(
  --glob '!vendor/**'
  --glob '!node_modules/**'
  --glob '!.git/**'
  --glob '!__pycache__/**'
  --glob '!venv/**'
)

PATTERN='error|exception|timeout|null|traceback|fatal|failed|denied|unauthorized|forbidden|not found'
if [[ -n "$KEYWORD" ]]; then
  PATTERN="$PATTERN|$KEYWORD"
fi

LOG_FILES=()
while IFS= read -r line; do
  [[ -n "$line" ]] && LOG_FILES+=("$line")
done < <(
  find "$ROOT" \( -type d \( -name logs -o -path '*/storage/logs' -o -name runtime \) -o -type f -name '*.log' \) \
    "${FIND_EXCLUDES[@]}" 2>/dev/null | sort -u
)

if [[ ${#LOG_FILES[@]} -eq 0 ]]; then
  echo 'No log files or log directories found.'
  exit 0
fi

echo '=== Log Search Targets ==='
printf '%s\n' "${LOG_FILES[@]}"

echo
echo '=== Matched Log Evidence ==='
FOUND=0
for target in "${LOG_FILES[@]}"; do
  if [[ -d "$target" ]]; then
    rg -n -i -C 2 "$PATTERN" "$target" "${RG_EXCLUDES[@]}" 2>/dev/null || true
    if rg -q -i "$PATTERN" "$target" "${RG_EXCLUDES[@]}" 2>/dev/null; then
      FOUND=1
    fi
  elif [[ -f "$target" ]]; then
    rg -n -i -C 2 "$PATTERN" "$target" 2>/dev/null || true
    if rg -q -i "$PATTERN" "$target" 2>/dev/null; then
      FOUND=1
    fi
  fi
done

if [[ "$FOUND" -eq 0 ]]; then
  echo 'No direct log evidence matched the target patterns.'
fi
