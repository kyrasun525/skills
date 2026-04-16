#!/usr/bin/env bash
set -euo pipefail

API_CLUE="${1:-}"
METHOD="${2:-}"
SYMPTOM="${3:-}"
ROOT="${4:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "$API_CLUE" ]]; then
  echo 'Usage: bash scripts/inspect_api.sh "<api clue>" "<optional method>" "<optional symptom>" "<optional root>"'
  exit 1
fi

echo '=== API Inspection Summary ==='
echo "API clue: $API_CLUE"
if [[ -n "$METHOD" ]]; then
  echo "Method: $METHOD"
fi
if [[ -n "$SYMPTOM" ]]; then
  echo "Symptom: $SYMPTOM"
fi

echo
echo '## Log Evidence'
bash "$SCRIPT_DIR/read_logs.sh" "$ROOT" "$SYMPTOM"

echo
echo '## Entry Candidates'
bash "$SCRIPT_DIR/locate_issue.sh" "$API_CLUE" "$METHOD" "$ROOT"

echo
echo '## Call-Chain Candidates'
bash "$SCRIPT_DIR/trace_callchain.sh" "$API_CLUE" "$ROOT"

echo
echo '## Summary Guidance'
echo '- Use the log evidence to confirm whether the issue is route rejection, validation, permission, service failure, dependency timeout, or configuration related.'
echo '- Use the entry candidates to identify the most likely route/controller/view.'
echo '- Use the call-chain candidates to connect handler -> service -> model/repository/client.'
echo '- Produce Top 1 to Top 3 likely causes with code locations, reasoning, confidence, and read-only verification steps.'
