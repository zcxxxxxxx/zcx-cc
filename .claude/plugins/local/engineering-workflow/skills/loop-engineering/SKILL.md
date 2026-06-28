---
name: loop-engineering
description: >-
  Build autonomous, self-sustaining task loops. Instead of one-shot prompts,
  design systems that iterate through "trigger → execute → verify → retry →
  escalate" cycles.

  TRIGGER ON: "set up a loop", "run automatically", "定时跑", "自动化流程",
  "批量处理", "auto-retry", "无人值守", "self-healing", "持续验证",
  "goal-driven execution", "循环执行", "run unattended", /loop, /goal,
  /schedule. Also trigger for experiment sweeps, nightly batch jobs, parameter
  scans, data pipelines, or any repetitive workflow where "keep running until
  condition X."

  DO NOT trigger for one-shot prompts, single-session debugging, tasks needing
  human judgment at every step (auth code, payment logic, architecture decisions),
  or anything the user plans to supervise in real-time.
---

# Loop Engineering

**Core insight:** the hands-off loop matters more than the one-shot prompt.
Instead of micromanaging each AI interaction, design a closed-loop system
that autonomously executes, verifies, retries, and only escalates to you
when stuck.

## Cost-Aware Fast Path

Before diving into the full 5-step method, check: **is this a single-domain task?**

| Task scope | What to do | Why |
|------------|-----------|-----|
| **Pure harness** (just experiment setup, no loop) | Run `harness-engineering` only. No loop design needed. | Saves 50%+ tokens by skipping loop logic |
| **Pure loop** (just a loop design, no experiment infra) | Run this skill but skip harness cross-references. Use flat STATE.md, no `docs/harness/` needed. | Harness scaffolding is unused when no long-term experiment tracking is needed |
| **Full stack** (loop + experiment infra) | Use the full 5-step method below + harness integration section at bottom | Both tiers earn their token cost |

> **Test data:** single-domain tasks score 100% without the other skill. Only full-stack
> tasks benefit from the combined workflow. If in doubt, start with the minimal approach
> and escalate only when the task requires both orchestration AND infrastructure.

## Where This Fits

Loop Engineering is the **orchestration layer** in a three-tier stack:

```
Loop Engineering    — autonomous cycles: trigger → execute → verify → retry
Superpowers         — session-level collaboration patterns (TDD, review, debug)
Harness Engineering — durable infrastructure: state files, check scripts, templates
```

A loop invokes superpowers skills for execution and runs on top of harness
infrastructure. If harness isn't set up yet, use harness-engineering first.

---

## The Five-Step Build Method

### Step 1 — Define a Machine-Verifiable Goal

State the objective so a machine can unambiguously tell success from failure:

**Good:**
> "Run all 8 mesh files. For each: solve k-omega SST at Re=1e6, check all
> residuals < 1e-6. Log pass/fail per mesh to outputs/summary.md. If a mesh
> diverges, retry once with relaxed under-relaxation; if still diverged, mark
> FAILED and continue. When all 8 done, report."

**Bad:**
> "Run the simulations and see which ones converge."

The 4-Condition Readiness Test (see `references/readiness-test.md`) determines
whether your task is loop-ready. If you can't describe success without human
judgment, this task doesn't belong in a loop yet.

### Step 2 — Build the Minimum Viable Loop

Four components. Nothing more.

```
┌──────────────────────────┐
│        Trigger           │  What starts a cycle:
│                          │  - timer (cron, /loop, ScheduleWakeup)
│                          │  - event (webhook, git push, file change)
│                          │  - goal (/goal — run until condition X)
└──────────┬───────────────┘
           │ fires
           ▼
┌──────────────────────────┐
│   Context (Skill File)   │  CLAUDE.md / STATE.md — project brief
│                          │  so the agent doesn't re-learn every cycle.
└──────────┬───────────────┘
           │ reads
           ▼
┌──────────────────────────┐
│     State File           │  Written to disk every cycle via harness:
│                          │  "What's done, what broke, what's next"
│                          │  Uses STATE.md convention from harness.
└──────────┬───────────────┘
           │ output reaches
           ▼
┌──────────────────────────┐
│  Gate (Verification)     │  Independent check via harness scripts:
│                          │  `scripts/check-harness.sh` for integrity,
│                          │  validation-templates.md for claim scoping.
│                          │  Must NOT share context with the writer.
└──────────────────────────┘
```

**Build order — do not skip:**
1. Manual run once — prove the task works end-to-end
2. Write the context/skill file so it's reproducible
3. Wrap in the trigger
4. Only then enable scheduled execution

The state file and gate components are provided by **harness-engineering**.
If they aren't set up, invoke `harness-engineering` first or read its
`SKILL.md` for the conventions.

### Step 3 — Separate Writer from Verifier

This is the single most important rule in loop design:

> The agent that writes the output must NOT be the same agent that verifies
> it. The verifier must not see the writer's reasoning.

**Why:** Models grade their own work too generously. An independent verifier
with no shared context catches issues the writer missed.

**Implementation patterns (from strongest isolation to weakest):**

| Pattern | How | Context isolation |
|---------|-----|-------------------|
| **Shell gate** | Deterministic script (`check-harness.sh`, grep/awk) | Zero — script has no "opinion" |
| **/goal sub-agent** | Writer = one agent, verifier = independent sub-agent | Verifier sees only output files |
| **Model split** | Large model writes, small model verifies | Cheapest, still need to strip writer context |

See `references/anti-patterns.md` for common mistakes (mixing verification
into execution, vague STATE.md next-steps, loops touching judgment calls).

### Step 4 — Configure Hard Stop Conditions

A loop without bounds is a billing surprise. Before enabling any trigger:

