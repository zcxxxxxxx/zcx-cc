# PINN Hyperparameter Search — Autonomous Loop

## Objective

Run an autonomous hyperparameter sweep for a Physics-Informed Neural Network (PINN) solving the 1D Burgers equation. The sweep covers 18 configurations (3 learning rates x 3 network widths x 2 activation functions), each trained for 50,000 steps. The loop autonomously dispatches, monitors, recovers from NaN failures, and ranks results by validation loss.

## Goal Statement (Machine-Verifiable)

> Run all 18 PINN configurations with recorded loss curves. For each config: train 50k steps, log step-by-step loss to CSV, and evaluate final validation loss. NaN runs are marked FAILED and skipped. When all 18 are done (DONE or FAILED), aggregate results and rank top-3 by validation loss. Best config wins smallest validation loss.

## Hyperparameter Space

| Parameter | Values | Count |
|-----------|--------|-------|
| Learning rate | `1e-4`, `5e-4`, `1e-3` | 3 |
| Hidden width | `32`, `64`, `128` | 3 |
| Activation | `tanh`, `silu` | 2 |
| **Total** | | **18** |

## Config Naming Convention

```
pinn_lr{lr}_w{width}_act{activation}
Example: pinn_lr1e-4_w32_act_tanh
```

## Architecture

### Loop Structure (Composite Parent-Child)

```
┌──────────────────────────────────────────────────┐
│            Parent Loop (Orchestrator)             │
│  Reads STATE.md → picks next pending config      │
│  Dispatches child: train config                  │
│  Runs independent verifier on output             │
│  Updates STATE.md with pass/fail                 │
│  Loops until all 18 configs processed            │
├──────────────────────────────────────────────────┤
│                                                   │
│  ┌─────────────────┐  ┌─────────────────┐        │
│  │  Trainer (Child) │  │  Verifier (Gate) │        │
│  │  train.py        │  │  verify.py       │        │
│  │  Outputs:        │  │  Checks:         │        │
│  │  - loss_curve.csv│  │  - No NaN in loss│        │
│  │  - metrics.json  │  │  - Valid loss vals│        │
│  │  - model.pt      │  │  - Curve integrity│        │
│  └─────────────────┘  └─────────────────┘        │
└──────────────────────────────────────────────────┘
```

### Writer/Verifier Separation

The trainer writes output files. The verifier reads **only the output files** and has zero knowledge of training internals, chain-of-thought, or failure modes. This prevents the verifier from "grading generously" based on shared context.

## Hard Stop Conditions

| Limit | Value | Action on Hit |
|-------|-------|---------------|
| Max iterations | 25 (18 + 7 retries) | Pause loop, escalate to human |
| Wall-clock timeout | 12 hours total | Pause loop, log partial results |
| Consecutive NaN limit | 3 in a row | Pause loop — likely systemic issue |
| Per-config runtime | 2 hours | Kill hung process, mark FAILED |

## Escalation Ladder

```
Level 1 — 1st NaN/error:           auto-retry config once (with note in STATE.md)
Level 2 — 2nd failure on same config: mark FAILED, note in STATE.md, continue
Level 3 — 3 consecutive NaN/configs: pause loop, notify human
```

## Acceptance Criteria

| Criterion | Check Method |
|-----------|--------------|
| All 18 configs processed (DONE or FAILED) | `scripts/check_completion.sh` |
| Each DONE config has valid loss_curve.csv + metrics.json | `verify.py` per config |
| No NaN values in any DONE config's loss curve | `verify.py` check_nan |
| Top-3 configs ranked by validation loss | `scripts/aggregate_results.py` |
| Parameter influence analysis included in report | `scripts/aggregate_results.py` output |

## Expected Outputs

### Per Config (`outputs/{config_name}/`)
- `loss_curve.csv` — step-by-step training + validation loss
- `loss_curve.png` — loss vs step plot
- `metrics.json` — final metrics (val_loss, train_loss, wall_time, steps_completed)
- `config.json` — copy of hyperparameter config used
- `model_state.npz` — final model weights (NumPy serialization)

### Aggregate (`outputs/`)
- `sweep_results.csv` — consolidated results across all configs
- `sweep_ranking.md` — ranked results with parameter influence analysis
- `sweep_comparison.png` — side-by-side comparison plot

## Resume Behavior

- The parent loop reads STATE.md to determine which configs are pending.
- If outputs/{config_name}/metrics.json exists and contains `status: DONE`, the config is skipped.
- To force re-run: `rm outputs/{config_name}/metrics.json`.
- Partial runs (interrupted mid-training) must be re-run from scratch.

## References

- Loop Engineering: `C:\Users\WIN11\.claude\skills\loop-engineering\SKILL.md`
- Loop Templates — PINN Hyperparameter Search (domain-specific template)
- State File Guide: `references/state-file-guide.md`
- Anti-Patterns: `references/anti-patterns.md`
