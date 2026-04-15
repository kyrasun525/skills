#!/usr/bin/env bash
set -euo pipefail

QUERY="${1:-}"
METHOD="${2:-}"
ROOT="${3:-.}"

if [[ -z "$QUERY" ]]; then
  echo 'Usage: bash scripts/locate_issue.sh "<api clue>" "<optional method>" "<optional root>"'
  exit 1
fi

COMMON_EXCLUDES=(
  --glob '!vendor/**'
  --glob '!node_modules/**'
  --glob '!.git/**'
  --glob '!__pycache__/**'
  --glob '!venv/**'
)

ROUTE_PATTERN="${QUERY}"
METHOD_LOWER="$(printf '%s' "$METHOD" | tr '[:upper:]' '[:lower:]')"

echo '=== Route and Entry Search ==='
echo "Query: $QUERY"
if [[ -n "$METHOD" ]]; then
  echo "Method: $METHOD"
fi

echo
echo '--- Direct Path or Name Matches ---'
rg -n -i \
  -e "$ROUTE_PATTERN" \
  -e '@RequestMapping|@GetMapping|@PostMapping|@PutMapping|@DeleteMapping|@PatchMapping' \
  -e 'Route::(get|post|put|delete|any|resource|rule|group)' \
  -e '@Controller|@Get\(|@Post\(|@Put\(|@Delete\(' \
  -e 'router\.(get|post|put|delete)|app\.(get|post|put|delete)' \
  -e 'urls\.py|path\(|re_path\(|router\.register|APIView|ViewSet|@app\.route|Blueprint|APIRouter|Depends|@router\.(get|post|put|delete)|@app\.(get|post|put|delete)' \
  "$ROOT" "${COMMON_EXCLUDES[@]}" 2>/dev/null || true

if [[ -n "$METHOD_LOWER" ]]; then
  echo
  echo '--- Method-Focused Matches ---'
  case "$METHOD_LOWER" in
    get)
      rg -n -i -e '@GetMapping|Route::get|@Get\(|router\.get|app\.get|@router\.get|@app\.get|path\(' "$ROOT" "${COMMON_EXCLUDES[@]}" 2>/dev/null || true
      ;;
    post)
      rg -n -i -e '@PostMapping|Route::post|@Post\(|router\.post|app\.post|@router\.post|@app\.post|path\(' "$ROOT" "${COMMON_EXCLUDES[@]}" 2>/dev/null || true
      ;;
    put)
      rg -n -i -e '@PutMapping|Route::put|@Put\(|router\.put|app\.put|@router\.put|@app\.put|path\(' "$ROOT" "${COMMON_EXCLUDES[@]}" 2>/dev/null || true
      ;;
    delete)
      rg -n -i -e '@DeleteMapping|Route::delete|@Delete\(|router\.delete|app\.delete|@router\.delete|@app\.delete|path\(' "$ROOT" "${COMMON_EXCLUDES[@]}" 2>/dev/null || true
      ;;
    patch)
      rg -n -i -e '@PatchMapping|router\.patch|app\.patch|@router\.patch|@app\.patch|Route::patch|path\(' "$ROOT" "${COMMON_EXCLUDES[@]}" 2>/dev/null || true
      ;;
  esac
fi

echo
echo '--- Python-Focused Search Keywords ---'
rg -n -i \
  -e 'urls\.py' \
  -e 'path\(' \
  -e 'APIView' \
  -e 'ViewSet' \
  -e '@app\.route' \
  -e 'Blueprint' \
  -e 'APIRouter' \
  -e 'Depends' \
  -e 'request\.args' \
  -e 'request\.json' \
  -e 'BaseModel' \
  -e 'settings\.py' \
  "$ROOT" "${COMMON_EXCLUDES[@]}" 2>/dev/null || true
