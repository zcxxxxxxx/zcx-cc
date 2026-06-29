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

### Variant A: Full experiment STATE.md (for loops + harness)

Used by loop tasks with experiment infrastructure — tracks status, cycle count,
per-item progress, hard stop limits, escalation path.

```
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

### Variant B: Code-task STATE.md (for code_only tasks)

Lightweight variant for pure code tasks: no cycles, no limits, no escalation.
Just summary, per-item results, and notes.

```
# <Task Name> State

## Summary
- **Total items processed:** N
- **Results:** <key metric>
- **Status:** COMPLETE | FAILED

## Per-Item Results
| # | Input | Expected | Actual | Status |
|---|-------|----------|--------|--------|
| 1 | ...   | ...      | ...    | PASS/FAIL |

## Notes
- Script: <filename>
- Output files: <file list>
```

**Contract:** Any agent can read/write STATE.md. code_only tasks MUST use
Variant B (lightweight). Full-stack tasks MUST use Variant A.
Iterative sweep/scan tasks SHOULD use Variant C (delta).
Format must be parseable by both humans and scripts (grep-friendly sections,
pipe-delimited tables).

### Variant C: Delta STATE.md (for iterative sweeps)

Delta variant for parameter sweeps, hyperparameter scans, and other iterative
experiments where each cycle only changes a few variables. Instead of rewriting
the full state each cycle, append only what changed.

```
# Delta State — Cycle <N>

## Changes from Previous Cycle
| Parameter | Previous | Current | Reason |
|-----------|----------|---------|--------|
| <param>   | <old>    | <new>   | <why>  |

## New Results This Cycle
| Config | Status | Key Metric | vs Baseline |
|--------|--------|------------|-------------|
| <id>   | PASS/FAIL | <val>   | <delta>    |

## Accumulated Best
- **Best config so far:** <config-id> (<metric>)
- **Total cycles completed:** <N>
- **Convergence trend:** improving | stable | degrading

## Next
- <what to try next cycle>
```

**Contract:** Variant C MUST be accompanied by a full Variant A STATE.md for
accumulated context. The delta records only the diff between consecutive cycles.
When N exceeds 20, archive accumulated deltas and reset.

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
builtins). Exit 0 for pass, non-zero for fail with specific error codes.
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

## Interface 6: Execution Contract

**Provider:** Harness Engineering (`scripts/generate-contract.sh`)
**Consumer:** Loop Engineering (gate before execution)

```
bash scripts/generate-contract.sh [experiment-dir]  # Generate contract
bash scripts/check-harness.sh contract [experiment-dir]  # Validate contract freshness
```

The execution contract is a single compressed document that captures the
agreement between planning and execution. It is generated from source
artifacts (plan, design, tasks) and validated by SHA256 content hashing.

**Contract:**
- Execution MUST NOT begin without a valid execution-contract.md
- If source artifacts change, the contract SHA256 hashes mismatch →
  execution is blocked until the contract is regenerated
- Code-only tasks (Variant B) skip the contract; full-stack tasks MUST
  generate and validate the contract before each execution cycle
- Loop gate calls `check-harness.sh contract` before each cycle
