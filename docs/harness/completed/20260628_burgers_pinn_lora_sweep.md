# [ABANDONED] Burgers PINN LoRA Rank Sweep

## Objective
Sweep LoRA ranks 1-8 for Burgers equation PINN.

## Plan
1. `python train.py --rank 1 --epochs 1000`
2. `python train.py --rank 2 --epochs 1000`
3. `python train.py --rank 4 --epochs 1000`
4. `python train.py --rank 8 --epochs 1000`

## Final Status
**ABANDONED** — superseded by the full harness-managed sweep at `docs/harness/active/2026-06-28-pinn-lora-rank-sweep.md`.

## Abandonment Record
| Field | Value |
|-------|-------|
| Last activity | 2026-06-12 |
| Abandoned on | 2026-06-28 |
| Status at abandonment | rank 4 complete, rank 8 in progress |
| Reason | Replaced by structured harness experiment with full acceptance criteria, validation scripts, and decision records |
| Stale for | 16 days |
| Action | None — all scripts preserved in `experiments/pinn_lora_rank_sweep/` |
