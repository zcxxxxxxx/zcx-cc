# zcx-cc Project Rules

This is a computational research repo (CFD/PINN/ML). Experiments are structured
with harness-engineering conventions. See `engineering-workflow` plugin for
the full loop + harness toolchain.

## Project Structure

- `experiments/<name>/` — experiment directories, each self-contained
  - `outputs/` — generated checkpoints and logs. **Do not commit.**
  - `configs/` — YAML/JSON configs, committed
  - `scripts/` — run/check scripts, committed
  - `docs/` — plan/design docs, committed
  - `meshes/` — small test meshes committed; large ones in .gitignore
- `docs/harness/` — harness artifacts
  - `active/` — current experiment plans
  - `completed/` — archived plans
- `plugins/local/engineering-workflow/` — the engineering-workflow plugin

## Git Rules

- Do not commit `experiments/*/outputs/` or `docs/harness/completed/` — generated artifacts.
  Reason: these are experiment checkpoints recreatable from committed configs and code.
- Use `git-pushing` skill for all git operations. Reason: ensures consistent commit format
  and prevents accidental push of large files.

## Commands

```bash
# Check all experiment harnesses:
# bash experiments/<name>/scripts/check-harness.sh all
```

## Gotchas

- `.msh` files are small test meshes committed to the repo; do not add large mesh files.
- `F:/Git_repo/zcx-cc` is the repo root — prefer relative paths from here.
- This repo is used across multiple sessions; always write STATE.md per harness convention
  so the next agent can resume.
