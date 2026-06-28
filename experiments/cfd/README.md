# CFD Turbulence Simulation Loop

Automated batch loop for k-omega SST turbulence simulations over multiple meshes at Re=1e6.

## Overview

Processes 8 mesh files (mesh_1 through mesh_8) sequentially:
1. Sets up OpenFOAM case directory from template
2. Runs simpleFoam with k-omega SST turbulence model (Re=1e6)
3. Monitors convergence (all residuals < 1e-6)
4. Auto-retries once with relaxed under-relaxation on divergence
5. Generates aggregated summary (summary.md + summary.csv)

## Quick Start

```bash
# Run all 8 meshes (sequential)
python scripts/run_loop.py

# Run specific meshes only
python scripts/run_loop.py --mesh-list mesh_1 mesh_3 mesh_5

# Dry run (preview without executing)
python scripts/run_loop.py --dry-run

# Single mesh via bash wrapper
bash scripts/run_single.sh --mesh mesh_1

# Check convergence of a completed log
python scripts/check_convergence.py logs/mesh_1.log
```

## Directory Layout

| Path | Purpose |
|------|---------|
| `meshes/` | Mesh files (mesh_1.msh through mesh_8.msh) |
| `templates/` | OpenFOAM case templates (0/, constant/, system/) |
| `configs/` | YAML configuration files |
| `scripts/` | Automation scripts |
| `cases/` | Per-mesh case directories (gitignored, auto-generated) |
| `logs/` | Solver log files (gitignored, auto-generated) |
| `outputs/` | Results (gitignored, auto-generated) |

## Configuration

Edit `configs/solver_config.yaml` to adjust:
- **Solver**: simpleFoam (default)
- **Turbulence model**: kOmegaSST (default)
- **Reynolds number**: 1e6
- **Convergence tolerance**: 1e-6
- **Max retries**: 1
- **Relaxation factor on retry**: 0.3

Edit `configs/mesh_list.yaml` to add/remove/modify mesh entries.

## Architecture

```
run_loop.py  (entry point)
  |
  +-- LoopOrchestrator   — main loop, resume safety, per-mesh pipeline
  |     |
  |     +-- SolverInterface   — case setup, solver execution, retry URF
  |     +-- ConvergenceChecker  — residual parsing, divergence detection
  |     +-- SummaryGenerator   — markdown + CSV aggregation
  |
  +-- logs/run_loop_*.log    — full execution trace
  +-- outputs/summary.md     — human-readable results
  +-- outputs/summary.csv    — machine-readable results
```

## Harness Integration

This experiment is tracked via the harness-engineering framework:

- **Plan:** `docs/harness/active/2026-06-28-cfd-mesh-sweep-openfoam.md`
- **Validation template:** `docs/harness/templates/cfd-validation-template.md`
- **Check scripts:** `scripts/check-residuals.sh`, `scripts/check-mesh-quality.sh`
- **State tracking:** `STATE.md`

## Status

| Mesh ID | Airfoil | Cells | Type | Status |
|---------|---------|-------|------|--------|
| mesh_1 | NACA0012 | 32768 | structured | pending |
| mesh_2 | NACA0012 | 8192 | structured (coarse) | pending |
| mesh_3 | NACA0012 | 131072 | structured (fine) | pending |
| mesh_4 | RAE2822 | 32768 | structured | pending |
| mesh_5 | RAE2822 | 50000 | unstructured | pending |
| mesh_6 | NACA4412 | 32768 | structured | pending |
| mesh_7 | S809 | 51200 | structured | pending |
| mesh_8 | DU93-W-210 | 51200 | structured | pending |
