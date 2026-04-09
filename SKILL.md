# ClawUpgrade Guard

**name:** claw_upgrade_guard  
**description:** "Agent-driven OpenClaw upgrades with pre-flight checks, migration validation, and rollback guidance. Install this skill and your agent can safely upgrade OpenClaw itself — with visibility, validation, and recovery built in. Use when: Dave asks to upgrade OpenClaw, when a new version is released, or when you see references to new OpenClaw releases."

---

**description:** "Manage OpenClaw version upgrades safely. Use this skill whenever Dave asks to upgrade OpenClaw, when a new version is released, or when you see references to new OpenClaw releases. Covers pre-flight checks, backup, upgrade execution, config migration, post-upgrade validation, feature review, and Discord release summary. Also trigger when Dave mentions 'update openclaw', 'new openclaw version', 'upgrade to v4.x', or 'what changed in the latest release'."

---

Safely upgrade OpenClaw, validate the environment, adopt beneficial new features, and produce a Discord release summary.

## When to Use

- Dave says "upgrade openclaw" or "update to latest"
- A new OpenClaw version is detected or mentioned
- Dave asks "what changed in the latest release"
- Dave shares release notes or changelog links

## Overview

Every upgrade follows this sequence:

1. **Pre-flight** — verify current state is healthy before touching anything
2. **Backup** — snapshot config and record current state
3. **Upgrade** — install new version
4. **Migrate** — run doctor to handle schema migrations
5. **Validate** — confirm everything survived
6. **Resolve** — fix any conflicts or regressions
7. **Review** — read release notes for beneficial features
8. **Adopt** — enable relevant features (with Dave's approval)
9. **Summarize** — produce Discord post for #openclaw-releases

### CRITICAL RULES

- Never skip pre-flight or backup
- Always `openclaw config validate` before gateway restart
- Never use `openclaw doctor --fix` AFTER manual config edits (it strips unrecognized keys). Only use it for version migration immediately after the npm upgrade step
- Get Dave's approval before enabling any new features
- If anything breaks, restore from backup before investigating

---

## Phase 1: Pre-Flight

Before upgrading, confirm the current environment is stable.

### 1.1 Record Current Version
```bash
openclaw --version
# Save output — this is the "before" version
```

### 1.2 Verify Gateway Health
```bash
openclaw doctor
openclaw status --verbose
```

Check for:
- Gateway running and responsive
- All providers connected (especially ollama-spark)
- All agents listed and healthy
- No critical errors

If there are existing issues, fix them BEFORE upgrading. Don't upgrade into a broken state.

### 1.3 Verify Cron Jobs
```bash
openclaw cron list
```

Record the current state of all cron jobs — model assignments, schedules, and last run status. You'll compare against this after upgrade.

### 1.4 Verify Model Connectivity

Test that local models respond:
```bash
curl -s --max-time 10 http://100.125.48.3:11434/api/tags
curl -s --max-time 10 http://127.0.0.1:11434/api/tags
```

If either Ollama instance is down, note it but don't block the upgrade.

### 1.5 Record Key Config Values

Read and save these values — they're the most likely to be affected:

- `models.providers.ollama-spark.api` (should be `"openai-responses"`)
- `models.providers.ollama-spark.baseUrl` (should include `/v1`)
- Scout's primary model in agents.list
- Morgan's primary model in agents.list
- `agents.defaults.subagents.model`
- All cron job model assignments
- Any recently added config (extraPaths, dreaming, memory-wiki, etc.)

Save this as a pre-upgrade snapshot in today's daily note.

---

## Phase 2: Backup

### 2.1 Config Backup
```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.pre-upgrade-${TIMESTAMP}
```

### 2.2 Verify Backup
```bash
diff ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.pre-upgrade-${TIMESTAMP}
# Should show no differences
```

### 2.3 Record Backup Path

Log the backup filename in today's daily note so it can be found later.

---

## Phase 3: Upgrade

### 3.1 Install New Version
```bash
npm install -g openclaw@latest
```

### 3.2 Verify Installation
```bash
openclaw --version
# Should show the new version number
```

If the version didn't change, check npm cache:
```bash
npm cache clean --force
npm install -g openclaw@latest
```

---

## Phase 4: Migrate

### 4.1 Run Doctor for Schema Migration

This is the ONE time `doctor --fix` is appropriate — it handles version-to-version schema migrations automatically.

```bash
openclaw doctor --fix
```

### 4.2 Check What Doctor Changed
```bash
diff ~/.openclaw/openclaw.json.pre-upgrade-${TIMESTAMP} ~/.openclaw/openclaw.json
```

Review the diff carefully. Doctor may have:

- Migrated config keys to new paths
- Changed value formats (e.g., `streaming: "partial"` → `streaming: {mode: "partial"}`)
- Added new required fields with defaults
- Stripped keys it doesn't recognize — this is the dangerous one

### 4.3 Verify Critical Config Survived

Compare against your Phase 1 pre-flight snapshot:

- [ ] ollama-spark provider: `api: "openai-responses"`, baseUrl with `/v1`
- [ ] Scout primary model: `ollama-spark/gemma4:26b`
- [ ] Morgan primary model: `ollama-spark/deepseek-r1:7b`
- [ ] All Spark models registered (gemma4, deepseek-r1, phi4, nemotron)
- [ ] `memorySearch.extraPaths` includes PARA paths
- [ ] Dreaming config intact
- [ ] Memory-wiki config intact (if enabled)
- [ ] Cron job model assignments unchanged

If any critical config was stripped, restore from backup:
```bash
cp ~/.openclaw/openclaw.json.pre-upgrade-${TIMESTAMP} ~/.openclaw/openclaw.json
```

Then manually reapply only the legitimate migrations from the doctor diff.

---

## Phase 5: Validate

### 5.1 Config Validation
```bash
openclaw config validate
```

Must pass before proceeding. If it fails, fix the errors — do NOT run `doctor --fix` again (it may strip more config).

### 5.2 Gateway Restart
```bash
# Kill and let auto-restart
ps aux | grep openclaw-gateway | grep -v grep
kill <PID>

# Wait for clean startup
sleep 10

# Verify running
ps aux | grep openclaw-gateway | grep -v grep

# Check logs for errors
tail -30 /private/tmp/openclaw-gateway.log
```

### 5.3 Post-Restart Checks
```bash
openclaw doctor # Should show no critical issues
openclaw status --verbose # Check provider health, cache stats, memory status
openclaw cron list # Verify all cron jobs intact
```

### 5.4 Model Test

Quick test that local models still respond through OpenClaw:
```bash
# Direct curl test to Spark
curl -s --max-time 30 http://100.125.48.3:11434/api/chat -d '{
  "model": "gemma4:26b",
  "stream": false,
  "messages": [{"role": "user", "content": "Say OK in JSON: {\"status\": \"ok\"}"}]
}'
```

### 5.5 Memory Test
```bash
# Test that memory search still works
# Use memory_search tool: "test query"
```

Verify embeddings are working (provider: auto should still resolve).

---

## Phase 6: Resolve

If any issues were found in Phase 5:

### Config Stripped by Doctor

1. Restore from backup: `cp ~/.openclaw/openclaw.json.pre-upgrade-${TIMESTAMP} ~/.openclaw/openclaw.json`
2. Review the doctor diff to identify legitimate migrations
3. Apply only the legitimate changes manually
4. `openclaw config validate`
5. Restart gateway

### Model Assignments Changed

1. Check `agents.list` for each agent
2. Check cron jobs: `openclaw cron list`
3. Restore correct model assignments
4. If cron models were reset, re-apply: `openclaw cron update <id> --model <model>`

### New Schema Validation Errors

1. Check which keys are failing
2. Search the release notes for migration guidance
3. Apply the documented fix
4. `openclaw config validate` before restart

### Provider Connection Failures

1. Verify Ollama is running on Spark: `curl http://100.125.48.3:11434/api/tags`
2. Verify Ollama on Mac mini (if used): `curl http://127.0.0.1:11434/api/tags`
3. Check if the API type changed — the `api` field has been a recurring issue:
   - v4.5+: `"openai-responses"` is the correct value for Ollama providers
   - `"ollama"` is NOT valid in the schema (despite appearing in docs)
   - `"openai-completions"` works but has worse tool calling

---

## Phase 7: Review Release Notes

Once the environment is stable, review what's new.

### 7.1 Fetch Release Notes

Read the release page for the new version:
```
https://github.com/openclaw/openclaw/releases/tag/v<VERSION>
```

### 7.2 Categorize Changes

Sort release items into these buckets:

**Breaking Changes** — things that could affect our setup:
- Config schema changes
- Removed features or deprecated paths
- Provider API changes
- Tool behavior changes

**Relevant Features** — things worth enabling for our setup:
- Memory/dreaming improvements
- Agent coordination improvements
- Ollama/local model improvements
- Prompt caching improvements
- Cron/automation improvements

**Not Relevant** — skip these:
- Channel-specific fixes (Slack, Discord, WhatsApp, etc.) unless we use them
- Provider-specific changes for providers we don't use
- Platform-specific fixes (Windows, Linux) unless they affect macOS

### 7.3 Report to Dave

For each relevant feature, provide:

- What it does (1-2 sentences)
- Why it matters for our setup
- What config change is needed
- Risk level (safe to enable / needs testing / wait)
- Recommendation (enable now / enable later / skip)

Do not enable features without Dave's approval.

---

## Phase 8: Adopt Features

When Dave approves a feature:

### 8.1 Pre-Change
```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.pre-feature-${FEATURE_NAME}
```

### 8.2 Apply

Make the config change.

### 8.3 Validate
```bash
openclaw config validate
```

### 8.4 Test

Restart gateway and test the specific feature.

### 8.5 Verify No Regression

Re-run the Phase 5 validation checks to confirm nothing else broke.

---

## Phase 9: Discord Summary

After upgrade is complete and stable, produce a summary for posting in the #openclaw-releases Discord channel.

### Format
```
## OpenClaw Upgrade: v{OLD} → v{NEW}

**Date:** {DATE}
**Status:** ✅ Stable

### What Changed (Our Setup)
- {Bullet list of changes that affected our environment}
- {Config migrations, if any}

### New Features Enabled
- {Features we turned on, with one-line description}

### Performance
- {Any speed/cost/cache improvements observed}
- Prompt cache hit rate: {X}%
- Scout (Gemma 4): {status}
- Morgan (DeepSeek R1): {status}

### Parked
- {Features we're aware of but skipped, with reason}

### Issues Encountered
- {Any problems hit during upgrade and how they were resolved}
- {Or "None — clean upgrade"}
```

### Rules for the Summary

- Keep it factual and concise
- Include version numbers
- Mention model performance if relevant
- Note any breaking changes that affected us
- Don't include irrelevant platform/channel fixes
- End with current system health status

---

## Quick Reference

### Known Pitfalls (from experience)

| Problem | Cause | Fix |
|---------|-------|-----|
| Config reverted after upgrade | `doctor --fix` stripped invalid keys | Restore from backup, apply migrations manually |
| `api: "ollama"` rejected | Not valid in v4.5+ schema | Use `api: "openai-responses"` |
| Cron jobs using old model | Cron payloads have explicit model overrides | `openclaw cron update <id> --model <model>` |
| Gateway won't restart | Invalid config key added | `openclaw config validate` to find the bad key |
| Embedding provider broken | Provider name changed between versions | Check `memorySearch.provider` — try `"auto"` |
| `brew services` fails on macOS | launchd permission issues | Kill process manually: `kill <PID>` |

### Emergency Rollback

If the upgrade is completely broken:
```bash
# 1. Restore config
cp ~/.openclaw/openclaw.json.pre-upgrade-${TIMESTAMP} ~/.openclaw/openclaw.json

# 2. Downgrade npm package
npm install -g openclaw@<PREVIOUS_VERSION>

# 3. Restart gateway
ps aux | grep openclaw-gateway | grep -v grep
kill <PID>
sleep 10

# 4. Verify
openclaw --version
openclaw doctor
```

### Config Edit Safety

- Before editing: `cp openclaw.json openclaw.json.backup`
- After editing: `openclaw config validate`
- Before restart: Verify changes are in the file
- After restart: Check logs + `openclaw status --verbose`
- NEVER run `doctor --fix` after manual edits
