# Decision Record: CFD Mesh Sweep Experiment Setup

**Date:** 2026-06-28
**Author:** harness-engineering

## Context

Set up a harness-tracked CFD mesh sweep evaluating OpenFOAM k-omega SST convergence across 8 meshes at Re=1e6. Each mesh must converge to residuals < 1e-6 for all fields (Ux, Uy, p, k, omega).

## Decision

1. **Solver**: `simpleFoam` with `kOmegaSST` turbulence model (steady-state RANS).
2. **Flow conditions**: Incompressible, Re=1e6 (U=1.0 m/s, L=1.0 m, nu=1e-6 m^2/s).
3. **Mesh inventory**: 8 meshes covering 4 airfoil geometries (NACA0012, RAE2822, NACA4412, S809, DU93-W-210) with structured and unstructured grids, cell counts from 8K to 131K.
4. **Convergence criterion**: All residuals < 1e-6; max 5000 iterations; 1 auto-retry with relaxed URF=0.3 on divergence; 3 consecutive failures pauses the batch.
5. **Directory layout**: Follows `experiments/<name>/` convention with `configs/`, `scripts/`, `meshes/`, `outputs/`, `logs/`, `cases/`.
6. **Taste invariants**: Mesh quality check and residual convergence check registered in `scripts/check-harness.sh`.
7. **Validation template**: Per-mesh report template at `docs/harness/templates/cfd-validation-template.md`.
8. **Summary generation**: Python script aggregates results into `summary.md` and `summary.csv` with PASS/FAIL/DIVERGED/PENDING status per mesh.

## Alternatives Considered

- **Batch loop via `run_loop.py`** vs. sequential bash: Python chosen for better error handling, resume safety, and structured logging.
- **Residual tolerance 1e-8**: Rejected as unnecessarily strict for engineering RANS; 1e-6 is standard for aerodynamic validation.
- **potentialFoam initialization**: Optional; to be enabled only if a mesh fails to converge on first attempt.

## Consequences

- Plan and check scripts encode all acceptance criteria as executable checks (taste invariants).
- Summary generation is standalone (no dependency on run_loop.py), satisfying the verifier isolation pattern.
- Results matrix in the plan will be filled as meshes complete.
- Commit SHA is logged per run for reproducibility.
