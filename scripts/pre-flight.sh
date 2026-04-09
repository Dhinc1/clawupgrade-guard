#!/usr/bin/env bash
# ClawUpgrade Guard - Pre-flight checks

set -euo pipefail

echo "Current version:"
openclaw --version

echo ""
echo "Gateway health:"
openclaw status 2>&1 | grep -A 5 "Gateway" || {
  echo "⚠️  Gateway not responding"
  exit 1
}

echo ""
echo "Config validation:"
openclaw config validate || {
  echo "❌ Config has errors. Fix before upgrading."
  exit 1
}

echo ""
echo "✅ Pre-flight checks passed"
