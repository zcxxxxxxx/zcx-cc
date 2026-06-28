# PINN LoRA Rank Sweep Experiment

## Objective
Determine the optimal LoRA rank for a PINN by scanning r ∈ {1, 2, 4, 8} with fixed seed=42 and 1000 epochs.

## Status

| Run ID | Status | Final Loss | Wall Time |
|--------|--------|------------|-----------|
| rank1_seed42 | pending | — | — |
| rank2_seed42 | pending | — | — |
| rank4_seed42 | pending | — | — |
| rank8_seed42 | pending | — | — |

## Quick Start

```bash
# Run all configurations sequentially
bash scripts/run_all.sh

# Run a single configuration
bash scripts/run_single.sh --rank 4 --seed 42 --epochs 1000
```

## Results Summary

*To be filled after experiment execution.*

## Directory Layout

- `configs/` — YAML configuration files per rank
- `scripts/` — Reproducible launch scripts
- `docs/` — Plan and results documentation
- `outputs/` — Training logs and metrics (gitignored)
- `checkpoints/` — Model weight snapshots (gitignored)
- `figures/` — Generated plots (gitignored)
