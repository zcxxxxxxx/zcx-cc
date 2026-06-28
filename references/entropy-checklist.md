# Entropy Management Checklist

This file links to the canonical entropy checklist in the harness-engineering skill.
For the authoritative version, see:
`skills/harness-engineering/references/entropy-checklist.md`

## Quick Reference

### Weekly Quick Check (~5 min)
- [ ] Any completed experiments in `docs/harness/active/`? Move to `completed/`.
- [ ] Any orphaned output directories in `experiments/*/outputs/`? Clean up if >1 week old.
- [ ] `scripts/check-harness.sh audit` passes?

### Per-Milestone Audit (~15 min)
- [ ] All experiments have plan + results artifacts.
- [ ] All decisions recorded with commit SHAs.
- [ ] No uncommitted config changes.
- [ ] `scripts/check-harness.sh audit` — full run.

### Signs of Entropy
| Symptom | Fix |
|---------|-----|
| "I can't find the config for that run" | Complete the plan+results artifact |
| "Which seed did we use?" | Run `scripts/check_seeds.sh` |
| "This script doesn't work anymore" | Pin dependencies |
