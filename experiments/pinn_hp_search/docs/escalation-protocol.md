# Escalation Protocol — PINN Hyperparameter Sweep

## Overview

This document defines the escalation response for the autonomous hyperparameter sweep loop. When the loop encounters failures beyond automatic recovery, it follows this protocol to alert the human operator.

---

## Escalation Levels

### Level 0 — Nominal
**Condition:** No failures, all configs training normally.

**Response:** Continue loop. No action needed.

**Log entry:** `[ESC] Level 0 — nominal`

---

### Level 1 — Single Config Failure
**Condition:** A config fails verification (NaN, error, timeout).

**Response:**
1. Increment per-config retry counter in `retry_state.json`
2. If retries < 3: re-queue the config, continue loop
3. Log the failure to STATE.md

**Log entry:** `[ESC] Level 1 — {config} failed (retry {N}/3)`

---

### Level 2 — Retries Exhausted
**Condition:** A config has failed 3 times.

**Response:**
1. Mark config as FAILED in STATE.md
2. Record the final error state
3. Move to next pending config
4. Check consecutive failure counter

**Log entry:** `[ESC] Level 2 — {config}: 3 retries exhausted, marking FAILED`

---

### Level 3 — Consecutive Failures
**Condition:** 3 consecutive distinct configs have all failed.

**Response:**
1. **Pause the loop immediately** (exit code 2)
2. Print prominent alert to stdout (RED text, boxed)
3. Print diagnostic suggestions
4. Wait for human intervention

**Log entry:** `[ESC] Level 3 — 3 consecutive configs failed. Loop PAUSED.`

**Diagnostic suggestions:**
```
=== ESCALATION: 3 consecutive configs failed ===
  Last 3 failed: {config1}, {config2}, {config3}
  
  Possible causes:
  1. Learning rate too high — check lr_scheduler config
  2. PDE parameters incorrect — verify nu, x_range, t_range
  3. Environment issue — check Python/PyTorch installation
  4. Data generation bug — check generate_collocation_points
  
  To resume after fixing:
    bash scripts/run_sweep_parent.sh --loop
    
  To reset retry counters:
    rm outputs/retry_state.json
    
  To inspect individual config:
    python pinn/verify.py outputs/{config_name}
```

**Human intervention checklist:**
- [ ] Check training logs in `outputs/{failed_config}/loss_curve.csv`
- [ ] Check metrics.json for error details
- [ ] Verify environment: `python -c "import torch; print(torch.__version__)"`
- [ ] Verify config files: `python configs/generate_configs.py`
- [ ] If fixed, clear retry state: `rm outputs/retry_state.json`
- [ ] Resume loop: `bash scripts/run_sweep_parent.sh --loop`

---

## Notification

Currently, escalation prints to stdout/stderr. Planned enhancements:

| Channel | Integration | Status |
|---------|-------------|--------|
| stdout | Color-coded terminal output | Implemented |
| Log file | `outputs/escalation.log` | Implemented |
| Desktop notification | `notify-send` / `msg` | Planned |
| Slack webhook | curl to Slack API | Planned |
| Email | SMTP relay | Planned |

---

## Recovery After Escalation

1. Diagnose root cause using the checklist above
2. Fix the issue (config, environment, or code)
3. Clear retry state: `rm outputs/retry_state.json`
4. Clear failed config metrics (optional, to force re-run):
   ```bash
   rm outputs/{failed_config1}/metrics.json
   rm outputs/{failed_config2}/metrics.json
   rm outputs/{failed_config3}/metrics.json
   ```
5. Resume loop:
   ```bash
   bash scripts/run_sweep_parent.sh --loop
   ```

---

## References

- Loop Engineering: 3-level escalation ladder (SKILL.md Step 4)
- Harness plan: `docs/harness/active/2026-06-28-pinn-hp-sweep.md`
- Loop design: `docs/loop-design.md`
