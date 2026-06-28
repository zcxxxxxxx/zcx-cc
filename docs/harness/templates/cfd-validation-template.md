# CFD Validation Template — Per-Mesh Report

Use this template to document each mesh run in a CFD sweep.

```markdown
## Mesh: {mesh_name}

### Mesh Quality
| Metric | Value | Acceptable |
|--------|-------|------------|
| Cells | | |
| Max aspect ratio | | < 1000 |
| Max non-orthogonality | | < 70 |
| Max skewness | | < 4 |
| checkMesh | | OK |

### Setup
- Airfoil: {airfoil}
- Grid: {structured/unstructured, resolution}
- Solver: simpleFoam + kOmegaSST
- Reynolds number: 1e6
- Max iterations: 5000
- Commit SHA: {sha}

### Convergence
| Field | Final Residual | Threshold | Status |
|-------|---------------|-----------|--------|
| Ux | | 1e-6 | |
| Uy | | 1e-6 | |
| p | | 1e-6 | |
| k | | 1e-6 | |
| omega | | 1e-6 | |

### Performance
- Wall-clock time:
- Iterations to converge:
- Final time reached:

### Decision
- Status: PASS / FAIL
- Notes:
```
