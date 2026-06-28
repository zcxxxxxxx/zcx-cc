# AGENTS.md — Project Orientation

## Repo Overview

This repository contains research experiments in CFD, ML, and PINN-based surrogate modeling. Each experiment lives under `experiments/<topic>/` and is self-contained with its own plan, scripts, and state tracking.

## Conventions

- **Harness engineering:** Complex multi-step tasks use the harness-engineering framework. Plans live in `experiments/<topic>/docs/harness/active/`, validation templates in `docs/harness/templates/`.
- **State tracking:** Each experiment has a `STATE.md` with current phase, acceptance criteria, hard limits, and next steps.
- **Design docs:** Architecture decisions are recorded in `experiments/<topic>/docs/design.md`.
- **Outputs:** Large generated files (logs, cases, results) are gitignored per `experiments/<topic>/.gitignore`.
- **Mesh files:** Stub `.msh` files under `experiments/<topic>/meshes/` are placeholders. Replace with real meshes before running.

## Active Experiments

| Experiment | Status | Plan |
|------------|--------|------|
| CFD mesh sweep | SETUP | `experiments/cfd/docs/harness/active/2026-06-28-cfd-mesh-sweep-openfoam.md` |
| PINN HP search | — | `experiments/pinn_hp_search/` |
| PINN LoRA rank sweep | — | `experiments/pinn_lora_rank_sweep/` |

## Key Commands (CFD Mesh Sweep)

```bash
# Dry run
python experiments/cfd/scripts/run_loop.py --dry-run

# Full pipeline
bash experiments/cfd/scripts/run-mesh-sweep.sh all

# Validate a single mesh log
bash experiments/cfd/scripts/check-residuals.sh experiments/cfd/logs/mesh_1.log 1e-6

# Aggregate summary
# (generated automatically by run_loop.py)
```

## Git Rules

- Do not commit large output directories, processor directories, or time-step results.
- Only commit durable source: scripts, configs, templates, docs, plan files.
- State files (STATE.md) are tracked; raw logs are not.
