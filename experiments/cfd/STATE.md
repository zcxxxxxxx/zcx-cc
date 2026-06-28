# CFD Mesh Sweep — State

**Last updated:** 2026-06-28

## Overall Status

| Phase | Status |
|-------|--------|
| Plan | COMPLETE |
| Mesh inventory | COMPLETE (8 meshes logged) |
| Case setup scripts | READY |
| Convert meshes | PENDING |
| checkMesh quality | PENDING |
| Run solver | PENDING |
| Validate residuals | PENDING |
| Tabulate results | PENDING |
| Archive | PENDING |

## Active Meshes

Full plan at `docs/harness/active/2026-06-28-cfd-mesh-sweep-openfoam.md`

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

## Acceptance Criteria

| Criterion | Threshold | Status |
|-----------|-----------|--------|
| Mesh conversion | All 8 meshes convert without error | PENDING |
| checkMesh pass | All meshes pass checkMesh | PENDING |
| Solver stability | No NaN/divergence in any run | PENDING |
| Residual Ux | < 1e-6 | PENDING |
| Residual Uy | < 1e-6 | PENDING |
| Residual p | < 1e-6 | PENDING |
| Residual k | < 1e-6 | PENDING |
| Residual omega | < 1e-6 | PENDING |

## Hard Stop Conditions

| Limit | Value | Action on breach |
|-------|-------|------------------|
| Iteration limit (per mesh) | 5,000 | Stop solver, evaluate convergence |
| Retry limit (per mesh) | 1 retry only | Skip mesh, log reason, continue |
| Wall-clock (per mesh) | 48 hours | Kill solver, mark ERROR, move on |
| Wall-clock (total batch) | 7 days | Hard abort, preserve partial results |
| Max consecutive failures | 3 meshes | Pause loop, notify operator |

## Escalation Ladder

```
Level 1 — 1st divergence per mesh:    auto-retry with URF=0.3
Level 2 — Retry also diverges:        mark mesh FAIL, log reason, continue
Level 3 — 3+ consecutive mesh fails:  pause loop, wait for operator
```

## Next Step

Run `bash scripts/run-mesh-sweep.sh all` to convert and run all 8 meshes, then `bash scripts/check-residuals.sh` to validate convergence, or use the existing Python loop: `python scripts/run_loop.py`.
