---
name: harness-engineering
description: >-
  Turn complex multi-step research into durable, agent-readable artifacts.
  Inspired by OpenAI's Harness Engineering (2026): the repo is durable memory,
  AGENTS.md is a map not an encyclopedia, taste invariants encode standards as
  executable checks, entropy management prevents decay.
  TRIGGER ON: long-running experiments, CFD/ML/PINN validation, ablation
  studies, hyperparameter sweeps, multi-step coding plans, benchmark execution,
  paper-grade reproducibility verification, or any task where "I need to
  record this so I can come back later." Also trigger when user mentions
  "做实验", "跑仿真", "复现", "验证", "记录决策", "paper 提交".
  DO NOT use for one-off scripts, pure exploration without persistence, or
  tasks that produce no durable output.
---

# Harness Engineering

**Inspired by OpenAI's Harness Engineering article (Feb 2026).**
Core insight: the scaffold around the work matters more than the work itself.
For scientific research, this means the experiment framework, validation gates,
and documentation structure are what make results reproducible and reliable.

## Core Philosophy

Five principles, adapted from OpenAI's practice to research:

| Principle | In OpenAI's words | In research terms |
|-----------|------------------|-------------------|
| **Repo is durable memory** | "Codex can't see what's not in the repo" | If it's not in the repo (commit, plan, log, result), it doesn't exist |
| **Map, not encyclopedia** | "Give Codex a map, not a 1000-page manual" | AGENTS.md is a ~100-line directory; details live in docs/ |
| **Constraints over instructions** | "Taste invariants enforced by linters" | Encode experiment standards as executable scripts, not prose reminders |
| **Observability is the feedback loop** | "Codex queries LogQL/PromQL directly" | Structured logs + check scripts let agents self-verify experiments |
| **Entropy must be collected** | "Background cleanup agents fix tech debt" | Regular archiving, pruning, and documentation updates prevent decay |

## 1. Progressive Disclosure (Map, Not Encyclopedia)

AGENTS.md must stay lean. It serves as a table of contents, pointing to
deeper documentation:

```
docs/harness/               # All harness artifacts live here
├── active/                 # Current experiment plans
│   └── YYYY-MM-DD-topic.md
├── completed/              # Archived plans and logs
├── decisions/              # Decision records (what, why, outcome)
├── templates/              # Reusable plan/validation templates
├── reports/                # Validation summaries, paper figures
└── references/             # Domain standards (JCP, JFM conventions)
```

Rules:
- AGENTS.md: only project-wide conventions and stable commands.
- Task-specific plans go in `docs/harness/active/`.
- Completed plans move to `docs/harness/completed/` — never delete.
- Decision records answer: what was tried, what passed/failed, what changed.

## 2. Taste Invariants (Encode Standards as Checks)

A "taste invariant" is a standard you encode as an executable rule so it's
enforced on every experiment, not just remembered. The goal: reduce
"please remember to X" prose and replace it with a script that checks X.

**Examples of research taste invariants:**

| Standard | Prose version (bad) | Executable version (good) |
|----------|--------------------|--------------------------|
| Random seeds | "Please record all seeds" | Script checks `seed` appears in every config |
| Convergence | "Make sure residuals are low" | Script checks `loss < 1e-4` in training log |
| Figures | "Label your axes" | Script checks figure dirs have captions.txt |
| Data split | "Report train/val/test split" | Script checks split ratios sum to 1.0 |

When a review comment or failed experiment reveals a missing standard:
1. Write the check script (or add an assertion).
2. Add it to `scripts/check-harness.sh`.
3. The standard is now encoded — enforced forever, never forgotten.

> **Why this matters:** A standard that isn't enforced will be violated.
> OpenAI found this repeatedly: "fix the harness, not the output."
> In research, this means: fix the experiment framework, not the specific run.

## 3. Repo as Single Source of Truth

Everything needed to understand, reproduce, and extend an experiment must be
in the repository. Knowledge in chat history, email, notebooks, or your head
is invisible to future agents (and future you).

**What must be in the repo:**
- Experiment plans with exact commands
- Configuration files (hyperparameters, mesh settings, solver options)
- Validation summaries with pass/fail and metrics
- Decision records with context
- Results in structured, queryable form (CSV/JSON, not screenshots)
- Paper figures with source data

**What stays out of git:**
- Raw logs, checkpoints, large output binaries → `.gitignore`-d
- Intermediate results that can be regenerated
- Sensitive data (API keys, tokens)

**For each experiment, create a structured directory:**

