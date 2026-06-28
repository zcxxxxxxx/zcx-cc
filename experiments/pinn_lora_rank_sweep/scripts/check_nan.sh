#!/bin/bash
# Taste Invariant: NaN Check
# Verifies that the training log contains no NaN values in loss or gradients.
#
# Usage: bash scripts/check_nan.sh <log_file>
#
# Exit codes:
#   0 — PASS (no NaN found)
#   1 — FAIL (NaN detected)

set -euo pipefail

LOG="${1:?"Usage: check_nan.sh <log_file>"}"

if [[ ! -f "$LOG" ]]; then
  echo "FAIL: log file not found: $LOG"
  exit 1
fi

# Search for NaN, nan, inf, -inf patterns in log
NAN_COUNT=$(grep -ciP '\b(nan|inf|-\s*inf|nan\.0)\b' "$LOG" || true)

if [[ "$NAN_COUNT" -gt 0 ]]; then
  echo "FAIL: found ${NAN_COUNT} NaN/Inf occurrences in $LOG"
  grep -inP '\b(nan|inf|-\s*inf|nan\.0)\b' "$LOG" | head -10
  exit 1
else
  echo "PASS: no NaN/Inf found in $LOG"
  exit 0
fi
