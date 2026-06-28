#!/bin/bash
# check-residuals.sh — Check OpenFOAM solver log residuals against tolerance
# ============================================================================
# Taste invariant: every solver log must have all residuals below threshold.
# Usage:
#   bash scripts/check-residuals.sh logs/mesh_1.log [tolerance]
#   bash scripts/check-residuals.sh logs/mesh_1.log 1e-6
#
# Exit codes:
#   0 — PASS (all residuals below tolerance)
#   1 — FAIL (residuals above tolerance or divergence detected)
#   2 — ERROR (log file not found or unparseable)
# ============================================================================

set -euo pipefail

LOG_FILE="${1:-}"
TOLERANCE="${2:-1e-6}"

if [[ -z "$LOG_FILE" ]]; then
    echo "[ERROR] Usage: $0 <log_file> [tolerance]"
    exit 2
fi

if [[ ! -f "$LOG_FILE" ]]; then
    echo "[ERROR] Log file not found: ${LOG_FILE}"
    exit 2
fi

# Regex for OpenFOAM residual lines
RESIDUAL_PATTERN='Solving for[[:space:]]+([^,]+),[[:space:]]*Initial residual[[:space:]]*=[[:space:]]*([0-9.eE+\-]+),[[:space:]]*Final residual[[:space:]]*=[[:space:]]*([0-9.eE+\-]+)'

# Divergence keywords
DIVERGENCE_KEYWORDS="NA?N|inf|divergence|failed|Floating point exception"

DIVERGED=false
declare -A FINAL_RESIDUALS

while IFS= read -r line; do
    # Check divergence keywords
    if echo "$line" | grep -qiE "$DIVERGENCE_KEYWORDS" 2>/dev/null; then
        echo "[DIVERGED] $line"
        DIVERGED=true
    fi

    # Extract residuals
    if [[ "$line" =~ $RESIDUAL_PATTERN ]]; then
        FIELD="${BASH_REMATCH[1]}"
        FINAL="${BASH_REMATCH[3]}"
        FINAL_RESIDUALS["$FIELD"]="$FINAL"
    fi
done < "$LOG_FILE"

if [[ "$DIVERGED" == "true" ]]; then
    echo "[FAIL] Divergence detected in ${LOG_FILE}"
    exit 1
fi

if [[ ${#FINAL_RESIDUALS[@]} -eq 0 ]]; then
    echo "[ERROR] No residual data found in ${LOG_FILE}"
    exit 2
fi

MAX_RESIDUAL=0
ALL_PASS=true
for field in "${!FINAL_RESIDUALS[@]}"; do
    VAL="${FINAL_RESIDUALS[$field]}"
    if (( $(echo "$VAL > $MAX_RESIDUAL" | bc -l 2>/dev/null || echo "0") )); then
        MAX_RESIDUAL=$VAL
    fi
    if (( $(echo "$VAL >= $TOLERANCE" | bc -l 2>/dev/null || echo "1") )); then
        echo "  [FAIL] ${field}: residual=${VAL} >= tol=${TOLERANCE}"
        ALL_PASS=false
    else
        echo "  [PASS] ${field}: residual=${VAL} < tol=${TOLERANCE}"
    fi
done

if [[ "$ALL_PASS" == "true" ]]; then
    echo "[PASS] All residuals below ${TOLERANCE} (max=${MAX_RESIDUAL})"
    exit 0
else
    echo "[FAIL] Some residuals above tolerance ${TOLERANCE}"
    exit 1
fi
