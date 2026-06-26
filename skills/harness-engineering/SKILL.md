---
name: harness-engineering
description: Turn complex multi-step work into durable repository artifacts — plans, logs, validation records, decision logs, and handoff summaries that future agents (or future you) can resume without chat history. TRIGGER ON: long-running experiments, CFD/ML/PINN validation, paper-grade reproducibility verification, ablation studies, hyperparameter sweeps, multi-step coding plans, benchmark execution, any task where "I need to record this so I can come back later", or when generating reproducibility documentation. Also trigger when the user mentions "做实验" (running experiments), "跑仿真" (simulation), "复现" (reproduce), "验证" (validation/verification), "记录决策" (recording decisions), or "paper 提交" (paper submission). DO NOT use for one-off scripts, pure exploration without persistence, or tasks that produce no durable output.
---

# Harness Engineering

Turn ad-hoc agent workflows into durable project harnesses: plans, logs, validation gates, and follow-up tasks live in the repository and can be resumed by another agent — or by you, weeks later — without relying on conversation memory.

The inspiration is OpenAI's Harness Engineering article. The core insight: **the repo is the durable memory.** Keep it there, not in chat history.

## Core Rules

### 1. Repo as durable memory
Write long-lived plans, commands, validation summaries, and next steps to **tracked** Markdown or code files. Do not write them only in conversation or in `outputs/` ignored directories.
> **Why:** Chat history is ephemeral — it disappears when the context window fills or the session ends. Tracked files survive indefinitely and are indexable by grep, search, and future agents.

### 2. Keep AGENTS.md concise
Use AGENTS.md only for global project orientation: conventions, branch rules, stable commands, and pointers to deeper docs. Do not dump experiment logs, temporary notes, or detailed plans there.
> **Why:** AGENTS.md must be loadable in every session. A bloated file wastes context and hides truly important information. Task-specific details belong in their own files.

### 3. Convert instructions into executable checks
Prefer scripts, CLI entry points, and automated tests over prose-only rules. If a validation step can be scripted, script it.
> **Why:** Prose is ambiguous and rots. Scripts either pass or fail — they don't need interpretation. This is especially important for agents, which interpret prose differently than humans do.

### 4. Summarize evidence in tracked files; logs stay ignored
Save raw logs, checkpoints, and bulk outputs under `.gitignore`-d paths. But extract and record the key metrics, pass/fail decisions, and failure reasons in a tracked Markdown file.
> **Why:** Git is not a data lake. Committing 500MB of OpenFOAM processor directories or PyTorch checkpoints destroys clone times and disk usage. But without a summary, the result is invisible — the summary is what makes the work durable.

### 5. Record decisions with context
When you try something new, record: what was tried, what passed, what failed, what changed, and what remains. Include the exact command line and the commit SHA.
> **Why:** Future agents have zero context about what happened in this session. A well-structured decision record is their equivalent of "I tried X, it failed because Y, so I switched to Z." Without it, they'll repeat your failures.

### 6. Make long-running jobs resumable
Design experiment scripts so that re-running them skips completed steps and preserves failure logs. Use flags like `--resume`, checkpoint files, or output-directory existence checks.
> **Why:** Experiments fail at step 45 of 50. Without resume support, fixing the issue and restarting means throwing away 44 steps of computation. With it, you rerun and it picks up at step 45.

## Workflow

1. **Identify the durable artifact needed.**
   - **Global project guidance** → put in AGENTS.md
   - **Task-specific plan or log** → put in e.g. `docs/harness/YYYY-MM-DD-topic.md`
   - **Validation record** → put in a tracked paper/experiment directory

2. **Create or update a plan artifact.**
   Include: objective, exact commands, acceptance criteria, expected outputs, resume behavior, known risks.

   **Good example:**
   ```markdown
   # Objective: LoRA rank sweep for Burgers PEFT-PINN
   ## Plan
   1. `python train.py --rank 1 --seed 42 --epochs 1000`
   2. `python train.py --rank 2 --seed 42 --epochs 1000` (same, higher rank)
   ## Acceptance
   - Train loss < 1e-4 for all ranks
   - Wall time recorded per run
   ## Resume
   Rerun skips existing output directories.
   ```

   **Bad example (no resume info, no acceptance criteria):**
   ```markdown
   # TODO: run LoRA sweep
   - try different ranks
   - see what happens
   ```

