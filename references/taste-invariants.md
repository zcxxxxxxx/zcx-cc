# Taste Invariants — Experiment Standards as Executable Checks

This file links to the canonical taste invariants reference in the
harness-engineering skill. For the authoritative version with all templates,
see: `skills/harness-engineering/references/taste-invariants.md`

## Registered Invariants in This Repo

| Standard | Check Script | Status |
|----------|-------------|--------|
| Seed field in every config | `scripts/check_seeds.sh` | Registered in `scripts/check-harness.sh` |

## How to Add a New Invariant
1. Identify a standard that was violated or forgotten.
2. Write a check script in `scripts/`.
3. Register it in `scripts/check-harness.sh` audit function.
4. Remove the prose reminder — the script replaces it.
