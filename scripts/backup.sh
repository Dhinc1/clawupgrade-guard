#!/usr/bin/env bash
# ClawUpgrade Guard - Config backup

set -euo pipefail

BACKUP_PATH="${1:-$HOME/.openclaw/openclaw.json.backup-$(date +%Y%m%d-%H%M%S)}"

cp "$HOME/.openclaw/openclaw.json" "$BACKUP_PATH"
echo "✅ Backup created: $BACKUP_PATH"

# Verify backup
diff "$HOME/.openclaw/openclaw.json" "$BACKUP_PATH" >/dev/null && \
  echo "✅ Backup verified" || {
  echo "❌ Backup verification failed"
  exit 1
}
