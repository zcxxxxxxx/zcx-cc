# CFD Mesh Sweep: k-omega SST Turbulence Simulation at Re=1e6

**Date:** 2026-06-28
**Status:** active
**Experiment path:** `experiments/cfd/`
**Solver:** OpenFOAM simpleFoam (kOmegaSST)
**Reynolds number:** 1e6
**Convergence tolerance:** 1e-6 (max residual across all fields)

---

## Objective

Run all 8 airfoil meshes through the OpenFOAM k-omega SST turbulence model at Re=1e6, verify each converges to residuals < 1e-6, and produce an aggregated summary. The study spans 4 airfoil types across structured and unstructured grids with cell counts from 8K to 131K.

---

## Mesh Inventory

| ID | Airfoil | Cells | Type | Description |
|----|---------|-------|------|-------------|
| mesh_1 | NACA0012 | 32,768 | structured (256x128) | Baseline medium grid |
| mesh_2 | NACA0012 | 8,192 | structured (128x64) | Coarse grid (grid convergence) |
| mesh_3 | NACA0012 | 131,072 | structured (512x256) | Fine grid (grid convergence) |
| mesh_4 | RAE2822 | 32,768 | structured (256x128) | Transonic airfoil |
| mesh_5 | RAE2822 | 50,000 | unstructured | Unstructured vs structured comparison |
| mesh_6 | NACA4412 | 32,768 | structured (256x128) | Cambered airfoil |
| mesh_7 | S809 | 51,200 | structured (320x160) | Wind turbine airfoil |
| mesh_8 | DU93-W-210 | 51,200 | structured (320x160) | Wind turbine airfoil |

---

## Numbered Steps

1. **Validate environment** -- Verify OpenFOAM installation, mesh files, config YAMLs, and template case structure.
2. **Dry-run check** -- Execute `python scripts/run_loop.py --dry-run` to confirm the execution plan.
3. **Execute batch loop** -- Run `python scripts/run_loop.py` from `experiments/cfd/` to process all 8 meshes sequentially.
4. **Monitor convergence** -- Each mesh runs up to 5000 iterations. Convergence checked every 50 iterations. Criteria: all field residuals (Ux, Uy, Uz, p, k, omega) < 1e-6.
5. **Handle divergence** -- On divergence (NaN, residual spike > 10, 20+ consecutive increases): auto-retry once with relaxed under-relaxation (U/k/omega = 0.3, p = 0.15). If retry also fails: mark FAIL, log reason, continue.
6. **Aggregate results** -- Generate `outputs/summary.md` (human-readable) and `outputs/summary.csv` (machine-readable) with per-mesh pass/fail, residuals, Cl/Cd, wall time.
7. **Audit completeness** -- Run `bash scripts/cfd-loop-audit.sh` to verify all 8 meshes have results and no anomalies.
8. **Record decisions** -- Document any failures, retries, or configuration changes in this plan file and in `STATE.md`.

---

## Acceptance Criteria

| Criterion | Description | Verifier |
|-----------|-------------|----------|
| AC-1 | All 8 meshes produce a solver log with no NaN/Inf/divergence markers | `check_convergence.py` |
| AC-2 | All final residuals < 1e-6 for every mesh (initial run or retry) | `check_convergence.py --tol 1e-6` |
| AC-3 | Per-mesh result JSON written to `outputs/<mesh_id>_result.json` | `cfd-loop-audit.sh [5/8]` |
| AC-4 | Aggregate summary.md and summary.csv generated in `outputs/` | `cfd-loop-audit.sh [4/8]` |
| AC-5 | At most 1 retry per failed mesh; retry reason documented | `STATE.md` failures section |
| AC-6 | Total batch completes within 7-day wall-clock limit | `cfd-loop-audit.sh` log timestamps |

---

## Resume Policy

- If interrupted mid-batch: re-run `python scripts/run_loop.py`. It will skip meshes with existing `<mesh_id>_result.json` files (resume-safe).
- To force re-run a specific mesh: delete its result JSON from `outputs/` and re-run.
- To force re-run all: `rm outputs/mesh_*_result.json && python scripts/run_loop.py`.

---

## Directory Structure (Harness)

```
experiments/cfd/
├── README.md              # Experiment overview + quick start
├── STATE.md               # Loop state + hard stop conditions + escalation ladder
├── .gitignore             # Ignores cases/, logs/, outputs/, __pycache__/
├── configs/
│   ├── mesh_list.yaml     # 8-mesh inventory with metadata
│   └── solver_config.yaml # Full solver parameterization
├── templates/
│   ├── 0/                 # Initial/boundary conditions (U, p, k, omega)
│   ├── constant/          # Turbulence properties (kOmegaSST)
│   └── system/            # controlDict, fvSchemes, fvSolution
├── meshes/                # mesh_1.msh through mesh_8.msh
├── scripts/
│   ├── run_loop.py        # Main orchestrator (Python)
│   ├── run_single.sh      # Bash wrapper for single-mesh runs
│   ├── check_convergence.py # Standalone convergence verifier
│   └── cfd-loop-audit.sh  # Loop health audit (8 checks)
├── cases/                 # (gitignored) Per-mesh case directories
├── logs/                  # (gitignored) Solver log files
└── outputs/               # (gitignored) Summary + per-mesh JSON results
```

## Validation Criteria (Taste Invariants)

The following standards are encoded as executable checks in `scripts/check-harness.sh`:

1. **Mesh completeness** -- All 8 mesh files exist and are non-empty.
2. **Config validity** -- YAML configs parse without error; all required keys present.
3. **Convergence gate** -- Verifier (`check_convergence.py`) is independent from writer (`run_loop.py`): no shared imports.
4. **Hard stop coverage** -- Iteration limit, retry limit, wall-clock limit, and divergence threshold all defined in config.
5. **Resume safety** -- Per-mesh result JSON files support safe resumption.
6. **Git integrity** -- All committed files tracked; no large binaries in git.

## Decision Records

*(To be filled post-execution)*

| Date | Decision | Rationale |
|------|----------|-----------|
| | | |

## Post-Execution Summary

*(To be filled post-execution)*

| Metric | Value |
|--------|-------|
| Meshes passed | /8 |
| Meshes failed | /8 |
| Retries triggered | /8 |
| Total wall time | |
| Git SHA | |

---

*Generated by harness-engineering skill. See `docs/harness/completed/` for archived plans.*
