# CFD Turbulence Simulation Loop — Design Document

## Problem

8 mesh files (mesh_1 through mesh_8) in `experiments/cfd/meshes/` each need a k-omega SST turbulence simulation at Re=1e6. Manual submission is tedious and error-prone. Each run must:
1. Complete without divergence
2. Converge residuals below 1e-6
3. Results aggregated for comparison

## Solution: Automated Loop

A Python-based batch automation system that processes meshes sequentially with built-in convergence monitoring and auto-retry.

## Architecture

Three layered scripts:

| Script | Role |
|--------|------|
| `scripts/run_loop.py` | Main orchestrator — loop, convergence check, retry, summary |
| `scripts/run_single.sh` | Bash wrapper for single-mesh runs |
| `scripts/check_convergence.py` | Standalone log parser and convergence evaluator |

## Decision Record

| Decision | Rationale |
|----------|-----------|
| Python over bash | Complex logic (regex parsing, JSON, conditional retry) is more maintainable |
| Sequential processing | Avoids resource contention; simpler failure isolation |
| YAML config | Tunable without code changes |
| Per-mesh JSON checkpoint | Resume-safe after interruption |
| Single retry with relaxed URF | Standard CFD practice; one retry sufficient in most cases |

## Retry Protocol

1. Initial run with default under-relaxation factors (U=0.7, p=0.3, k=0.7, omega=0.7)
2. If diverged: relax URF to 0.3 (U/k/omega) and 0.15 (p)
3. Maximum 1 retry per mesh
4. If retry also fails: mark as FAIL with diagnostic message

## Convergence Definition

A simulation is considered converged when ALL of:
- No NaN/Inf/divergence in solver log
- All field final residuals < 1.0e-6
- Residuals not stagnant for 200+ consecutive iterations

## Failure Modes Handled

- Solver not installed (exit code 127)
- Mesh file missing (skip with ERROR)
- Solver crash (retry)
- NaN/Inf in solution (divergence detection -> retry)
- Residual spike (initial > 10.0 -> divergence)
- Residual stagnation -> FAIL
- Increasing residual trend -> FAIL
- Interrupted execution (resume-safe)

## Verification

```bash
# Dry run
python scripts/run_loop.py --dry-run

# Check a mock log
python scripts/check_convergence.py path/to/log --json
```
