# Loop Design — PINN Hyperparameter Sweep

> Built following the Loop Engineering 5-Step Build Method.
> Reference: `C:\Users\WIN11\.claude\plugins\local\engineering-workflow\skills\loop-engineering\SKILL.md`

---

## Step 1 — Machine-Verifiable Goal

> Run all 18 PINN configurations with recorded loss curves. For each config: attempt training up to 3 retries on failure, verify output files via independent gate, and log pass/fail. If 3 consecutive configs fail, pause and escalate. When all 18 are done (DONE or FAILED after retries), aggregate results and rank top-3 by validation loss. Best config wins smallest validation loss.

**4-Condition Readiness Test:**
- [x] **Condition 1 — Verifiable success**: Each config has DONE/FAILED status in metrics.json
- [x] **Condition 2 — Verifiable failure**: verify.py returns non-zero exit, metrics.json shows FAILED_NAN
- [x] **Condition 3 — Bounded scope**: 18 configs, 50k steps each, ~12 hours max
- [x] **Condition 4 — No human-in-loop needed**: Retry logic + escalation handles edge cases

---

## Step 2 — Minimum Viable Loop

### Architecture

```
┌──────────────────────────────────────────────────────────┐
│                 Parent Loop (Orchestrator)                │
│  Reads STATE.md → picks next pending config              │
│  ├── Retry check: retries < 3? → re-queue or mark FAILED │
│  ├── Consecutive check: < 3 failures? → continue or STOP  │
│  └── Escalation: Level 0/1/2/3 → log + alert             │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────┐   ┌──────────────────────────┐  │
│  │   Trainer (Writer)   │   │   Verifier (Gate)        │  │
│  │   pinn/train.py      │──▶│   pinn/verify.py         │  │
│  │   Outputs:            │   │   Checks:                │  │
│  │   - loss_curve.csv    │   │   - File existence       │  │
│  │   - metrics.json      │   │   - JSON validity        │  │
│  │   - config.json       │   │   - No NaN/Inf in loss   │  │
│  │   - model_state.npz   │   │   - Steps completed      │  │
│  └──────────────────────┘   │   - Loss convergence      │  │
│                              │   - CSV integrity         │  │
│                              └──────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

### Components

| Component | File | Role |
|-----------|------|------|
| Trigger | `scripts/run_sweep_parent.sh --loop` | Manual start, auto-loop |
| Context | `STATE.md` | Current progress, retry counts, limits |
| State File | `STATE.md` + `outputs/retry_state.json` | Persisted progress + retry tracking |
| Gate | `pinn/verify.py` | Independent output verification |
| Trainer | `pinn/train.py` | Config execution |
| Results | `scripts/aggregate_results.py` | Final ranking + analysis |

### Writer/Verifier Separation

The trainer writes output files to `outputs/{config_name}/`. The verifier (`verify.py`) reads **only those output files** and has zero knowledge of training internals, chain-of-thought, or failure modes. This prevents the verifier from "grading generously" based on shared context.

Verifier checks performed independently:
1. Required files exist (metrics.json, loss_curve.csv, config.json)
2. metrics.json is valid JSON with required fields
3. Status is DONE
4. No NaN or Inf in final losses
5. Steps completed >= expected (50,000)
6. CSV parses and has valid entries
7. No NaN in CSV loss values
8. Loss convergence (final < initial — informational)

---

## Step 3 — Writer/Verifier Separation

Enforced by design:
- **Writer**: `pinn/train.py` produces outputs in `outputs/{config}/`
- **Verifier**: `pinn/verify.py` reads only from `outputs/{config}/`
- No shared variables, no shared imports (except numpy for NaN check)
- Verifier main() is a separate script invoked as subprocess by the parent loop
- Parent loop never passes trainer exit code to verifier — verifier makes its own determination

---

## Step 4 — Hard Stop Conditions

### Limits (all defined in STATE.md under "Limits" section)

| Limit | Value | Enforcement | Action |
|-------|-------|-------------|--------|
| **Iteration limit** | 25 max loop iterations | `run_sweep_parent.sh` counter | Aggregate partial, exit 2 |
| **Per-config retry limit** | 3 retries per config | `retry_state.json` counter | Mark FAILED, move to next |
| **Consecutive failure limit** | 3 consecutive configs | STATE.md consecutive counter | Escalate Level 3, pause loop |
| **Wall-clock timeout** | 12 hours total | `check_wall_clock()` per cycle | Log partial, exit 2 |
| **Per-config timeout** | 2 hours | Not enforced in script (manual monitor) | Kill hung process if needed |

### Escalation Ladder (3-Level)

```
Level 0 — nominal
  └── No failures, all configs training normally

Level 1 — single config failure (NaN/error)  
  ├── Action: auto-retry config (increment retry counter)
  ├── Log: "Config X failed (attempt N/3), re-queuing"
  └── Transition: next cycle retries same config

Level 2 — retries exhausted for a config (3 failures)
  ├── Action: mark config FAILED, continue to next config
  ├── Log: "Config X: 3 retries exhausted, marking FAILED"
  └── Transition: move to next pending config

Level 3 — 3 consecutive configs fail
  ├── Action: pause loop, print alert to stdout
  ├── Log: "ESCALATION: 3 consecutive configs failed"
  ├── Suggestion: check PDE parameters, environment, data
  └── Recovery: manual intervention required, clear retry_state or fix root cause
```

### When Limits Are Hit

1. Log the failure reason to STATE.md (under "Failures" section)
2. Print prominent alert to stdout (with color highlighting)
3. If Level 3: pause loop (exit with code 2)
4. Wait for human intervention

---

## Step 5 — Track the One Metric That Matters

**Primary metric: Acceptance rate** = configs that pass verification / total configs attempted

| Threshold | Action |
|-----------|--------|
| Acceptance rate > 80% | Nominal — loop is effective |
| Acceptance rate 50-80% | Acceptable — some configs genuinely diverge |
| Acceptance rate < 50% | Review: check if verification is too strict or training has bugs |

**Secondary metrics:**
- **Cost per accepted config**: estimated total compute time / number of DONE configs
- **Retry efficiency**: number of configs that passed after retry vs. on first attempt

---

## Retry State Management

Retries are tracked in `outputs/retry_state.json`:

```json
{
  "per_config_retries": {
    "pinn_lr1e-3_w128_act_silu": 0,
    "pinn_lr5e-4_w32_act_tanh": 2
  },
  "consecutive_failures": 0,
  "last_config_status": "DONE",
  "last_updated": "2026-06-28T..."
}
```

- Created on first failure, persists across loop cycles
- Cleared when all configs are done or on manual reset
- Each config retry counter resets to 0 only when config reaches DONE status

---

## References

- Loop Engineering SKILL: `C:\Users\WIN11\.claude\plugins\local\engineering-workflow\skills\loop-engineering\SKILL.md`
- Harness Engineering: `C:\Users\WIN11\.claude\skills\harness-engineering\SKILL.md`
- Anti-Patterns: `C:\Users\WIN11\.claude\skills\harness-engineering\references\anti-patterns.md`
- Harness plan: `docs/harness/active/2026-06-28-pinn-hp-sweep.md`
- Escalation protocol: `docs/escalation-protocol.md`
