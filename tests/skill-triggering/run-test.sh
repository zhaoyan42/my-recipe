#!/usr/bin/env bash

# Test a leaf skill with a natural-language prompt.
# Usage: ./run-test.sh <skill-name> <prompt-file> [max-turns]

set -euo pipefail

SKILL_NAME="${1:-}"
PROMPT_FILE="${2:-}"
MAX_TURNS="${3:-3}"

if [ -z "$SKILL_NAME" ] || [ -z "$PROMPT_FILE" ]; then
  echo "Usage: $0 <skill-name> <prompt-file> [max-turns]"
  echo "Example: $0 my-recipe-shopping-list ./prompts/my-recipe-shopping-list.txt"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date +%s)"
OUTPUT_DIR="/tmp/my-recipe-tests/${TIMESTAMP}/skill-triggering/${SKILL_NAME}"

mkdir -p "$OUTPUT_DIR"
cp "$PROMPT_FILE" "$OUTPUT_DIR/prompt.txt"

PROMPT="$(cat "$PROMPT_FILE")"
LOG_FILE="$OUTPUT_DIR/claude-output.json"

echo "=== Skill Triggering Test ==="
echo "Skill: $SKILL_NAME"
echo "Prompt file: $PROMPT_FILE"
echo "Max turns: $MAX_TURNS"
echo "Output dir: $OUTPUT_DIR"
echo ""

cd "$OUTPUT_DIR"

if ! command -v claude >/dev/null 2>&1; then
  echo "❌ FAIL: claude command not found"
  exit 1
fi

echo "Running claude -p with naive prompt..."

TIMEOUT_CMD=()
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_CMD=(timeout 300)
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_CMD=(gtimeout 300)
fi

if [ "${#TIMEOUT_CMD[@]}" -gt 0 ]; then
  "${TIMEOUT_CMD[@]}" claude -p "$PROMPT" \
    --plugin-dir "$REPO_ROOT" \
    --dangerously-skip-permissions \
    --no-session-persistence \
    --max-turns "$MAX_TURNS" \
    --verbose \
    --output-format stream-json \
    > "$LOG_FILE" 2>&1 || true
else
  claude -p "$PROMPT" \
    --plugin-dir "$REPO_ROOT" \
    --dangerously-skip-permissions \
    --no-session-persistence \
    --max-turns "$MAX_TURNS" \
    --verbose \
    --output-format stream-json \
    > "$LOG_FILE" 2>&1 || true
fi

echo ""
echo "=== Results ==="

SKILL_PATTERN='"skill":"([^"]*:)?'"${SKILL_NAME}"'"'
if grep -q '"name":"Skill"' "$LOG_FILE" && grep -qE "$SKILL_PATTERN" "$LOG_FILE"; then
  echo "✅ PASS: Skill '$SKILL_NAME' was triggered"
  TRIGGERED=true
else
  echo "❌ FAIL: Skill '$SKILL_NAME' was NOT triggered"
  TRIGGERED=false
fi

echo ""
echo "Skills triggered in this run:"
grep -o '"skill":"[^"]*"' "$LOG_FILE" 2>/dev/null | sort -u || echo " (none)"

echo ""
echo "Full log: $LOG_FILE"
echo "Timestamp: $TIMESTAMP"

if [ "$TRIGGERED" = "true" ]; then
  exit 0
fi

exit 1
