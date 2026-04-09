# ClawUpgrade Guard - Agent Workflow Example

## Scenario
User asks: "Upgrade OpenClaw to the latest version"

## Agent Workflow

### 1. Agent Reads SKILL.md
```
[Agent loads claw_upgrade_guard/SKILL.md]
[Recognizes trigger: "upgrade openclaw"]
[Begins Phase 1]
```

### 2. Phase 1: Pre-Flight
```
Agent: "Starting upgrade pre-flight checks..."

[Runs:]
openclaw --version          → 2026.4.8
openclaw doctor             → Gateway healthy
openclaw config validate    → ✓ Config valid

Agent: "Current version: 2026.4.8. Gateway healthy. Config valid. Ready to upgrade."
```

### 3. Phase 2: Backup
```
Agent: "Creating config backup..."

[Creates:]
~/.openclaw/openclaw.json.backup-20260409-073000

Agent: "Backup created: openclaw.json.backup-20260409-073000"
```

### 4. Phase 3: Upgrade
```
Agent: "Installing latest OpenClaw via npm..."

[Runs:]
npm install -g openclaw@latest

Agent: "Upgraded to OpenClaw 2026.4.9"
```

### 5: Phase 4: Migrate
```
Agent: "Running schema migration via openclaw doctor --fix..."

[Doctor output shows:]
- Removed stale plugin: capability
- Fixed permissions: 644 → 600
- Archived 2 orphan transcripts

Agent: "Doctor applied 33 config changes. Checking what survived..."
```

### 6. Phase 5: Validate
```
Agent: "Validating critical config..."

[Checks:]
✓ Ollama Spark provider: api=openai-responses
✓ Scout model: ollama-spark/gemma4:26b
✓ Morgan model: ollama-spark/deepseek-r1:7b
✗ PARA paths: missing (doctor stripped them)

Agent: "PARA paths were stripped by doctor. Restoring from backup..."

[Restores extraPaths from backup, re-applies legitimate migrations]

Agent: "PARA paths restored. All critical config intact."
```

### 7. Phase 6: Gateway Restart
```
Agent: "Restarting gateway..."

[Runs:]
kill <PID>
sleep 5
openclaw gateway start

Agent: "Gateway restarted on v4.9"
```

### 8. Phase 7: Test
```
Agent: "Running post-upgrade tests..."

[Tests:]
openclaw ask "What version are you running?" → 2026.4.9 ✓
openclaw cron list → 9 jobs intact ✓
openclaw status → Memory: 132 files, 4019 chunks ✓

Agent: "All tests passed."
```

### 9. Phase 8: Summarize
```
Agent: "Upgrade complete. Summary:

**Version:** 2026.4.8 → 2026.4.9
**Time:** 3 minutes
**Changes:** 
  - Removed stale capability plugin
  - Fixed config permissions (644 → 600)
  - Archived 2 orphan transcripts
  - PARA paths restored (doctor had stripped them)

**Status:** All systems healthy. Backup saved at openclaw.json.backup-20260409-073000

**New v4.9 features:**
  - Enhanced security audit
  - Better session lock detection
  - Plugin compatibility checking
  
Let me know if you'd like to enable any new features."
```

## Key Differences from Manual Upgrade

| Manual | ClawUpgrade Guard (Agent) |
|--------|---------------------------|
| User remembers to backup | Agent always backs up first |
| User runs `doctor --fix` blindly | Agent interprets changes, validates survival |
| User manually checks config | Agent validates critical paths automatically |
| User reads logs to debug | Agent explains what broke and fixes it |
| No memory of what changed | Agent logs full summary to memory |

## Recovery Example

If Phase 5 validation fails completely:

```
Agent: "❌ Critical config corrupted after migration. Rolling back..."

[Runs:]
cp ~/.openclaw/openclaw.json.backup-20260409-073000 ~/.openclaw/openclaw.json
openclaw config validate

Agent: "Rollback complete. System restored to v2026.4.8. 

Issue detected: Doctor stripped PARA paths + agent model assignments.

Recommendation: Report this to OpenClaw team, wait for fixed migration, or manually reapply config after upgrade."
```
