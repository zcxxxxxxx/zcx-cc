# Engineering Workflow Plugin

Three-tier engineering workflow stack for complex multi-step tasks, experiment
verification, and autonomous loop design.

```
Loop Engineering      — orchestration: trigger → execute → verify → retry → escalate
Superpowers (ext.)    — session patterns: TDD, review, debug, parallel agents
Harness Engineering   — infrastructure: STATE.md, check scripts, templates
```

## Core Features

- **Cost-Aware Fast Path** — auto-classifies task scope (code_only / pure harness / pure loop / full stack) and loads only relevant context
- **Code templates** — `harness-engineering/scripts/templates/` provides reusable file-watcher and equation-solver scripts
- **STATE.md dual variant** — Variant A for full experiment tracking, Variant B for lightweight code-task state
- **Writer/Verifier separation** — independent gate verification, no shared context between executor and verifier
- **Hard stop conditions** — iteration limit + wall-clock timeout + failure threshold, with 3-level escalation ladder (retry → notify → halt)
- **Entropy management** — archive completed experiments, prune stale outputs

## Dependency: Superpowers

This plugin requires the [superpowers](https://github.com/obra/superpowers) plugin.

### Auto-install

If superpowers is not already installed, install it by cloning the repository:

```bash
git clone https://github.com/obra/superpowers.git /tmp/superpowers
```

Then follow the superpowers installation instructions in its README.

To check if superpowers is already installed, look for:
- `~/.claude/plugins/cache/claude-plugins-official/superpowers/` directory, OR
- The `superpowers` entry in `~/.claude/plugins/installed_plugins.json`

## Skills

- `harness-engineering` — Experiment workflows, check scripts, validation templates, entropy management
- `loop-engineering` — Autonomous task loop design (5-step build method, composite loops, hard stops)

## Tier Interaction

1. **Loop Engineering orchestrates** — designs the cycle structure, triggers, gates, and escalation paths
2. **Loop delegates execution to Superpowers** — uses superpowers skills for individual steps
3. **Loop runs on Harness infrastructure** — state files, check scripts, experiment templates, and validation gates

### Cost-Aware Fast Path

| Task scope | What to load | Example |
|-----------|-------------|---------|
| **Code only** | Skip loop + harness. Reference templates only. | Write a Python script to process data |
| **Pure harness** | Harness-engineering only | Configure experiment params, write check script |
| **Pure loop** | Loop-engineering only | Design a timer-based website monitoring loop |
| **Full stack** | Both tiers | CFD parameter sweep + convergence loop |

## Reference Files

- `INTERFACES.md` — Interface contracts between the three tiers
- `skills/harness-engineering/scripts/templates/` — Reusable code templates
- `skills/loop-engineering/references/anti-patterns.md` — Common loop design mistakes
- `skills/loop-engineering/references/readiness-test.md` — 4-condition readiness test + trigger guide
