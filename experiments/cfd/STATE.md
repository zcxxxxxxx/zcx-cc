# CFD Mesh Sweep — State

**Last updated:** 2026-06-28

## Overall Status

| Phase | Status |
|-------|--------|
| Plan | COMPLETE |
| AGENTS.md | CREATED |
| Validation template | CREATED |
| Mesh inventory | COMPLETE (8 meshes logged) |
| Case setup scripts | READY |
| Mesh files (real) | NEEDED (stubs in place) |
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

## Harness Artifacts

| Artifact | Path | Status |
|----------|------|--------|
| Plan | `docs/harness/active/2026-06-28-cfd-mesh-sweep-openfoam.md` | CREATED |
| Validation template | `docs/harness/templates/cfd-validation-template.md` | CREATED |
| Design doc | `docs/design.md` | CREATED |
| AGENTS.md | `../../AGENTS.md` | CREATED |
| State file | `STATE.md` | UPDATED |

## Next Step

1. Replace stub mesh files (`meshes/*.msh`) with real mesh geometry.
2. Adjust `FOAM_BASH` path in `scripts/run-mesh-sweep.sh` for local OpenFOAM installation.
3. Run `bash scripts/run-mesh-sweep.sh all` to convert and run all 8 meshes.
4. Validate: `bash scripts/check-residuals.sh logs/mesh_1.log 1e-6` (repeat for each).
5. Or use: `python scripts/run_loop.py` for the Python orchestrator with auto-retry.
