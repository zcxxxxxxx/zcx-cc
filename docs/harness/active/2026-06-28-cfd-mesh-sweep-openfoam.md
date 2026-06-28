# CFD Mesh Sweep — OpenFOAM k-omega SST at Re=1e6

**Objective:** Evaluate convergence behavior of OpenFOAM's k-omega SST solver across 8 meshes (varying airfoil geometry, grid type, and resolution). Verify that residuals drop below 1e-6 for every mesh.

**Status:** IN_PROGRESS

---

## Mesh Inventory

| # | File | Airfoil | Grid Type | Resolution / Cells |
|---|------|---------|-----------|-------------------|
| 1 | `mesh_1.msh` | NACA0012 | Structured | 256 x 128 |
| 2 | `mesh_2.msh` | NACA0012 | Structured (coarse) | 128 x 64 |
| 3 | `mesh_3.msh` | NACA0012 | Structured (fine) | 512 x 256 |
| 4 | `mesh_4.msh` | RAE2822 | Structured | 256 x 128 |
| 5 | `mesh_5.msh` | RAE2822 | Unstructured | ~50k cells |
| 6 | `mesh_6.msh` | NACA4412 | Structured | 256 x 128 |
| 7 | `mesh_7.msh` | S809 (wind turbine) | Structured | 320 x 160 |
| 8 | `mesh_8.msh` | DU93-W-210 (wind turbine) | Structured | 320 x 160 |

**Solver config:** `kOmegaSST` turbulence model, `Re = 1e6`, incompressible steady-state (`simpleFoam`).

---

## Plan (Numbered Steps)

1. **Preprocess** — Convert `.msh` to OpenFOAM polyMesh format with `ideasUnvToFoam` or `gmshToFoam`. Run `checkMesh` on each, record mesh quality stats (cells, aspect ratio, non-orthogonality, skewness).
2. **Configure** — Generate per-mesh `system/controlDict`, `system/fvSchemes`, `system/fvSolution`, and `constant/turbulenceProperties` with k-omega SST parameters at Re=1e6.
3. **Run** — Execute `simpleFoam` for each mesh. Log output to `outputs/{mesh_name}/`. Enforce residual report every 100 iterations. Max iterations: 5000.
4. **Monitor** — Tail residuals for: `Ux`, `Uy`, `p`, `k`, `omega`. Flag any divergence or NaN early.
5. **Validate** — Extract final residuals per mesh. Check all < 1e-6.
6. **Tabulate** — Compile results matrix: mesh name, cells, iterations to converge, final residuals, wall-clock time.
7. **Archive** — Move plan to `docs/harness/completed/`. Commit all configs and results.

---

## Acceptance Criteria

| Criterion | Threshold | Measured |
|-----------|-----------|----------|
| Mesh conversion | All 8 meshes convert without error | |
| checkMesh pass | All meshes pass checkMesh | |
| Solver stability | No NaN/divergence in any run | |
| Residual Ux | < 1e-6 | |
| Residual Uy | < 1e-6 | |
| Residual p | < 1e-6 | |
| Residual k | < 1e-6 | |
| Residual omega | < 1e-6 | |
| Wall-clock per mesh | < 4 hours | |

---

## Results Matrix

| Mesh | Cells | checkMesh | Iterations | Residual Ux | Residual Uy | Residual p | Residual k | Residual omega | Wall time | Status |
|------|-------|-----------|------------|-------------|-------------|------------|-------------|----------------|-----------|--------|
| 1 | | | | | | | | | | PENDING |
| 2 | | | | | | | | | | PENDING |
| 3 | | | | | | | | | | PENDING |
| 4 | | | | | | | | | | PENDING |
| 5 | | | | | | | | | | PENDING |
| 6 | | | | | | | | | | PENDING |
| 7 | | | | | | | | | | PENDING |
| 8 | | | | | | | | | | PENDING |

---

## Resume Policy

- If a mesh run crashes (OOM, segfault), check logs, fix config, re-run that mesh only.
- If a mesh fails to converge in 5000 iters, re-run with `potentialFoam` initialisation, then `simpleFoam` with under-relaxation.
- Partial results are preserved in `outputs/{mesh_name}/`. Use `--resume` flag to skip completed meshes.

---

## Commit Log

| Date | SHA | Action |
|------|-----|--------|
| 2026-06-28 | | Plan created |
