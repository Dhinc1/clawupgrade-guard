#!/usr/bin/env bash
# ClawUpgrade Guard - Standalone upgrade script
# Can be run manually or by agent via exec

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_PATH="$HOME/.openclaw/openclaw.json.backup-${TIMESTAMP}"

echo "=== ClawUpgrade Guard ==="
echo "Starting upgrade protocol at $(date)"
echo ""

# Phase 1: Pre-flight
echo "=== Phase 1: Pre-Flight ==="
bash "${SCRIPT_DIR}/pre-flight.sh" || {
  echo "❌ Pre-flight checks failed. Fix issues before upgrading."
  exit 1
}

# Phase 2: Backup
echo ""
echo "=== Phase 2: Backup ==="
bash "${SCRIPT_DIR}/backup.sh" "$BACKUP_PATH"

# Phase 3: Upgrade
echo ""
echo "=== Phase 3: Upgrade ==="
echo "Installing latest OpenClaw..."
npm install -g openclaw@latest
NEW_VERSION=$(openclaw --version)
echo "Upgraded to: $NEW_VERSION"

# Phase 4: Migrate
echo ""
echo "=== Phase 4: Migrate ==="
echo "Running openclaw doctor --fix (schema migration)..."
openclaw doctor --fix

# Phase 5: Validate
echo ""
echo "=== Phase 5: Validate ==="
bash "${SCRIPT_DIR}/validate.sh" "$BACKUP_PATH" || {
  echo "❌ Validation failed. Consider rollback."
  exit 1
}

# Phase 6: Gateway restart
echo ""
echo "=== Phase 6: Gateway Restart ==="
echo "Restarting gateway..."
pkill -f openclaw-gateway || true
sleep 5
openclaw gateway start
sleep 10

# Phase 7: Test
echo ""
echo "=== Phase 7: Test ==="
openclaw status | head -20

echo ""
echo "✅ ClawUpgrade Guard complete!"
echo "Backup saved: $BACKUP_PATH"
echo "New version: $NEW_VERSION"
