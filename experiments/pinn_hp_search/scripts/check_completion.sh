#!/bin/bash
# ============================================================================
# PINN Sweep Completion Check
#
# Verifies all 18 configs have been processed (DONE or FAILED) and
# that outputs are valid.
#
# Exit codes:
#   0 = All configs complete
#   1 = Some configs still pending
#   2 = Missing configs
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPERIMENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Convert Git Bash paths for Windows Python
if command -v cygpath &> /dev/null; then
    EXPERIMENT_DIR_WIN="$(cygpath -w "$EXPERIMENT_DIR")"
else
    EXPERIMENT_DIR_WIN="$EXPERIMENT_DIR"
fi

OUTPUTS_DIR="$EXPERIMENT_DIR/outputs"
CONFIG_DIR="$EXPERIMENT_DIR/configs"
PYTHON="python"

get_config_names() {
    $PYTHON -c "
import json
with open(r'${EXPERIMENT_DIR_WIN}/configs/manifest.json') as f:
    m = json.load(f)
for c in m['configs']:
    print(c['name'])
"
}

get_metrics_status() {
    local metrics_file="$1"
    if [ ! -f "$metrics_file" ]; then
        echo "MISSING"
        return
    fi
    $PYTHON -c "
import json
print(json.load(open(r'${metrics_file}'))['status'])
" 2>/dev/null || echo "UNKNOWN"
}

TOTAL=0
DONE=0
FAILED=0
PENDING=0

echo ""
echo "=== PINN Sweep Completion Check ==="
echo ""

for cfg in $(get_config_names); do
    TOTAL=$((TOTAL + 1))
    METRICS="$OUTPUTS_DIR/$cfg/metrics.json"

    if [ ! -d "$OUTPUTS_DIR/$cfg" ]; then
        echo "  [PENDING] $cfg — no output directory"
        PENDING=$((PENDING + 1))
        continue
    fi

    if [ ! -f "$METRICS" ]; then
        echo "  [PENDING] $cfg — no metrics.json"
        PENDING=$((PENDING + 1))
        continue
    fi

    STATUS=$(get_metrics_status "$METRICS")

    case "$STATUS" in
        DONE)
            echo -e "  [\033[0;32mDONE\033[0m]   $cfg"
            DONE=$((DONE + 1))
            ;;
        FAILED_NAN)
            echo -e "  [\033[0;31mFAIL\033[0m]  $cfg — NaN in training"
            FAILED=$((FAILED + 1))
            ;;
        *)
            echo -e "  [\033[1;33m?\033[0m]    $cfg — status: $STATUS"
            PENDING=$((PENDING + 1))
            ;;
    esac
done

echo ""
echo "=== Summary ==="
echo "  Total:   $TOTAL"
echo "  DONE:    $DONE"
echo "  FAILED:  $FAILED"
echo "  PENDING: $PENDING"
echo ""

if [ $PENDING -eq 0 ] && [ $TOTAL -gt 0 ]; then
    echo -e "\033[0;32m[PASS]\033[0m All $TOTAL configs processed."
    exit 0
elif [ $PENDING -gt 0 ]; then
    echo -e "\033[1;33m[PENDING]\033[0m $PENDING config(s) still pending."
    exit 1
else
    echo -e "\033[0;31m[ERROR]\033[0m No configs found."
    exit 2
fi
