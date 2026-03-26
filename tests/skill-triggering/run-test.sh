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
LOG_FILE="$OUTPUT_DIR/codex-output.json"
TMP_HOME="$(mktemp -d)"

echo "=== Skill Triggering Test ==="
echo "Skill: $SKILL_NAME"
echo "Prompt file: $PROMPT_FILE"
echo "Max turns: $MAX_TURNS"
echo "Output dir: $OUTPUT_DIR"
echo ""

cd "$OUTPUT_DIR"

if ! command -v codex >/dev/null 2>&1; then
  echo "❌ FAIL: codex command not found"
  exit 1
fi

echo "Running codex exec with naive prompt..."

TIMEOUT_CMD=()
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_CMD=(timeout 300)
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_CMD=(gtimeout 300)
fi

CODEX_ENV=(HOME="$TMP_HOME" CODEX_HOME="/Users/zhaoyanlong/.codex")

if [ "${#TIMEOUT_CMD[@]}" -gt 0 ]; then
  env "${CODEX_ENV[@]}" "${TIMEOUT_CMD[@]}" codex exec \
    --json \
    --ephemeral \
    --dangerously-bypass-approvals-and-sandbox \
    -C "$REPO_ROOT" \
    "$PROMPT" \
    > "$LOG_FILE" 2>&1 || true
else
  env "${CODEX_ENV[@]}" codex exec \
    --json \
    --ephemeral \
    --dangerously-bypass-approvals-and-sandbox \
    -C "$REPO_ROOT" \
    "$PROMPT" \
    > "$LOG_FILE" 2>&1 || true
fi

echo ""
echo "=== Results ==="

if ! grep -q '^{"type"' "$LOG_FILE"; then
  echo "❌ FAIL: No JSON events were produced"
  echo ""
  echo "Full log: $LOG_FILE"
  echo "Timestamp: $TIMESTAMP"
  exit 1
fi

FINAL_MESSAGE="$(
  grep '^{"type"' "$LOG_FILE" \
    | jq -r 'select(.type == "item.completed" and .item.type == "agent_message") | .item.text' \
    | tail -n 1
)"

case "$SKILL_NAME" in
  my-recipe-shopping-list)
    EXPECTED_1='几人份|多少人|几个人'
    EXPECTED_2=''
    ;;
  my-recipe-inventory)
    EXPECTED_1='还差|缺|剩余'
    EXPECTED_2='清单|已勾选|已备'
    ;;
  my-recipe-equipment)
    EXPECTED_1='换算|比例|系数'
    EXPECTED_2='模具|容器|尺寸'
    ;;
  my-recipe-multidish)
    EXPECTED_1='时间轴|顺序|先后'
    EXPECTED_2='一起上桌|同步出锅|别让菜先凉'
    ;;
  my-recipe-rescue)
    EXPECTED_1='太咸|锅底糊|不要刮锅底'
    EXPECTED_2='救|稀释|吸味|补救'
    ;;
  *)
    EXPECTED_1='.'
    EXPECTED_2='.'
    ;;
esac

MATCH_ONE=true
MATCH_TWO=true

if ! printf '%s\n' "$FINAL_MESSAGE" | grep -Eq "$EXPECTED_1"; then
  MATCH_ONE=false
fi

if [ -n "$EXPECTED_2" ] && ! printf '%s\n' "$FINAL_MESSAGE" | grep -Eq "$EXPECTED_2"; then
  MATCH_TWO=false
fi

if [ "$MATCH_ONE" = true ] && [ "$MATCH_TWO" = true ]; then
  echo "✅ PASS: Output matched expected behavior for '$SKILL_NAME'"
  TRIGGERED=true
else
  echo "❌ FAIL: Output did not match expected behavior for '$SKILL_NAME'"
  TRIGGERED=false
fi

echo ""
echo "Final assistant message:"
printf '%s\n' "$FINAL_MESSAGE"

echo ""
echo "Full log: $LOG_FILE"
echo "Timestamp: $TIMESTAMP"

if [ "$TRIGGERED" = "true" ]; then
  exit 0
fi

exit 1
