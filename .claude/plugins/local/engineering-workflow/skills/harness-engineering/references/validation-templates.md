# Validation Templates

Use these templates for experiment validation and paper-grade verification.

## Standard Validation

```markdown
# Validation Status

## Command
`python train.py --epochs 1000 --seed 42`

## Result
- Status: passed / failed / partial
- Commit: `<sha>`
- Date: `YYYY-MM-DD`
- Output: `outputs/run_name/`

## Acceptance
- Criterion A (e.g. loss < 0.01): passed (0.008) / failed (0.05)
- Criterion B (e.g. wall time < 1hr): passed (42m) / failed (73m)

## Logs
- Main: `outputs/run_name/training.log`
- Error: `outputs/run_name/error.log`

## Notes
- Decision:
- Next:
```

## CFD-Specific Fields

Add when applicable:

```markdown
## Mesh Quality
- Cells: 1.2M
- Max aspect ratio: 847
- Max non-orthogonality: 63.4
- Max skewness: 3.8
- checkMesh: Mesh OK.

## Convergence
- Final time reached: yes/no
- Residuals: <1e-6
- Continuity: satisfied
```

## Claim Scoping

Distinguish three evidence levels in paper claims:

| Level | Meaning | Label |
|-------|---------|-------|
| **Workflow validity** | Pipeline runs end-to-end | "demonstrate" |
| **Numerical trend agreement** | Qualitative match to reference | "consistent with" |
| **Experimental validation** | Quantitative match to ground truth | "validated" |

Never present a lower-level claim as higher-level.
