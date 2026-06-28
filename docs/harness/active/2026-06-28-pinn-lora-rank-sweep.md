# PINN LoRA Rank Sweep Experiment

## Objective
Systematically scan LoRA rank values {1, 2, 4, 8} for a PINN (Physics-Informed Neural Network) to determine the optimal rank that balances expressivity and parameter efficiency. All runs use seed=42 and train for 1000 epochs.

## Motivation
LoRA (Low-Rank Adaptation) reduces the number of trainable parameters in PINNs by decomposing weight updates into low-rank matrices. The rank r controls the bottleneck dimension: higher ranks capture more complex solution features but increase computational cost. This sweep identifies the minimum rank sufficient for the target PDE accuracy.

## Plan

### Configurations

| Run ID | Rank | Seed | Epochs | Trainable Params (approx) |
|--------|------|------|--------|---------------------------|
| rank1_seed42 | 1 | 42 | 1000 | ~0.125x base |
| rank2_seed42 | 2 | 42 | 1000 | ~0.25x base |
| rank4_seed42 | 4 | 42 | 1000 | ~0.5x base |
| rank8_seed42 | 8 | 42 | 1000 | ~1.0x base (full rank) |

### Steps

1. **Setup**: Generate config YAML files for each rank.
2. **Pre-flight**: Run `scripts/check-harness.sh setup` to verify configs and environment.
3. **Execute rank=1**: `python train.py --config configs/rank1.yaml`
4. **Execute rank=2**: `python train.py --config configs/rank2.yaml`
5. **Execute rank=4**: `python train.py --config configs/rank4.yaml`
6. **Execute rank=8**: `python train.py --config configs/rank8.yaml`
7. **Validate**: Run convergence checks and collect final metrics.
8. **Decide**: Recommend optimal rank based on accuracy/cost trade-off.

## Directory Structure

```
experiments/pinn_lora_rank_sweep/
├── README.md               # Objective + status summary
├── configs/
│   ├── rank1.yaml           # LoRA rank=1
│   ├── rank2.yaml           # LoRA rank=2
│   ├── rank4.yaml           # LoRA rank=4
│   └── rank8.yaml           # LoRA rank=8
├── docs/
│   └── plan.md              # This plan (linked from harness active)
├── outputs/                 # .gitignore-d (training logs, metrics)
│   ├── rank1_seed42/
│   ├── rank2_seed42/
│   ├── rank4_seed42/
│   └── rank8_seed42/
├── checkpoints/             # .gitignore-d (model weights)
│   ├── rank1_seed42/
│   ├── rank2_seed42/
│   ├── rank4_seed42/
│   └── rank8_seed42/
├── figures/                 # .gitignore-d (loss curves, error plots)
└── scripts/
    ├── run_all.sh            # Submit all rank jobs
    ├── run_single.sh         # Run a single rank config
    ├── check_convergence.sh  # Taste invariant: loss < threshold
    └── check_nan.sh          # Taste invariant: NaN-free training
```

## Configuration Details

Each config file contains:
- `model.lora_rank`: int — the LoRA bottleneck dimension (1, 2, 4, 8)
- `training.seed`: 42 — fixed for reproducibility
- `training.epochs`: 1000 — number of training iterations
- `training.lr`: 1e-3 — learning rate (fixed across all runs)
- `training.lr_scheduler`: cosine — cosine annealing schedule
- `pde.type`: [TBD: specify PDE, e.g., burgers, poisson, navier_stokes]
- `pde.nu`: [TBD: PDE parameter, e.g., viscosity]
- `logging.wandb`: disabled — local logging only
- `logging.save_every`: 100 — checkpoint every 100 epochs

## Acceptance Criteria

| Criterion | Threshold | Check Method |
|-----------|-----------|--------------|
| Final PDE residual loss | < 1.0e-4 | `scripts/check_convergence.sh` |
| Training L2 error | < 1.0e-3 | Parse final validation metrics |
| No NaN in gradients/loss | NaN-free | `scripts/check_nan.sh` |
| Relative improvement from rank 1 to 8 | Logged | Compare final losses |
| Wall time per run | Recorded | Parse training log timestamps |
| All 4 runs complete without crash | 4/4 | Job exit codes |

## Expected Outputs

### Per-run (stored in `outputs/{run_id}/`)
- `training.log` — full training log with epoch-by-epoch loss
- `config.yaml` — copy of the config used
- `metrics.json` — final metrics (final_loss, l2_error, wall_time, param_count)
- `loss_curve.png` — training loss vs epoch plot

### Aggregate (stored in `outputs/`)
- `sweep_results.csv` — consolidated results across all ranks
- `sweep_comparison.png` — final loss vs rank plot

## Resume Behavior

- Rerunning the experiment script checks `outputs/{run_id}/metrics.json`.
- If metrics.json exists and contains `final_loss`, the run is skipped.
- To force re-run: `rm outputs/{run_id}/metrics.json`.
- Partial runs (interrupted before checkpoint) resume from latest checkpoint.

## Validation

After all runs complete, execute:

```bash
bash scripts/check_convergence.sh outputs/rank1_seed42/training.log 1e-4
bash scripts/check_convergence.sh outputs/rank2_seed42/training.log 1e-4
bash scripts/check_convergence.sh outputs/rank4_seed42/training.log 1e-4
bash scripts/check_convergence.sh outputs/rank8_seed42/training.log 1e-4
```

Aggregate pass/fail into `docs/results.md`.

## Decision Record

| Field | Value |
|-------|-------|
| What was tried | LoRA rank sweep {1,2,4,8}, seed=42, 1000 epochs |
| What passed | TBD after execution |
| What failed | TBD after execution |
| What changed | TBD after execution |
| Commit | TBD |
| Next | TBD — recommend optimal rank or expand sweep |

## References

- LoRA: Hu et al., "LoRA: Low-Rank Adaptation of Large Language Models", ICLR 2022
- PINN: Raissi et al., "Physics-Informed Neural Networks", JCP 2019
- Project harness: `F:/Git_repo/zcx-cc/docs/harness/`