```
experiments/rank_sweep/
├── README.md              # Objective + status summary
├── configs/
│   ├── rank1.yaml
│   └── rank2.yaml
├── docs/
│   ├── plan.md            # What we intend to do
│   └── results.md         # What happened + decision
├── outputs/               # .gitignore-d
│   ├── rank1_seed42/
│   └── rank2_seed42/
└── scripts/
    └── run.sh             # Reproducible launch command
```

## 4. Experiment Workflow

A six-stage workflow for any complex experiment:

```
Plan → Setup → Execute → Validate → Decide → Archive
```

### Stage 1: Plan
Create a plan artifact (`docs/harness/active/YYYY-MM-DD-topic.md`):

```markdown
# Objective: [one line]
## Plan
1. `python train.py --rank 1 --seed 42`
2. `python train.py --rank 2 --seed 42`
## Acceptance
- Train loss < 1e-4 for all ranks
- Wall time recorded per run
## Resume
Rerun skips existing output dirs (checkpoint-aware).
```

### Stage 2: Setup
- Generate configs, mesh, data splits.
- Run `scripts/check-harness.sh setup` to verify preconditions.

### Stage 3: Execute
- Use deterministic output paths: `outputs/{config}_{seed}/`.
- Log full command and commit SHA.
- Support `--resume` — re-running skips completed steps.

### Stage 4: Validate
Run checks against acceptance criteria:
- Loss convergence, residual history, NaN detection.
- Compare against baselines or prior results.
- If validation fails → log the failure, decide whether to fix or abort.

### Stage 5: Decide
Record in the plan artifact:
```
## Decision
- What was tried:
- What passed:
- What failed:
- What changed:
- Commit: abc1234
- Next:
```

### Stage 6: Archive
- Move plan from `active/` to `completed/`.
- Ensure all data files are documented (even if not committed).
- Close or update the task.

## 5. Dual-Agent Verification

For critical experiments (paper-grade results, ablation studies),
use a **verifier agent independent of the executor agent**:

1. **Executor agent** writes and runs the experiment.
2. **Verifier agent** (separate context, no shared history) reviews:
   - Are the configs consistent with the plan?
   - Are the reported metrics derivable from the raw logs?
   - Are the failure cases correctly categorized?
   - Are the claimed conclusions supported by the evidence?

Spawn the verifier as a subagent with the plan artifact only — no
conversation history from the execution phase.

> **Why:** OpenAI found that "verification must be independent."
> The executor will naturally interpret ambiguous results in its favor.
> An independent verifier catches this.

## 6. Entropy Management

Research repositories decay. Code rots, docs go stale, experiments go
unarchived. Fight this with periodic cleanup.

Read `references/entropy-checklist.md` for the full list. Key items:

- **Weekly** (during idle time): archive completed experiments, prune
  orphaned output directories, update AGENTS.md if conventions changed.
- **Per-milestone**: run full `scripts/check-harness.sh audit` to verify
  experiment integrity (no missing configs, no unrecorded decisions).
- **Per-paper-submission**: full reproducibility audit — can every figure
  be regenerated from the committed code+configs?

## 7. Validation Templates

### Standard Template

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

### CFD-Specific Fields

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

### Claim Scoping

Distinguish three evidence levels in paper claims:

| Level | Meaning | Label |
|-------|---------|-------|
| **Workflow validity** | Pipeline runs end-to-end | "demonstrate" |
| **Numerical trend agreement** | Qualitative match to reference | "consistent with" |
| **Experimental validation** | Quantitative match to ground truth | "validated" |

Never present a lower-level claim as higher-level.

## 8. When NOT to Use This Skill

| Skip harness-engineering when... | Instead... |
|---|---|
| Writing a single throwaway script | Just write and run it |
| Quick exploratory data analysis | Notebook, save only findings |
| Task completes in one session with no follow-up | No artifact needed |
| Debugging a simple bug | Fix and commit directly |

If unsure: "Would it be useful to resume this next week?" If yes, use it.

## Reference Files

- `references/taste-invariants.md` — Templates for encoding experiment
  standards as executable checks. Read when adding new invariants.
- `references/entropy-checklist.md` — Cleanup checklists for entropy
  management. Read when running periodic maintenance.
- `scripts/check-harness.sh` — Experiment integrity check script.
  Run via `bash scripts/check-harness.sh` to verify current state.

## Updating AGENTS.md

- Add only project-wide conventions or stable commands.
- Link to task-specific docs in `docs/harness/active/`.
- Remove stale temporary notes after archiving.
- Checklist: is this needed in *every* session? If not, put it elsewhere.
