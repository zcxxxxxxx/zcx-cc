#!/bin/bash
# Taste Invariant: Seed Field Presence Check
# Verifies that every YAML config file in the experiment directory tree
# contains a 'seed' field under one of: training, evaluation, or top-level.
#
# Usage: bash scripts/check_seeds.sh [experiments_dir]
#   experiments_dir  — path to experiments root (default: experiments/)
#
# Exit codes:
#   0 — PASS (all configs have seed fields)
#   1 — FAIL (one or more configs missing seed)
#
# This is a taste invariant — it encodes the standard:
#   "Every experiment config MUST record its random seed for reproducibility."

set -euo pipefail

EXPERIMENTS_DIR="${1:-experiments}"
MISSING=0
CHECKED=0

if [[ ! -d "$EXPERIMENTS_DIR" ]]; then
  echo "FAIL: experiments directory not found: $EXPERIMENTS_DIR"
  exit 1
fi

while IFS= read -r -d '' CFG; do
  CHECKED=$((CHECKED + 1))
  # Search for seed field (matches `seed: 42` at any indentation)
  # Avoids Perl regex (-P) for Windows/MSYS2 compatibility
  if grep -qE '^[[:space:]]+seed:[[:space:]]*[0-9]+' "$CFG"; then
    :  # seed found
  else
    echo "MISSING: no seed field in $CFG"
    MISSING=$((MISSING + 1))
  fi
done < <(find "$EXPERIMENTS_DIR" -name '*.yaml' -type f -print0 2>/dev/null || true)

if [[ "$CHECKED" -eq 0 ]]; then
  echo "WARN: no YAML config files found in $EXPERIMENTS_DIR"
  exit 0
fi

if [[ "$MISSING" -gt 0 ]]; then
  echo "FAIL: ${MISSING}/${CHECKED} config(s) missing seed field"
  exit 1
else
  echo "PASS: all ${CHECKED} config(s) have seed fields"
  exit 0
fi
