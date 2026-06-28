#!/bin/bash
# Taste Invariant: Convergence Check
# Verifies that the final training loss is below a given threshold.
#
# Usage: bash scripts/check_convergence.sh <log_file> [threshold]
#   log_file   — path to training.log
#   threshold  — loss threshold (default: 1e-4)
#
# Exit codes:
#   0 — PASS (loss below threshold)
#   1 — FAIL (loss above threshold or unparseable)

set -euo pipefail

LOG="${1:?"Usage: check_convergence.sh <log_file> [threshold]"}"
THRESHOLD="${2:-1e-4}"

if [[ ! -f "$LOG" ]]; then
  echo "FAIL: log file not found: $LOG"
  exit 1
fi

# Extract final loss — supports common formats:
#   "loss=0.000123", "loss: 0.000123", "final_loss: 0.000123"
FINAL_LOSS=$(tail -n 20 "$LOG" | grep -oP '(?:loss|final_loss)[=:]\s*\K[0-9]+\.[0-9]+(?:e[+-]?[0-9]+)?' | tail -1)

if [[ -z "$FINAL_LOSS" ]]; then
  echo "FAIL: could not extract final loss from $LOG"
  echo "  Last 5 lines of log:"
  tail -5 "$LOG" | sed 's/^/  /'
  exit 1
fi

# Use awk for float comparison (more portable than bc)
if awk "BEGIN {exit !($FINAL_LOSS > $THRESHOLD)}"; then
  echo "FAIL: loss=$FINAL_LOSS exceeds threshold=$THRESHOLD"
  exit 1
else
  echo "PASS: loss=$FINAL_LOSS < threshold=$THRESHOLD"
  exit 0
fi
