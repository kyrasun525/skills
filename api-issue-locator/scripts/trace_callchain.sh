#!/usr/bin/env bash
set -euo pipefail

QUERY="${1:-}"
ROOT="${2:-.}"

if [[ -z "$QUERY" ]]; then
  echo 'Usage: bash scripts/trace_callchain.sh "<symbol or handler clue>" "<optional root>"'
  exit 1
fi

EXCLUDES=(
  --glob '!vendor/**'
  --glob '!node_modules/**'
  --glob '!.git/**'
  --glob '!__pycache__/**'
  --glob '!venv/**'
)

SYM="$(printf '%s' "$QUERY" | sed 's#^.*/##; s#[^A-Za-z0-9_]# #g' | awk '{print $1}')"
if [[ -z "$SYM" ]]; then
  SYM="$QUERY"
fi

echo '=== Call Chain Candidates ==='
echo "Seed: $QUERY"

echo
echo '--- Entry Candidates ---'
rg -n -i \
  -e "$QUERY" \
  -e "$SYM" \
  -e '@RequestMapping|@GetMapping|@PostMapping|@PutMapping|@DeleteMapping|@PatchMapping' \
  -e 'Route::(get|post|put|delete|any|resource|rule|group)' \
  -e '@Controller|@Get\(|@Post\(|@Put\(|@Delete\(' \
  -e 'router\.(get|post|put|delete)|app\.(get|post|put|delete)' \
  -e 'path\(|APIView|ViewSet|@app\.route|Blueprint|APIRouter|Depends|@router\.(get|post|put|delete)|@app\.(get|post|put|delete)' \
  "$ROOT" "${EXCLUDES[@]}" 2>/dev/null || true

echo
echo '--- Controller or View to Service Hops ---'
rg -n -i \
  -e "$SYM" \
  -e 'service|Service|Repository|repository|Mapper|mapper|queryset|serializer|permission_classes|Depends|db\.session|SessionLocal|objects\.(filter|get|create)|SQLAlchemy' \
  "$ROOT" "${EXCLUDES[@]}" 2>/dev/null || true

echo
echo '--- Downstream Dependency Hops ---'
rg -n -i \
  -e 'Feign|RestTemplate|WebClient|HttpClient|axios|fetch\(|requests\.|httpx\.|grpc|redis|kafka|rabbit|celery|queryset|Repository|Model|ORM|SQLAlchemy|BaseModel|serializer' \
  -e "$SYM" \
  "$ROOT" "${EXCLUDES[@]}" 2>/dev/null || true
