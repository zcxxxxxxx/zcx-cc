# PINN Hyperparameter Search -- Burgers Equation

Autonomous hyperparameter sweep for a Physics-Informed Neural Network (PINN) solving the 1D Burgers equation.

## Overview

**Objective:** Find the optimal hyperparameter combination (learning rate, hidden width, activation function) for a PINN solving `du/dt + u*du/dx - nu*d2u/dx2 = 0` on `x in [-1,1]`, `t in [0,1]`.

**Search space:** 18 configurations = 3 learning rates x 3 network widths x 2 activation functions.

| Parameter | Values |
|-----------|--------|
| Learning rate | 1e-4, 5e-4, 1e-3 |
| Hidden width | 32, 64, 128 |
| Activation | tanh, silu |

**Training:** Each config trained for 50,000 steps with cosine LR scheduler, Adam optimizer, 4 hidden layers, seed 42.

## Architecture

```
Parent Loop (Orchestrator)      -- run_sweep_parent.sh / run_sweep_harness.sh
  +-- Trainer (Writer)           -- pinn/train.py
  +-- Verifier (Gate)            -- pinn/verify.py (independent, no shared context)
  +-- State                      -- STATE.md + outputs/retry_state.json
  +-- Aggregator                 -- scripts/aggregate_results.py
  +-- Health Checker             -- scripts/check-harness.sh
```

## Loop Behavior

- **Per-config retries:** up to 3 retries per config before marking FAILED
- **Consecutive failure detection:** alerts and pauses if 3 configs in a row fail
- **Writer/verifier separation:** `train.py` writes outputs, `verify.py` reads only output files (no shared context with trainer)
- **3-level escalation ladder:**
  - Level 1: single NaN/error -> auto-retry
  - Level 2: retries exhausted -> mark FAILED, continue
  - Level 3: 3 consecutive failures -> pause loop, alert human

## Usage

```bash
# Setup
bash scripts/setup.sh

# Run full autonomous sweep
bash scripts/run_sweep_parent.sh --loop

# Check status
bash scripts/run_sweep_parent.sh --status

# Run with harness-enhanced orchestration (extended logging)
bash scripts/run_sweep_harness.sh --loop

# Verify harness integrity
bash scripts/check-harness.sh setup
bash scripts/check-harness.sh audit

# Check completion status
bash scripts/check_completion.sh

# Reset retry state (after fixing root cause)
bash scripts/run_sweep_parent.sh --reset-retry

# Aggregate results (after all configs processed)
python scripts/aggregate_results.py
```

## Outputs (`outputs/`)

**Per config (`outputs/{config_name}/`):**
- `loss_curve.csv` -- step-by-step training + validation loss
- `metrics.json` -- final metrics (val_loss, train_loss, wall_time, status)
- `config.json` -- hyperparameter config used
- `model_state.npz` -- final model weights

**Aggregate (`outputs/`):**
- `sweep_results.csv` -- consolidated results across all configs
- `sweep_ranking.md` -- ranked results with parameter influence analysis
- `retry_state.json` -- persistent retry counters

## Hard Stop Conditions

| Limit | Value | Action |
|-------|-------|--------|
| Per-config retries | 3 | Mark FAILED, move to next |
| Consecutive failures | 3 | Pause loop, escalate |
| Wall-clock timeout | 12 hours | Log partial results, stop |
| Max iterations | 25 | Aggregate partial results, stop |
| Per-config timeout | 2 hours | Kill hung process |

## Files

```
experiments/pinn_hp_search/
+-- README.md                     # This file
+-- sweep_config.json             # Master sweep configuration
+-- STATE.md                      # Loop state (auto-updated)
+-- .gitignore
+-- configs/                      # 18 config JSON files + manifest
|   +-- manifest.json
|   +-- generate_configs.py
|   +-- pinn_lr{*}_w{*}_act_{*}.json
+-- pinn/                         # PINN implementation
|   +-- model.py                  # PINN model (PyTorch + NumPy)
|   +-- train.py                  # Training entry point
|   +-- utils.py                  # Data gen, loss, logging
|   +-- verify.py                 # Independent verification gate
+-- scripts/                      # Orchestration and utilities
|   +-- run_sweep_parent.sh       # Parent orchestrator loop
|   +-- run_sweep_harness.sh      # Harness-enhanced orchestrator
|   +-- check-harness.sh          # Integrity check script
|   +-- check_completion.sh       # Completion verification
|   +-- aggregate_results.py      # Result ranking + analysis
|   +-- setup.sh                  # One-time setup
+-- docs/                         # Design documentation
|   +-- plan.md                   # Execution plan
|   +-- loop-design.md            # Loop design doc
|   +-- escalation-protocol.md    # Escalation protocol
+-- outputs/                      # Training outputs (gitignored)
```

## Harness Plan

See `docs/harness/active/2026-06-28-pinn-hp-sweep.md` at repo root for the full harness experiment plan with acceptance criteria and resume policy.