3. **Run the work with logs.**
   Use deterministic output directory names (e.g. `outputs/rank1_seed42/`). Save the full command line in the tracked plan so it's reproducible.

4. **Validate with encoded checks.**
   - Unit tests → `pytest tests/`
   - CLI dry-runs → `python train.py --dry-run`
   - CFD mesh → `checkMesh` metrics
   - Convergence → residual history, final loss values
   - CSV integrity → row counts, NaN checks, schema validation

5. **Summarize the result in a tracked artifact.**
   Record: exact status, important metrics, failure reasons, paths to ignored logs, and next actions. Use the template below.

6. **Commit only durable source/docs.**
   Do not commit: large output directories, OpenFOAM processor dirs, time-step results, raw bulk logs, `__pycache__`, checkpoints. Do commit: plans, summaries, validation records, decision logs, scripts, and configuration files.

## When NOT to use this skill

| Skip harness-engineering when... | Instead... |
|---|---|
| Writing a single throwaway script | Just write and run it |
| Quick exploratory data analysis | Use a notebook, save only findings |
| The task completes in one session with no follow-up | No artifact needed |
| Debugging a simple bug | Fix and commit directly |

If you're unsure, ask yourself: "Would it be useful to resume this from a different machine next week?" If yes, use the harness.

## Validation Evidence Template

Use this in a tracked Markdown file when preserving results. Fields marked `[CFD-specific]` can be omitted for ML-only experiments.

```markdown
# Validation Status

## Command
`PYTHONPATH=... python train.py --epochs 1000 ...`

## Result
- Status: passed / failed / partial
- Commit: `<short-sha>`
- Date: `YYYY-MM-DD`
- Output directory: `reproduction/experiment/outputs/run_name/`

## Acceptance
- Criterion A (e.g. test loss < 0.01): passed (0.008) / failed (0.05)
- Criterion B (e.g. wall time < 1hr): passed (42m) / failed (73m)

## Logs
- Main log: `outputs/run_name/training.log`
- Failure log: `outputs/run_name/error.log`

## Notes
- Decision:
- Risk:
- Next:
```

For CFD/ML mixed experiments, add these [CFD-specific] fields:

```markdown
## Mesh Quality [CFD-specific]
- Cells: 1.2M
- Max aspect ratio: 847
- Max non-orthogonality: 63.4
- Max skewness: 3.8
- checkMesh: Mesh OK.

## Convergence [CFD-specific]
- Final time reached: yes/no
- Residuals: <1e-6 at final iteration
- Continuity: satisfied
```

## Paper-Grade CFD/ML Harness

For CFD, Geo-FNO, PINN, and optimization validation in academic papers:

- **Stage separation**: Keep geometry generation, mesh generation, solver execution, surrogate training, and optimization as separate resumable stages. Each stage should be independently verifiable and restartable.
- **Mesh quality [CFD-specific]**: Record `checkMesh` metrics — cells, max aspect ratio, max non-orthogonality, max skewness, and `Mesh OK.` verdict. A bad mesh invalidates all downstream CFD claims.
- **Solver convergence [CFD-specific]**: Record force coefficient availability, final time reached, and residual/continuity trends. Diverged solvers are not evidence for flow-field claims.
- **Surrogate evidence**: Record separately from CFD evidence: dataset size, train/val/test split strategy, error metrics (relative L2, max error), and optimization objective. Do not conflate surrogate accuracy with CFD accuracy.
- **Failed cases**: Preserve as evidence when they define feasibility boundaries (e.g., "rank-1 LoRA does not converge for Nu > 0.1"). But do not present failures as positive aerodynamic claims.
- **Claim scoping**: Distinguish three levels — *workflow validity* (the pipeline runs end-to-end), *numerical trend agreement* (qualitative match), and *experimental validation* (quantitative match to ground truth). Paper claims must be scoped to their evidence level.

## When Updating AGENTS.md

- Add only project-wide conventions or stable commands that every session needs.
- Link to deeper task-specific docs in `docs/harness/` instead of embedding long histories.
- Remove stale temporary notes after converting them to tracked plans, scripts, or validation records.
- **Checklist before adding to AGENTS.md:** Is this information needed in *every* session? If not, put it in a task-specific file.
