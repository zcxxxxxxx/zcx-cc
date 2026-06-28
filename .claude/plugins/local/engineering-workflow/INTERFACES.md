# Engineering Workflow — Interface Contracts

This document defines the contracts between the three tiers of the engineering-workflow plugin.

## Tier Architecture

```
┌─────────────────────────────────────────────────┐
│  Loop Engineering  (orchestration)               │
│  ── invokes superpowers skills for execution     │
│  ── uses harness for state/check/template infra  │
├─────────────────────────────────────────────────┤
│  Superpowers  (session patterns)                 │
│  ── provides TDD, debugging, review, branch ops  │
│  ── called by loop at specific cycle steps       │
├─────────────────────────────────────────────────┤
│  Harness Engineering  (infrastructure)            │
│  ── provides STATE.md convention                 │
│  ── provides check-harness.sh integrity script   │
│  ── provides validation/entropy templates        │
└─────────────────────────────────────────────────┘
```

## Interface 1: STATE.md Convention

**Provider:** Harness Engineering
**Consumer:** Loop Engineering, any agent reading/writing state

```
STATE.md format:
# Project State

## Status
- Current: RUNNING | PAUSED | COMPLETE | FAILED
- Cycle: N (integer, incremented each iteration)

## Per-Item Tracking
| Item | Status | Attempts | Last Output | Notes |
|------|--------|----------|-------------|-------|
| ...  | PASS/FAIL/RETRY | N | path/to/output | ... |

## Limits (Hard Stops)
- Max iterations per item: 3
- Wall-clock timeout: 120min per cycle
- Max consecutive failures: 3

## Escalation
- Level: 0 (none) | 1 (retrying) | 2 (notified) | 3 (paused)
- Last escalation: timestamp + reason
```

**Contract:** Any agent can read/write STATE.md. The format must be parseable
by both humans and scripts (grep-friendly sections, pipe-delimited tables).

## Interface 2: check-harness.sh

**Provider:** Harness Engineering
**Consumer:** Loop Engineering (gate verification step)

```bash
# Exit codes:
#   0 — all checks pass
#   1 — setup checks failed (missing files, bad configs)
#   2 — runtime checks failed (diverged, NaN, threshold breach)
#   3 — audit checks failed (git hygiene, stale state)

# Modes:
bash scripts/check-harness.sh setup    # Pre-flight: files, configs, deps
bash scripts/check-harness.sh audit    # Full audit: integrity + entropy
```

**Contract:** The script must be self-contained (no imports beyond stdlib/bash
builtins). It must exit 0 for pass and non-zero for fail with specific codes.
Loop gates call this script and interpret exit codes.

## Interface 3: Validation Templates (Claim Levels)

**Provider:** Harness Engineering (`references/validation-templates.md`)
**Consumer:** Loop Engineering (gate criteria)

| Level | Meaning | Gate check |
|-------|---------|------------|
| **L1: Demonstrate** | Evidence exists for the claim | Assertion passes with any valid evidence |
| **L2: Consistent with** | Multiple independent observations align | Cross-validate 2+ sources |
| **L3: Validated** | Formal test with known error bounds | Statistical test, known confidence interval |

**Contract:** Loop gates specify required claim level per assertion.
The verifier checks evidence against the specified level.

## Interface 4: Plan Artifacts

**Provider:** Harness Engineering
**Consumer:** Loop Engineering, any experiment participant

```
docs/harness/active/YYYY-MM-DD-topic.md

Required sections:
1. Objective (one line)
2. Numbered execution steps
3. Acceptance criteria (numbered, with verifier reference)
4. Resume policy (what's safe to resume, what needs re-verify)
```

**Contract:** Plan files live in `docs/harness/active/` during execution and
are moved to `docs/harness/completed/` on completion (by harness entropy
management). Loop reads the plan to bootstrap context.

## Interface 5: Superpowers Skill References

**Provider:** Superpowers
**Consumer:** Loop Engineering

| Skill name | When loop calls it |
|------------|-------------------|
| `dispatching-parallel-agents` | Composite loop pattern — launching child loops |
| `systematic-debugging` | Failure analysis in escalation Level 1-2 |
| `verification-before-completion` | Independent gate verification step |
| `finishing-a-development-branch` | Pre-merge cleanup after all configs pass |

**Contract:** These skills are loaded by name. The superpowers plugin must be
installed for the references to resolve.
