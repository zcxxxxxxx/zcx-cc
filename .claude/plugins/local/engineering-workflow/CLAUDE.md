# Engineering Workflow Plugin

This plugin provides a three-tier engineering workflow stack:

```
Loop Engineering      — autonomous cycles: trigger → execute → verify → retry → escalate
Superpowers (ext.)    — session-level collaboration patterns (TDD, review, debug, branch)
Harness Engineering   — durable infrastructure: state files, check scripts, experiment templates
```

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

## Skills in this plugin

- `harness-engineering` — Experiment workflows, check scripts, validation templates, entropy management
- `loop-engineering` — Autonomous task loop design (5-step build method, composite loops, hard stops)

## How the tiers interact

1. **Loop Engineering orchestrates** — designs the cycle structure, triggers, gates, and escalation paths
2. **Loop delegates execution to Superpowers** — uses superpowers skills (TDD, debugging, parallel agents) for individual steps
3. **Loop runs on Harness infrastructure** — state files, check scripts, experiment templates, and validation gates come from harness
