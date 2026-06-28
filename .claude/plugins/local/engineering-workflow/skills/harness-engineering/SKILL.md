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

**Core insight:** the scaffold around the work matters more than the work itself.
For scientific research, this means the experiment framework, validation gates,
and documentation structure are what make results reproducible and reliable.

## Fast Path — Start Here

Before diving into the full workflow, ask: **does this task need the full harness?**

| Task type | Use |
|-----------|-----|
| Quick script, one-off analysis, simple debug | **Skip harness.** Just code, run, commit. |
| Planned experiment (ranks, seeds, sweeps) | **Full workflow below.** Create plan artifact. |
| Results review / claim verification | **Dual-agent mode.** Spawn verifier agent. |
| Cleanup stale experiments | **Entropy mode.** Read entropy-checklist.md. |

If unsure: "Would I need to resume this next week?" If yes, full workflow.

## Five Principles

| Principle | In research terms |
|-----------|-------------------|
| **Repo is durable memory** | If it's not committed, it doesn't exist |
| **Map, not encyclopedia** | SKILL.md is lean; details in reference files |
| **Constraints over instructions** | Encode standards as check scripts, not prose |
| **Observability is feedback** | Structured logs let agents self-verify |
| **Entropy must be collected** | Archive completed experiments; prune stale state |

## Experiment Workflow

### 1. Plan
Create `docs/harness/active/YYYY-MM-DD-topic.md` with: objective, numbered steps, acceptance criteria, resume policy.

### 2. Setup
Generate configs, data splits, mesh. Run `scripts/check-harness.sh setup`.

### 3. Execute
Deterministic output paths: `outputs/{config}_{seed}/`. Log commit SHA. Support `--resume`.

### 4. Validate
Check acceptance criteria: loss convergence, NaN detection, metrics vs baselines.

### 5. Decide
Record in plan: what was tried, passed, failed, changed, commit SHA, next step.

### 6. Archive
Move plan from `active/` to `completed/`. Document data files. Close task.

## Directory Structure

```
docs/harness/           # All harness artifacts
├── active/             # Current experiment plans
├── completed/          # Archived plans + logs
├── decisions/          # Decision records
└── templates/          # Plan/validation templates
experiments/<name>/
├── README.md           # Objective + status
├── configs/            # YAML/JSON configs
├── docs/               # Plan + results
├── outputs/            # .gitignore-d
└── scripts/            # run.sh, check scripts
```

## Taste Invariants

A standard you encode as a check script so it's enforced forever, not just remembered.
When a review comment reveals a missing standard:

1. Write the check script (bash/Python — see `references/taste-invariants.md`).
2. Register it in `scripts/check-harness.sh`.
3. The standard is now enforced — remove the prose reminder.

> **Why:** A standard that isn't enforced will be violated. Fix the harness, not the output.

## Dual-Agent Verification

For paper-grade results, spawn an **independent verifier** (subagent, no shared history):

1. **Executor** runs the experiment.
2. **Verifier** reviews plan artifact only: config consistency, metric derivability, failure categorization, claim vs evidence.

Use `references/validation-templates.md` for claim scoping (Level 1: demonstrate, Level 2: consistent with, Level 3: validated).

## Entropy Management

Research repos decay. See `references/entropy-checklist.md` for full checklists.

Core actions:
- **Weekly**: archive completed experiments, prune orphaned outputs, run `check-harness.sh audit`.
- **Milestone**: verify all plans have results, all decisions have SHAs, no uncommitted configs.
- **Pre-submission**: full reproducibility audit — every figure traceable to committed code.

## API Surface for Loop Engineering

This section documents the explicit interface that Loop Engineering and other
orchestration layers use to consume Harness infrastructure:

| Component | File | What it provides | Consumed by loop as |
|-----------|------|------------------|-------------------|
| **State file convention** | `STATE.md` at project root | Cycle memory: what's done, what broke, what's next | Loop's Step 2 (State File) |
| **Check scripts** | `scripts/check-harness.sh` | Integrity verification, setup, audit | Gate verification step |
| **Validation templates** | `references/validation-templates.md` | Claim levels + verification checklists | Gate criteria |
| **Plan artifacts** | `docs/harness/active/` | Structured experiment plans | Loop's context initialization |
| **Taste invariants** | `references/taste-invariants.md` | Enforceable standards as executable checks | Gate automation |
| **Entropy checklist** | `references/entropy-checklist.md` | Cleanup procedures | Loop teardown / archive |

**Contract:**
- Loop Engineering calls `scripts/check-harness.sh` for gate verification — it must exit 0 for pass, non-zero for fail
- Loop writes `STATE.md` per the state file convention documented in harness references
- Loop uses harness validation templates for verifier gates (claim scoping levels)
- Harness provides but does not mandate the directory structure — loop may extend it

## When NOT to Use

| Skip when... | Instead... |
|---|---|
| One-off script | Write and run |
| Quick EDA | Notebook, save findings |
| Single-session task, no follow-up | No artifact needed |
| Simple bug fix | Fix and commit |

## Reference Files

- `references/taste-invariants.md` — Templates for encoding standards as checks
- `references/entropy-checklist.md` — Cleanup checklists
- `references/validation-templates.md` — Templates + claim scoping
- `scripts/check-harness.sh` — Integrity check script
