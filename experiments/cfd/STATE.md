# Loop State — CFD Turbulence Simulation Batch

**Status:** running

**Cycle info:**
- Started: 2026-06-28T00:00:00+00:00
- Last run: (not yet run)
- Iterations: 0
- Cost (est.): $(not yet tracked)

**Progress:**
- [ ] mesh_1: NACA0012 (32,768 cells) — pending
- [ ] mesh_2: NACA0012 coarse (8,192 cells) — pending
- [ ] mesh_3: NACA0012 fine (131,072 cells) — pending
- [ ] mesh_4: RAE2822 (32,768 cells) — pending
- [ ] mesh_5: RAE2822 unstructured (50,000 cells) — pending
- [ ] mesh_6: NACA4412 (32,768 cells) — pending
- [ ] mesh_7: S809 (51,200 cells) — pending
- [ ] mesh_8: DU93-W-210 (51,200 cells) — pending

**Failures (last cycle):**
- (none yet)

**Next step:**
Run `python scripts/run_loop.py` from the `experiments/cfd/` directory to process all 8 meshes sequentially. Each mesh: (1) set up OpenFOAM case from templates, (2) run simpleFoam (k-omega SST, Re=1e6, max 5000 iterations), (3) check all residuals < 1e-6. On divergence: retry once with URF=0.3. On retry failure: mark FAIL and continue. Results go to `outputs/summary.md` and `outputs/summary.csv`. Expected total time: 4-8 hours on 4 cores. For single-mesh test: `bash scripts/run_single.sh --mesh mesh_1`.

---

## Hard Stop Conditions

| Limit | Value | Action on breach |
|-------|-------|------------------|
| **Iteration limit (per mesh)** | 5,000 solver iterations | Stop solver for that mesh, evaluate convergence |
| **Retry limit (per mesh)** | 1 retry only | Skip mesh, log to STATE.md, continue to next |
| **Wall-clock (per mesh)** | 48 hours | Kill solver process, mark ERROR, move to next |
| **Wall-clock (total batch)** | 7 days | Hard abort entire run, preserve partial results |
| **Max consecutive failures** | 3 meshes | Pause loop, notify operator |
| **Divergence (per run)** | NaN/Inf/residual spike > 10 | Trigger retry immediately (don't wait for max iterations) |
| **Post-retry divergence** | 1 | Skip mesh permanently, record skip reason in summary.md |

## Escalation Ladder

```
Level 1 — 1st divergence per mesh:    auto-retry with URF=0.3
Level 2 — Retry also diverges:        mark mesh FAIL, log reason, continue to next mesh
Level 3 — 3+ consecutive mesh fails:  pause loop, wait for operator review
```
