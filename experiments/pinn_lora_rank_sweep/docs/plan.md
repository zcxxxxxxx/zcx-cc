# PINN LoRA Rank Sweep — Experiment Plan

> This document is a symlink target / copy of the canonical plan at:
> `docs/harness/active/2026-06-28-pinn-lora-rank-sweep.md`
>
> For the full plan with acceptance criteria, validation steps, and decision
> record template, see the canonical location above.

## Quick Reference

| Parameter | Value |
|-----------|-------|
| Ranks | 1, 2, 4, 8 |
| Seed | 42 |
| Epochs | 1000 |
| Learning rate | 0.001 |
| Scheduler | Cosine annealing |
| Configs | `configs/rank{1,2,4,8}.yaml` |
| Launch | `bash scripts/run_all.sh` |
| Single run | `bash scripts/run_single.sh --rank 4 --seed 42` |

## Directory Structure

```
experiments/pinn_lora_rank_sweep/
├── README.md
├── configs/
│   ├── rank1.yaml
│   ├── rank2.yaml
│   ├── rank4.yaml
│   └── rank8.yaml
├── docs/
│   └── plan.md
├── outputs/           (gitignored)
│   ├── rank1_seed42/
│   ├── rank2_seed42/
│   ├── rank4_seed42/
│   └── rank8_seed42/
├── checkpoints/       (gitignored)
├── figures/           (gitignored)
└── scripts/
    ├── run_all.sh
    └── run_single.sh
```
