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
- **STATE.md triple variant** — Variant A (full experiment), Variant B (code-task), Variant C (delta sweeps)
- **Execution contract** — `scripts/generate-contract.sh` compresses plan artifacts into a single checkable contract with SHA256 content-level staleness detection
- **Content-level state detection** — `check-harness.sh contract` mode validates SHA256 hashes of source artifacts against contract; `loop-audit.sh` checks STATE.md content freshness
- **Experiment artifact templates** — `references/experiment-artifacts.md` provides structured plan/spec/design/task templates inspired by OpenSpec
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

## Tier Interaction (CRITICAL — READ THIS FIRST)

These three tiers form a stack. For any multi-step experiment or research task,
you MUST load ALL THREE: `harness-engineering`, `loop-engineering`, AND
relevant superpowers skills (`tdd`, `debugging`, `review`, `parallel-agent`).

```
Loop Engineering      — orchestrates: designs cycles, triggers, gates, escalation
  ↓ delegates to
Superpowers (ext.)    — executes: TDD, review, debug, parallel agents
  ↓ runs on
Harness Engineering   — infrastructure: STATE.md, check scripts, contracts
```

- If you loaded `harness-engineering` but the task has 3+ steps → also load `loop-engineering` + superpowers skills
- If you loaded `loop-engineering` but the task needs experiment tracking → also load `harness-engineering` + superpowers skills
- If you loaded only superpowers skills but the task needs orchestration or tracking → also load loop + harness
- Superpowers skills to load: `tdd` (code writing), `debugging` (fix issues), `review` (code review), `parallel-agent` (parallel dispatch)
- Use the fast-path table below to determine if ONE tier can be skipped for simple tasks
- When in doubt, load both — the fast-path logic handles the "skip if unnecessary" case

### Cost-Aware Fast Path

| Task scope | What to load | Example |
|-----------|-------------|---------|
| **Code only** | Skip loop + harness. Reference templates only. | Write a Python script to process data |
| **Pure harness** | Harness-engineering only | Configure experiment params, write check script |
| **Pure loop** | Loop-engineering only | Design a timer-based website monitoring loop |
| **Full stack** | Both tiers | CFD parameter sweep + convergence loop |

## Reference Files

- `INTERFACES.md` — Interface contracts between the three tiers (+ Variant C delta STATE.md, + Interface 6 Execution Contract)
- `skills/harness-engineering/scripts/templates/` — Reusable code templates
- `skills/harness-engineering/scripts/generate-contract.sh` — Execution contract generator
- `skills/harness-engineering/references/experiment-artifacts.md` — Structured experiment plan templates
- `skills/harness-engineering/references/execution-contract.md` — Execution contract template and guide
- `skills/loop-engineering/references/anti-patterns.md` — Common loop design mistakes
- `skills/loop-engineering/references/readiness-test.md` — 4-condition readiness test + trigger guide
