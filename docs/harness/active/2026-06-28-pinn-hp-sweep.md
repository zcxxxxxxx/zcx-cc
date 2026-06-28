# PINN Hyperparameter Sweep — Burgers Equation

## Objective

Run an autonomous hyperparameter sweep for a Physics-Informed Neural Network (PINN) solving the 1D Burgers equation. The sweep covers 18 configurations (3 learning rates x 3 network widths x 2 activation functions), each trained for 50,000 steps. The loop autonomously dispatches, retries on failure (up to 3 retries per config), monitors consecutive failures (escalate at 3), and ranks results by validation loss.

## Plan

### Step 1 — Pre-flight
- Verify configs exist (18 JSON files + manifest.json in `configs/`)
- Verify environment (Python, PyTorch or NumPy)
- Create output directories
- Run: `python configs/generate_configs.py` (if configs missing)
- Run: `bash scripts/check-harness.sh setup`

### Step 2 — Autonomous Loop Execution
- **Trigger**: `bash scripts/run_sweep_parent.sh --loop`
- **Behavior**: 
  - Reads STATE.md, picks next pending config
  - Trains config via `pinn/train.py`
  - Verifies output via independent `pinn/verify.py` (separate writer/verifier)
  - Updates metrics.json with status (DONE / FAILED_NAN / FAILED)
  - Updates STATE.md with progress
  - Retries failed configs up to 3 times
  - Escalates if 3 consecutive configs fail
  - Stops when all 18 configs processed or hard limit hit

### Step 3 — Validation
- All configs processed (DONE or FAILED after retries)
- No NaN in any DONE config's loss curve
- Top-3 ranked by validation loss
- Parameter influence analysis (LR, width, activation)

### Step 4 — Decision
- Record optimal hyperparameters
- Document which configs failed and why
- Archive plan from active/ to completed/

## Configurations

| Parameter | Values | Count |
|-----------|--------|-------|
| Learning rate | 1e-4, 5e-4, 1e-3 | 3 |
| Hidden width | 32, 64, 128 | 3 |
| Activation | tanh, silu | 2 |
| **Total** | | **18** |

## Hard Stop Conditions

| Limit | Value | Action |
|-------|-------|--------|
| Max iterations | 25 (18 + 7 retry overhead) | Pause loop, aggregate partial results |
| Wall-clock timeout | 12 hours total | Pause loop, log partial results |
| Consecutive config failures | 3 | Escalate Level 3 — pause + alert human |
| Per-config retries | 3 per config | Mark FAILED, move to next |
| Per-config runtime | 2 hours | Kill hung process |

## Escalation Ladder

```
Level 0 — nominal:           all configs passing
Level 1 — single NaN/error:  auto-retry config (up to 3 attempts per config)
Level 2 — repeated failures: mark FAILED after 3 retries exhausted, continue
Level 3 — 3 consecutive configs fail: pause loop, alert human, wait for intervention
```

## Acceptance Criteria

| Criterion | Threshold | Check Method |
|-----------|-----------|--------------|
| All 18 configs processed | 18/18 DONE or FAILED after retries | `scripts/check_completion.sh` |
| Each DONE config validated | PASS from verify.py | `scripts/check-harness.sh audit` |
| No NaN in DONE configs | Zero NaN/Inf entries | verify.py loss_nan_check |
| Ranking produced | sweep_ranking.md exists | Manual review |
| Parameter influence analysis | LR, width, activation breakdown | Present in sweep_ranking.md |
| Consecutive failures < 3 | Max 2 consecutive failures | STATE.md escalation level |

## Resume Policy

- Loop reads STATE.md to determine pending configs
- If `outputs/{config}/metrics.json` has status DONE, config is skipped
- If FAILED_NAN and retries < 3, config is re-queued
- To force re-run: `rm outputs/{config_name}/metrics.json`
- Partial runs (interrupted mid-training) must re-run from scratch
- Retry counter resets only on DONE status or manual intervention

## Commit

- All configs, scripts, and docs committed to `experiments/pinn_hp_search/`
- Outputs/ is gitignored
- Harness plan committed to `docs/harness/active/`

## References

- Harness Engineering: `C:\Users\WIN11\.claude\skills\harness-engineering\SKILL.md`
- Loop Engineering: `C:\Users\WIN11\.claude\plugins\local\engineering-workflow\skills\loop-engineering\SKILL.md`
- Experiment docs: `experiments/pinn_hp_search/docs/loop-design.md`
- Escalation protocol: `experiments/pinn_hp_search/docs/escalation-protocol.md`
