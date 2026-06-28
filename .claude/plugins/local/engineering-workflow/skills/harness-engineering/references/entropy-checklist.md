# Entropy Management Checklist

Research repositories naturally decay. Use these checklists at regular
intervals to keep the harness effective.

## Weekly Quick Check (~5 min)

Run during idle time or at session end:

- [ ] Any completed experiments in `docs/harness/active/`?
      Move to `completed/`.
- [ ] Any orphaned output directories in `experiments/*/outputs/`?
      Clean up if >1 week old.
- [ ] AGENTS.md still accurate? Remove stale entries.
- [ ] `scripts/check-harness.sh audit` passes?

## Per-Milestone Audit (~15 min)

Before switching projects, submitting a paper, or starting a major new
experiment:

- [ ] All experiments have plan + results artifacts.
- [ ] All decisions recorded with commit SHAs.
- [ ] No uncommitted config changes in working tree.
- [ ] `scripts/check-harness.sh audit` — full run.
- [ ] Stale branches identified (consider pruning).
- [ ] All paper figures can be traced to source data in repo.

## Per-Paper-Submission Audit (~30 min)

Full reproducibility check before submission:

- [ ] Can every figure be regenerated from committed code+configs?
- [ ] Are all random seeds recorded and reproducible?
- [ ] Do validation summaries match paper claims?
- [ ] Is the claim scoping correct? (No level-2 claims presented as level-3)
- [ ] Has a **verifier agent** (independent context) confirmed the results?
- [ ] Are all external dependencies pinned (requirements.txt, etc.)?
- [ ] Is the code/data availability statement ready?

## Signs of Entropy

Watch for these warning signs:

| Symptom | Meaning | Fix |
|---------|---------|-----|
| "I can't find the config for that run" | Experiment not archived | Complete the plan+results artifact |
| "This script doesn't work anymore" | Dependency drift | Pin versions, add CI check |
| "I'm sure I fixed this before" | Fix not recorded | Write a decision record |
| "The figure doesn't match the data" | Manual editing | Add reproducibility check |
| "Which seed did we use?" | Seed not tracked | Add seed invariant check |
