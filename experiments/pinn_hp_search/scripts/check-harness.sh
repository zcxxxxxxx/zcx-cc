#!/bin/bash
# ============================================================================
# PINN Hyperparameter Search — Harness Integrity Check
#
# Verifies the experiment harness is properly set up and all components
# are in place for the autonomous sweep.
#
# Usage:
#   bash scripts/check-harness.sh setup    # Verify experiment structure
#   bash scripts/check-harness.sh audit    # Full audit of state + outputs
#   bash scripts/check-harness.sh all      # Run all checks (default)
#
# Exit codes:
#   0 = All checks passed
#   1 = Warnings (non-critical)
#   2 = FAIL (critical issue, sweep cannot proceed)
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPERIMENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS() { echo -e "  ${GREEN}[PASS]${NC} $1"; }
WARN() { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
FAIL() { echo -e "  ${RED}[FAIL]${NC} $1"; }
INFO() { echo -e "  ${CYAN}[INFO]${NC}  $1"; }

# Convert Git Bash paths for Windows Python
if command -v cygpath &> /dev/null; then
    EXPERIMENT_DIR_WIN="$(cygpath -w "$EXPERIMENT_DIR")"
else
    EXPERIMENT_DIR_WIN="$EXPERIMENT_DIR"
fi

PYTHON="python"

# ============================================================================
# Taste Invariants (encoded as check functions)
# ============================================================================

check_manifest_integrity() {
    local errors=0
    if [ ! -f "$EXPERIMENT_DIR/configs/manifest.json" ]; then
        FAIL "manifest.json not found"
        return 1
    fi

    # Verify each manifest entry has a corresponding file
    $PYTHON -c "
import json, os
with open(r'${EXPERIMENT_DIR_WIN}/configs/manifest.json') as f:
    m = json.load(f)
cfg_dir = r'${EXPERIMENT_DIR_WIN}/configs'
errors = 0
for c in m['configs']:
    fpath = os.path.join(cfg_dir, c['file'])
    if not os.path.isfile(fpath):
        print(f'  [FAIL] Missing: {fpath}')
        errors += 1
if errors == 0:
    print(f'  [PASS] All {len(m[\"configs\"])} config files verified')
exit(errors)
" 2>/dev/null && return 0 || return 1
}

check_harness_files() {
    local errors=0
    local expected=(
        "pinn/model.py"
        "pinn/train.py"
        "pinn/utils.py"
        "pinn/verify.py"
        "configs/generate_configs.py"
        "configs/manifest.json"
        "scripts/run_sweep_parent.sh"
        "scripts/check_completion.sh"
        "scripts/aggregate_results.py"
        "scripts/check-harness.sh"
        "sweep_config.json"
        "STATE.md"
        "docs/plan.md"
        "docs/loop-design.md"
        "docs/escalation-protocol.md"
    )

    for f in "${expected[@]}"; do
        if [ -f "$EXPERIMENT_DIR/$f" ]; then
            PASS "File exists: $f"
        else
            WARN "File missing: $f"
            errors=$((errors + 1))
        fi
    done
    return $errors
}

check_state_file() {
    if [ ! -f "$EXPERIMENT_DIR/STATE.md" ]; then
        FAIL "STATE.md not found"
        return 1
    fi

    local state_content
    state_content=$(cat "$EXPERIMENT_DIR/STATE.md")

    # Check for required sections
    local missing=0
    echo "$state_content" | grep -q "Status:" || { WARN "STATE.md missing Status section"; missing=$((missing + 1)); }
    echo "$state_content" | grep -q "Progress:" || { WARN "STATE.md missing Progress section"; missing=$((missing + 1)); }
    echo "$state_content" | grep -q "Limits:" || { WARN "STATE.md missing Limits section"; missing=$((missing + 1)); }
    echo "$state_content" | grep -q "Escalation level:" || { WARN "STATE.md missing Escalation level section"; missing=$((missing + 1)); }

    if [ $missing -eq 0 ]; then
        PASS "STATE.md has all required sections"
    fi
    return $missing
}

check_outputs_clean() {
    local output_count
    output_count=$(find "$EXPERIMENT_DIR/outputs" -maxdepth 1 -type d 2>/dev/null | wc -l)
    # Subtract 1 for the outputs dir itself
    output_count=$((output_count - 1))

    if [ "$output_count" -eq 0 ]; then
        INFO "Outputs directory is empty (expected before execution)"
    elif [ "$output_count" -gt 0 ]; then
        INFO "Outputs directory has $output_count config subdirectories"
    fi
    return 0
}

check_retry_state() {
    local retry_file="$EXPERIMENT_DIR/outputs/retry_state.json"
    if [ -f "$retry_file" ]; then
        local consecutive
        consecutive=$($PYTHON -c "
import json
with open(r'${EXPERIMENT_DIR_WIN}/outputs/retry_state.json') as f:
    s = json.load(f)
print(s.get('consecutive_failures', 0))
" 2>/dev/null || echo "unknown")

        if [ "$consecutive" != "unknown" ] && [ "$consecutive" -ge 3 ]; then
            WARN "Retry state shows $consecutive consecutive failures — loop may be paused"
        else
            INFO "Retry state: $consecutive consecutive failures"
        fi
    else
        INFO "No retry state file (loop has not run yet)"
    fi
    return 0
}

check_git_committed() {
    if ! command -v git &> /dev/null; then
        WARN "git not available, skipping git checks"
        return 0
    fi

    # Check for uncommitted configs
    local uncommitted
    uncommitted=$(git -C "$EXPERIMENT_DIR" status --porcelain 'configs/' 2>/dev/null || true)
    if [ -n "$uncommitted" ]; then
        WARN "Uncommitted config files:"
        echo "$uncommitted" | while read -r line; do
            WARN "  $line"
        done
    else
        PASS "All config files committed"
    fi

    # Check for uncommitted scripts
    local uncommitted_scripts
    uncommitted_scripts=$(git -C "$EXPERIMENT_DIR" status --porcelain 'scripts/' 2>/dev/null || true)
    if [ -n "$uncommitted_scripts" ]; then
        WARN "Uncommitted script files detected"
    else
        PASS "All script files committed"
    fi
    return 0
}

# ============================================================================
# Setup
# ============================================================================

setup_checks() {
    echo ""
    echo "=== Harness Setup Checks ==="
    echo ""

    local exit_code=0

    echo "--- Required files ---"
    check_harness_files || exit_code=1

    echo ""
    echo "--- Config integrity ---"
    check_manifest_integrity || exit_code=2

    echo ""
    echo "--- STATE.md ---"
    check_state_file || exit_code=1

    echo ""
    echo "--- Outputs directory ---"
    check_outputs_clean

    if [ $exit_code -eq 0 ]; then
        echo ""
        echo -e "${GREEN}=== Setup checks complete: all PASS ===${NC}"
    elif [ $exit_code -eq 1 ]; then
        echo ""
        echo -e "${YELLOW}=== Setup checks complete: warnings (non-critical) ===${NC}"
    else
        echo ""
        echo -e "${RED}=== Setup checks complete: FAIL — critical issues ===${NC}"
    fi

    return $exit_code
}

# ============================================================================
# Audit
# ============================================================================

audit_checks() {
    echo ""
    echo "=== Harness Audit Checks ==="
    echo ""

    local exit_code=0

    echo "--- Retry state ---"
    check_retry_state

    echo ""
    echo "--- Git hygiene ---"
    check_git_committed

    echo ""
    echo "--- Output directory status ---"
    local done_count=0
    local fail_count=0
    local pending_count=0

    if [ -d "$EXPERIMENT_DIR/outputs" ]; then
        for d in "$EXPERIMENT_DIR/outputs"/*/; do
            [ -d "$d" ] || continue
            local metrics_file="$d/metrics.json"
            if [ -f "$metrics_file" ]; then
                local status
                status=$($PYTHON -c "
import json
print(json.load(open(r'${metrics_file}'))['status'])
" 2>/dev/null || echo "UNKNOWN")
                case "$status" in
                    DONE) done_count=$((done_count + 1)) ;;
                    FAILED*) fail_count=$((fail_count + 1)) ;;
                    *) pending_count=$((pending_count + 1)) ;;
                esac
            else
                pending_count=$((pending_count + 1))
            fi
        done
    fi

    INFO "Configs: $done_count DONE, $fail_count FAILED, $pending_count pending"

    if [ "$done_count" -eq 18 ] && [ "$fail_count" -eq 0 ]; then
        PASS "All 18 configs completed successfully"
    elif [ "$done_count" -gt 0 ] || [ "$fail_count" -gt 0 ]; then
        INFO "Sweep in progress: $done_count done, $fail_count failed"
    fi

    if [ $exit_code -eq 0 ]; then
        echo ""
        echo -e "${GREEN}=== Audit checks complete: all PASS ===${NC}"
    else
        echo ""
        echo -e "${YELLOW}=== Audit checks complete: issues found ===${NC}"
    fi

    return $exit_code
}

# ============================================================================
# Main
# ============================================================================

all_checks() {
    setup_checks
    echo ""
    audit_checks
}

case "${1:-all}" in
    setup)
        setup_checks
        exit $?
        ;;
    audit)
        audit_checks
        exit $?
        ;;
    all)
        all_checks
        exit $?
        ;;
    *)
        echo "Usage: $0 [setup|audit|all]"
        exit 1
        ;;
esac
