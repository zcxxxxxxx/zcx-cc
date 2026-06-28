# CFD Validation Record

Use this template to record per-mesh validation results. One record per mesh.

## Mesh Metadata

- **Mesh ID:** `mesh_N`
- **Airfoil:** `NACA0012 / RAE2822 / NACA4412 / S809 / DU93-W-210`
- **Cell count:** `####`
- **Mesh type:** `structured / unstructured`

## Command

```bash
# Example: full pipeline command
python scripts/run_loop.py --mesh-list mesh_N

# Example: validation only
bash scripts/check-residuals.sh logs/mesh_N.log 1e-6
```

## Result

- **Status:** `passed / failed / partial`
- **Commit:** `<short-sha>`
- **Date:** `YYYY-MM-DD`
- **Output directory:** `outputs/mesh_N/`

## Acceptance

| Criterion | Result | Metric |
|-----------|--------|--------|
| Mesh conversion | `passed/failed` | — |
| checkMesh quality | `passed/failed` | `Mesh OK.` / warnings |
| Solver stability | `passed/failed` | NaN/divergence: yes/no |
| Residual Ux | `passed/failed` | `X.XXe-XX` |
| Residual Uy | `passed/failed` | `X.XXe-XX` |
| Residual p | `passed/failed` | `X.XXe-XX` |
| Residual k | `passed/failed` | `X.XXe-XX` |
| Residual omega | `passed/failed` | `X.XXe-XX` |
| Max residual | — | `X.XXe-XX` |

## Logs

- **Solver log:** `logs/mesh_N.log`
- **Mesh quality:** `outputs/mesh_N/checkMesh.log`
- **Validation JSON:** `outputs/mesh_N/validation.json`
- **Environment:** `outputs/mesh_N/environment.log`

## Notes

- **Decision:** (e.g., mesh passes acceptance, mesh failed due to divergence)
- **Risk:** (e.g., coarse mesh may not capture boundary layer)
- **Next:** (e.g., proceed to mesh_N+1, re-run with refined mesh)
