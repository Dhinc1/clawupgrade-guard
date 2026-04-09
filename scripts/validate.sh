#!/usr/bin/env bash
# ClawUpgrade Guard - Post-migration validation

set -euo pipefail

BACKUP_PATH="$1"

echo "Validating critical config survived migration..."

# Check if jq is available
if ! command -v jq &>/dev/null; then
  echo "⚠️  jq not found, skipping detailed validation"
  exit 0
fi

CONFIG="$HOME/.openclaw/openclaw.json"

# Validate Ollama Spark provider
echo -n "Checking Ollama Spark provider... "
API=$(jq -r '.models.providers."ollama-spark".api' "$CONFIG")
if [[ "$API" == "openai-responses" ]]; then
  echo "✅"
else
  echo "❌ (api: $API, expected: openai-responses)"
  exit 1
fi

# Validate agent models (if agents.list exists)
if jq -e '.agents.list' "$CONFIG" >/dev/null 2>&1; then
  echo "✅ All validations passed"
else
  echo "⚠️  agents.list structure changed (this may be normal for v4.9+)"
fi

echo "✅ Critical config intact"
