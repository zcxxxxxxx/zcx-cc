# CFD Mesh Sweep: OpenFOAM k-omega SST at Re=1e6

**Created:** 2026-06-28
**Status:** SETUP
**Plan file:** `experiments/cfd/docs/harness/active/2026-06-28-cfd-mesh-sweep-openfoam.md`
**State tracking:** `experiments/cfd/STATE.md`

## Objective

Run 8 mesh files through OpenFOAM `simpleFoam` with the k-omega SST turbulence model at Re=1e6. Each mesh must converge to residuals < 1e-6. Results are aggregated into a summary for cross-mesh comparison.

## Mesh Inventory

| ID | Airfoil | Cells | Type | Status |
|----|---------|-------|------|--------|
| mesh_1 | NACA0012 | 32,768 | structured | pending |
| mesh_2 | NACA0012 | 8,192 | structured (coarse) | pending |
| mesh_3 | NACA0012 | 131,072 | structured (fine) | pending |
| mesh_4 | RAE2822 | 32,768 | structured | pending |
| mesh_5 | RAE2822 | 50,000 | unstructured | pending |
| mesh_6 | NACA4412 | 32,768 | structured | pending |
| mesh_7 | S809 | 51,200 | structured | pending |
| mesh_8 | DU93-W-210 | 51,200 | structured | pending |

## Pipeline Stages

Each mesh passes through four sequential stages:

```
Convert  ──>  checkMesh  ──>  Solve  ──>  Validate
```

### Stage 1: Convert
Convert the mesh file to OpenFOAM polyMesh format.
- **Command:** `bash scripts/run-mesh-sweep.sh convert` (all meshes)
- **Resume:** Already-converted meshes are skipped if output exists.
- **Evidence:** `cases/<mesh_id>/constant/polyMesh/` directory must exist.

### Stage 2: checkMesh
Validate mesh quality metrics.
- **Command:** `bash scripts/check-mesh-quality.sh [mesh_id]`
- **Acceptance:** `checkMesh` must report `Mesh OK.` without critical warnings.
- **Metrics log:** `outputs/<mesh_id>/checkMesh.log`
- **Resume:** Skip if `outputs/<mesh_id>/checkMesh.pass` exists.

### Stage 3: Solve
Run simpleFoam with k-omega SST.
- **Command:** `bash scripts/run-mesh-sweep.sh run` (all) or `bash scripts/run_single.sh --mesh <mesh_id>`
- **Solver:** `simpleFoam` (steady-state, incompressible)
- **Turbulence model:** `kOmegaSST`
- **Reynolds number:** 1e6
- **Max iterations:** 5,000
- **Log:** `logs/<mesh_id>.log`
- **Resume:** Skips meshes with `outputs/<mesh_id>/.done` marker.

### Stage 4: Validate
Check convergence against tolerance.
- **Command:** `bash scripts/check-residuals.sh logs/<mesh_id>.log 1e-6`
- **Alternative:** `python scripts/check_convergence.py logs/<mesh_id>.log --json > outputs/<mesh_id>/validation.json`
- **Acceptance:** All field residuals < 1e-6.

## Acceptance Criteria

| Criterion | Threshold | Check Method |
|-----------|-----------|--------------|
| Mesh conversion | All 8 meshes convert without error | `bash scripts/check-mesh-quality.sh` |
| Mesh quality | `checkMesh` passes (`Mesh OK.`) | `bash scripts/check-mesh-quality.sh` |
| Solver stability | No NaN/divergence in any run | Implicit in residual check |
| Residual Ux | < 1e-6 | `bash scripts/check-residuals.sh` |
| Residual Uy | < 1e-6 | `bash scripts/check-residuals.sh` |
| Residual p | < 1e-6 | `bash scripts/check-residuals.sh` |
| Residual k | < 1e-6 | `bash scripts/check-residuals.sh` |
| Residual omega | < 1e-6 | `bash scripts/check-residuals.sh` |
| Summary generation | `outputs/summary.md` and `outputs/summary.csv` created | File existence check |

## Commands

```bash
# --- Stage 0: Validate environment ---
bash scripts/cfd-loop-audit.sh

# --- Stage 1 + 2 + 3: Full pipeline ---
bash scripts/run-mesh-sweep.sh all

# --- Stage 2 (standalone mesh quality) ---
bash scripts/check-mesh-quality.sh

# --- Stage 4: Validate residuals ---
for i in $(seq 1 8); do
  bash scripts/check-residuals.sh logs/mesh_$i.log 1e-6
done

# --- Or: Python orchestration (preferred) ---
python scripts/run_loop.py

# --- Python convergence check (per mesh) ---
python scripts/check_convergence.py logs/mesh_1.log --json

# --- Single-mesh run ---
bash scripts/run_single.sh --mesh mesh_1

# --- Dry run (preview without execution) ---
python scripts/run_loop.py --dry-run
```

## Escalation & Retry

| Level | Condition | Action |
|-------|-----------|--------|
| L1 | 1st divergence per mesh | Auto-retry with URF=0.3 |
| L2 | Retry also diverges | Mark FAIL, log reason, continue |
| L3 | 3+ consecutive mesh fails | Pause loop, wait for operator |

## Hard Limits

| Limit | Value | Action on breach |
|-------|-------|------------------|
| Iteration limit | 5,000 | Stop, evaluate partial convergence |
| Retry limit | 1 | Skip, log, move on |
| Wall-clock per mesh | 48 h | Kill, mark ERROR, continue |
| Wall-clock total | 7 days | Hard abort, preserve partial results |

## Expected Outputs

```
logs/
  run_loop_<timestamp>.log   # Full execution trace
  mesh_1.log                 # Solver log per mesh
  ...
outputs/
  summary.md                 # Human-readable results
  summary.csv                # Machine-readable results
  mesh_1/
    result.json              # Per-mesh result + metadata
    validation.json          # Convergence check details
    environment.log          # Run environment snapshot
    checkMesh.log            # Mesh quality metrics
    simpleFoam.log           # Raw solver output
```

## Known Risks

1. **Mesh stubs:** All 8 `meshes/*.msh` are currently stub files. Real mesh files must replace them before the pipeline runs.
2. **OpenFOAM availability:** The solver path `FOAM_BASH` defaults to `/opt/openfoam10/etc/bashrc`. Adjust for local installation.
3. **Windows compatibility:** `bc` and `seq` are assumed. On Windows/Git Bash, `bc` may be missing, causing `check-residuals.sh` comparisons to fail silently. The Python `check_convergence.py` script is preferred.
4. **Mesh format:** The conversion heuristic in `run-mesh-sweep.sh` inspects file headers. If all meshes share a format, adjust the default conversion command.

## Resume Behavior

- Each stage checks for completion markers before running.
- Re-running the pipeline skips completed work and resumes from the first incomplete stage.
- To force a re-run of a specific mesh: `rm outputs/<mesh_id>/.done` or `rm outputs/<mesh_id>/.status`.

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-06-28 | Initial plan | zcxxxxxxx |
