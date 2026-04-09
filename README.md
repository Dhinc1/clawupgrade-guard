# ClawUpgrade Guard

**Agent-driven OpenClaw upgrades with pre-flight checks, migration validation, and rollback guidance.**

## What It Does

ClawUpgrade Guard teaches your OpenClaw agent to upgrade the system safely — not just running `npm update` and hoping for the best. It adds:

- **Pre-flight visibility** — Validates current state before touching anything
- **Change explanations** — Interprets what `openclaw doctor --fix` changed and why
- **Survival validation** — Verifies critical config (models, PARA paths, cron jobs) survived migration
- **Human-readable diffs** — Shows before/after with context
- **Rollback guidance** — Helps you recover if things break
- **Agent-driven workflow** — Your agent walks you through it, explains decisions

## Installation

### As an AgentSkill (Recommended)

```bash
# Clone to your OpenClaw skills directory
cd ~/.openclaw/skills/
git clone https://github.com/YOUR_USERNAME/clawupgrade-guard.git

# Or install via symbolic link
ln -s ~/path/to/clawupgrade-guard ~/.openclaw/skills/claw_upgrade_guard
```

### Standalone (Without OpenClaw Agent)

```bash
git clone https://github.com/YOUR_USERNAME/clawupgrade-guard.git
cd clawupgrade-guard
chmod +x scripts/*.sh
./scripts/upgrade.sh
```

## Usage

### Via Agent

```
You: "Upgrade OpenClaw to the latest version"

Agent: [reads SKILL.md, follows 9-phase protocol]
- Phase 1: Pre-flight checks (current version, health, model connectivity)
- Phase 2: Backup (config snapshot with timestamp)
- Phase 3: Upgrade (npm install)
- Phase 4: Migrate (openclaw doctor --fix)
- Phase 5: Validate (verify critical config survived)
- Phase 6: Restart gateway
- Phase 7: Test (basic interaction, memory, files, cron)
- Phase 8: Review release notes
- Phase 9: Summarize changes
```

### Manual

```bash
# Run full upgrade protocol
./scripts/upgrade.sh

# Individual phases
./scripts/pre-flight.sh        # Check current state
./scripts/backup.sh            # Snapshot config
./scripts/validate.sh          # Verify survival after migration
./scripts/rollback.sh          # Restore from backup
```

## What Makes This Different from `openclaw doctor`

| Feature | `openclaw doctor --fix` | ClawUpgrade Guard |
|---------|-------------------------|-------------------|
| Schema migration | ✅ Automatic | ✅ Automatic |
| Pre-flight health check | ❌ | ✅ Full validation |
| Config backup | ⚠️ One `.bak` file | ✅ Timestamped snapshots |
| Change explanation | ❌ | ✅ Human-readable diff + interpretation |
| Survival validation | ❌ | ✅ Verifies models, PARA, cron jobs intact |
| Rollback guidance | ❌ | ✅ Step-by-step recovery |
| Agent-driven | ❌ | ✅ Agent explains each step |

## Example Output

```
=== Phase 1: Pre-Flight ===
Current version: OpenClaw 2026.4.8
Gateway: healthy (PID 74741)
Scout primary model: ollama-spark/gemma4:26b ✓
Morgan primary model: ollama-spark/deepseek-r1:7b ✓
PARA paths indexed: 132 files ✓

=== Phase 4: Migrate ===
Running openclaw doctor --fix...

Doctor changed 33 config paths:
  • Removed stale plugin: capability
  • Fixed permissions: 644 → 600
  • Archived 2 orphan transcripts

=== Phase 5: Validate ===
✓ Ollama Spark provider survived (api: openai-responses, /v1 endpoint)
✓ Scout model intact: ollama-spark/gemma4:26b
✓ Morgan model intact: ollama-spark/deepseek-r1:7b
✗ PARA paths missing! Restoring from backup...

[restores from backup, re-applies legitimate migrations only]
```

## Protocol Phases

1. **Pre-Flight** — Verify current state is healthy
2. **Backup** — Snapshot config with timestamp
3. **Upgrade** — Install new version via npm
4. **Migrate** — Run doctor for schema migrations
5. **Validate** — Check critical config survived
6. **Resolve** — Fix conflicts or rollback
7. **Review** — Read release notes for new features
8. **Adopt** — Enable beneficial features (with approval)
9. **Summarize** — Log changes to memory

Full protocol details: [SKILL.md](SKILL.md)

## Requirements

- OpenClaw v2026.4.x or later
- Agent with skill loading enabled
- `jq` for config validation (optional but recommended)

## Contributing

PRs welcome! Please follow the existing structure:
- Protocol phases in `SKILL.md`
- Standalone scripts in `scripts/`
- Examples in `examples/`
- Docs in `docs/`

## License

MIT

## Credits

Created by Dave Hughes (@maxbox)  
Part of the OpenClaw ecosystem 🦞