| Limit | What it prevents | Recommended default |
|-------|-----------------|-------------------|
| **Token limit per cycle** | One runaway iteration | 2x expected max tokens |
| **Iteration limit** | Infinite retry loop | 3 retries, then escalate |
| **Wall-clock timeout** | Hung processes | 2x expected runtime |
| **Total cost budget** | Silent overspend | Set per-cycle and total |

**Document ALL hard stop conditions in STATE.md** under a "Limits" section
with current values, so a fresh agent can see them without reading config files.

Required hard stop types (every loop must define ALL three):
1. **Iteration limit** — max retries per item, max items before escalation
2. **Wall-clock timeout** — max time per cycle, max total runtime, or a hard deadline
   (e.g., "must finish by 5 AM", "if service down > 15 min, force-escalate")
3. **Failure threshold** — max consecutive failures before pausing

**When a loop hits a limit:**
1. Log the failure reason to STATE.md
2. Send notification (Slack, email, inbox issue)
3. Pause the loop (do NOT silently retry)
4. Wait for human intervention

**Escalation path — use this exact 3-level ladder:**
```
Level 1 — 1st failure:        auto-retry (with backoff if applicable)
Level 2 — 2nd failure:        notify Slack/#incident (do NOT retry again at this level)
Level 3 — 3rd failure:        pause loop + alert human + wait for intervention
```
Also: cost > 80% of budget → notify. Cost > 100% → halt.
Time-based deadline breach → treat as Level 3 escalation regardless of failure count.

### Step 5 — Track the One Metric That Matters

Ignore token count, PR count, run count. Track only:

> **Cost per accepted change** = total loop cost ÷ number of accepted outputs

If the **acceptance rate** (outputs that pass the gate ÷ total outputs)
drops below 50%, the loop costs more in review than it saves. Kill or
redesign.

**Token efficiency (proportionality):**
- A simple monitoring loop should run under 30k tokens per cycle
- An experiment sweep with full harness typically runs 60-90k tokens per cycle
- If token usage exceeds 2x what a human would spend describing the same task
  in writing, the skill instructions are likely causing over-elaboration
- When you notice the agent producing unnecessarily verbose output (pages of
  boilerplate, over-documented scripts), tighten the prompt — don't add more
  "be concise" rules, just remove the parts of the skill that trigger the
  verbosity

**How to track it:**
- Log cycle cost in STATE.md (estimated tokens × rate)
- Log gate outcome (pass/fail) per cycle
- Compute acceptance rate weekly
- Set a threshold alert: pause loop if rate < 50% for 3 consecutive days

---

## Composite Loop Pattern (Nested Loops)

For complex tasks, a single loop is insufficient. Use parent-child nesting:

```
┌──────────────────────────────────────────────┐
│            Parent Loop (Orchestrator)         │
│  Monitors /goal: "All 20 configs complete"   │
│  Reads STATE.md, decides what to dispatch    │
├──────────────────────────────────────────────┤
│                                              │
│  ┌──────────────┐  ┌──────────────┐          │
│  │ Child Loop 1 │  │ Child Loop 2 │  ...     │
│  │ /goal: run   │  │ /goal: run   │          │
│  │ config A     │  │ config B     │          │
│  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                    │
│         ▼                 ▼                    │
│  ┌──────────────────────────────────┐         │
│  │     Independent Verifier         │         │
│  │  (no context from child loops)   │         │
│  └──────────────────────────────────┘         │
└──────────────────────────────────────────────┘
```

**Rules for composite loops:**
- Children **never** read each other's state — isolation is mandatory
- Verifier receives only output artifacts, never child chain-of-thought
- Parent handles retry/skip logic

**When the goal is a comparison/ranking** (e.g., hyperparameter sweep, A/B test):
The output report MUST include parameter influence analysis — not just ranked results.
Show which parameters drove the outcome (e.g., "learning rate affected convergence more
than network width by 3×"). A bare ranking without influence analysis is incomplete.

**Use cases:** hyperparameter sweeps, multi-repo CI, parallel pipeline branches.

---

## Superpowers Integration

Inside a loop, reference superpowers skills for specific steps:

| Step | Superpowers skill | Example usage |
|------|------------------|---------------|
| **Dispatch child loops** | `dispatching-parallel-agents` | Sweep 18 PINN configs: spawn 3 parallel agents, each runs 6 configs |
| **Debug failures** | `systematic-debugging` | A config produces NaN loss: replicate, isolate dims, check gradient flow |
| **Gate verification** | `verification-before-completion` | Monitor loop output dir, verify STATE.md integrity, check convergence metrics |
| **Pre-merge finalization** | `finishing-a-development-branch` | After all loop configs pass: clean up experiment dir, push results, archive logs |

For website monitoring: use `dispatching-parallel-agents` to check
multiple endpoints simultaneously, `systematic-debugging` on 5xx response
analysis, `verification-before-completion` to confirm recovery before
re-adding to rotation.

---

## Harness Integration

This skill integrates with harness-engineering for infrastructure:

- **State file** → uses harness `STATE.md` convention
- **Gate verification** → delegates to `scripts/check-harness.sh`
- **Validation criteria** → uses harness `references/validation-templates.md`
- **Plan artifacts** → stored in `docs/harness/active/` per harness convention
- **Cleanup** → uses harness `references/entropy-checklist.md`

If the harness infrastructure is not present, run `harness-engineering` first
to bootstrap it.

---

## Reference Files

- `references/anti-patterns.md` — Common mistakes and how to avoid them
- `references/readiness-test.md` — 4-Condition test and loop triggers
- `scripts/loop-audit.sh` — Check active loops for health

For harness-related references (state file guide, validation templates,
entropy checklist), see the harness-engineering skill's reference files.
