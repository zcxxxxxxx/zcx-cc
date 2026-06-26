---
name: claude-md-maintainer
description: >
  Write, review, simplify, or reorganize CLAUDE.md as a concise agent onboarding
  manual. ACTIVATE WHENEVER CLAUDE.md is created, changed, reviewed, or discussed
  — every edit to CLAUDE.md should pass through this skill. Also activate when:
  creating/initializing CLAUDE.md, reviewing/improving an existing CLAUDE.md,
  reducing an overlong one, deciding what belongs in CLAUDE.md vs
  README/harness/memory, or turning repeated mistakes into durable rules.
  Trigger on project-specific phrases like "检查/更新 CLAUDE.md", "CLAUDE.md 还准吗",
  "加一条规则", "改一下 CLAUDE.md", or any smoke-test/harness workflow that
  touches agent instructions.
  Do NOT use for: writing experiment plans (use harness-engineering), formatting
  README files, or one-off task instructions that belong in conversation context.
---

## Core Principle

`CLAUDE.md` is an onboarding manual for the agent, not a README for humans. Keep it short, specific, executable, and layered.

| ❌ Overloaded CLAUDE.md | ✅ Concise CLAUDE.md |
|---|---|
| Full directory tree listing | Key entry points only |
| Broad wishes like "write clean code" | Concrete, verifiable constraints |
| Experiment logs and metrics | Links to `docs/harness/` for evidence |
| Duplicated README content | Unique agent-focused instructions only |
| Stale task histories | Current project state snapshot |

## Content Classification

### What to Keep
Rules that are concrete, action-oriented, verifiable, surprising (not inferable from code), tied to a real constraint, or accompanied by a short reason.

Example:
> Do not commit `reproduction/**/outputs/`; these contain generated figures, checkpoints, and logs. Record metrics in `docs/harness/` instead.

### What to Remove or Move

| Move to docs/harness/ | Move to linked docs |
|---|---|
| Experiment results | Full architecture prose |
| `docs/harness/`-worthy records | Long explanations and history |

| Remove entirely |
|---|
| "Be careful" / "Write clean code" (not actionable) |
| Large terminology glossaries |
| Rules that cannot be verified |
| Stale task histories |

## Recommended Structure

Aim for 50–80 lines. This ordering is intentional: orient → do → navigate → follow conventions → know boundaries → avoid traps.

```markdown
## Project Overview       # WHAT is this repo, domain, current goal
## Commands               # HOW to run (install, test, smoke)
## Architecture           # WHERE things live + links to deeper docs
## Conventions            # HOW to write code (naming, layout, testing)
## Hard Constraints       # WHAT NOT TO DO, each with a reason
## Gotchas                # TRAPS that code inspection won't reveal
```

For research repositories, add an `Active Harness Files` section pointing to tracked planning/validation docs — this tells the agent "these experiments are the current priority."

## Workflow

1. Read existing `CLAUDE.md` and inspect the repo to identify real entry points and commands
2. Classify existing content using the tables above — decide what stays, moves to harness docs, or is removed
3. Check `docs/harness/` for active experiment records; if new harness files exist, add an `Active Harness Files` section
4. Rewrite `CLAUDE.md` following the six-part structure, keeping it under 80 lines
5. Validate: every instruction specific enough for Claude to act on? At least one checkable command or harness pointer exists?
6. Report changes in the format below

## Rule Update Trigger

Add a new rule only when **all four** conditions are met:

- [ ] Claude made the same mistake **twice**
- [ ] The rule prevents a **real project risk**
- [ ] The rule **cannot be inferred** from the current code
- [ ] The rule can be written in a **concrete and checkable** way

Do not add one-off preferences or temporary task details to `CLAUDE.md`; use chat context, tasks, memory, or harness docs as appropriate.

## Output Format

Report what changed so the user can review the decisions:

```
## Updated: CLAUDE.md

### Added
- [section]: [summary]

### Removed / Moved
- [item] → moved to [new location]

### Remaining Gaps
- [anything needing user confirmation]
```

## Quality Checklist

- [ ] Under 80 lines, or clearly justified if longer
- [ ] Avoids duplicating README content
- [ ] Hard constraints are specific and reasoned
- [ ] Commands are runnable from the repo root
- [ ] Generated outputs, secrets, and large files explicitly protected if relevant
- [ ] Deeper docs linked instead of pasted
- [ ] A new session could start working from this file
