# Experiment Artifact Templates

Inspired by OpenSpec's structured artifact model (proposal → specs → design → tasks),
adapted for computational research experiments (CFD/PINN/ML).

## Artifact Flow

```
experiment-plan.md  ──►  configs/specs  ──►  experiment-design.md  ──►  tasks.md
     │                       │                       │                       │
  intent + scope         what we're               how it's set            execution
  + hypothesis           testing                  up + decisions           steps
```

Dependencies are **enablers, not gates** — you can update any artifact at any time.

---

## 1. Experiment Plan (`experiments/<name>/docs/experiment-plan.md`)

The "why" and "what" — intent, scope, hypothesis.

```markdown
# Experiment Plan: <name>

## Intent
<one-paragraph: what problem are we investigating>

## Hypothesis
<what we expect to find. Be specific enough that a machine can check the outcome>

## Scope
### In Scope
- <specific configs/parameters to test>
- <specific metrics to compare>

### Out of Scope
- <what we explicitly NOT doing>

## Success Criteria
1. <quantifiable criterion 1 — e.g., "loss < 1e-5">
2. <quantifiable criterion 2>
3. <minimum viable result that makes this experiment worthwhile>

## Resume Policy
- Safe to resume from: <which outputs/checkpoints>
- Must re-verify: <which steps need re-validation>
```

---

## 2. Config Specs (`experiments/<name>/configs/`)

The "what we're testing" — parameter definitions, sweep ranges, baseline config.
Each config file IS the spec: structured data (YAML/JSON) rather than prose.

```yaml
# configs/baseline.yaml
description: "Baseline configuration"
params:
  learning_rate: 1e-3
  batch_size: 32
  epochs: 100

# configs/sweep.yaml  
description: "Learning rate sweep"
sweep:
  parameter: learning_rate
  values: [1e-2, 1e-3, 1e-4, 1e-5]
```

**Convention:** Each config file at `configs/<name>.yaml` IS a spec. The
`configs/` directory collectively defines the experimental parameter space.

---

## 3. Experiment Design (`experiments/<name>/docs/experiment-design.md`)

The "how" — technical setup details, architecture decisions, data flow.

```markdown
# Experiment Design: <name>

## Setup
- **Mesh/Data source:** <path>
- **Solver/Model:** <name + version>
- **Hardware:** <GPUs, nodes>

## Architecture Decisions

### Decision: <solver choice, model architecture, etc.>
- **Option considered:** <alternatives>
- **Chosen:** <this one>
- **Reason:** <why>

### Decision: <metric choice>
- **Chosen:** <which metric>
- **Why:** <rationale>

## Data Flow
<how data moves from input → processing → output — a short description or diagram>

## File Changes
- <new files>
- <modified files>
```

---

## 4. Tasks (`experiments/<name>/docs/tasks.md`)

The execution checklist — concrete, numbered, checkable steps.

```markdown
# Tasks: <name>

## 1. Setup
- [ ] 1.1 Generate config files for all sweep parameters
- [ ] 1.2 Prepare input data / mesh
- [ ] 1.3 Run `scripts/check-harness.sh setup`

## 2. Execution
- [ ] 2.1 Run baseline config
- [ ] 2.2 Run sweep configs
- [ ] 2.3 Verify all runs completed (check logs for errors)

## 3. Analysis
- [ ] 3.1 Extract metrics from all runs
- [ ] 3.2 Compare against baseline
- [ ] 3.3 Generate summary table

## 4. Archive
- [ ] 4.1 Update STATE.md with results
- [ ] 4.2 Archive experiment plan to completed/
- [ ] 4.3 Commit configs and docs
```
