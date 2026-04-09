#!/usr/bin/env bash
# ClawUpgrade Guard - Rollback to backup

set -euo pipefail

BACKUP_PATH="$1"

if [[ ! -f "$BACKUP_PATH" ]]; then
  echo "❌ Backup not found: $BACKUP_PATH"
  exit 1
fi

echo "⚠️  Rolling back to: $BACKUP_PATH"
cp "$BACKUP_PATH" "$HOME/.openclaw/openclaw.json"

echo "Validating restored config..."
openclaw config validate

echo "✅ Rollback complete. Restart gateway with: openclaw gateway start"
