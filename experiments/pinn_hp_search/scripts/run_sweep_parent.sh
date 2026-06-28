#!/bin/bash
# ============================================================================
# PINN Hyperparameter Search — Parent Orchestrator Loop
#
# Reads STATE.md, picks the next pending config, dispatches the trainer,
# runs the independent verifier, and updates STATE.md.
#
# Usage:
#   bash scripts/run_sweep_parent.sh              # Run one cycle
#   bash scripts/run_sweep_parent.sh --loop        # Run all cycles in a loop
#   bash scripts/run_sweep_parent.sh --status      # Print current status
#
# Exit codes:
#   0 = All configs complete
#   1 = Still have pending configs
#   2 = Error / Limit hit
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPERIMENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Convert Git Bash paths (/f/...) to Windows paths (F:/...) for Python
if command -v cygpath &> /dev/null; then
    EXPERIMENT_DIR_WIN="$(cygpath -w "$EXPERIMENT_DIR")"
else
    EXPERIMENT_DIR_WIN="$EXPERIMENT_DIR"
fi

OUTPUTS_DIR="$EXPERIMENT_DIR/outputs"
STATE_FILE="$EXPERIMENT_DIR/STATE.md"
CONFIG_DIR="$EXPERIMENT_DIR/configs"
SWEEP_CONFIG="$EXPERIMENT_DIR/sweep_config.json"
TRAIN_SCRIPT="$EXPERIMENT_DIR/pinn/train.py"
VERIFY_SCRIPT="$EXPERIMENT_DIR/pinn/verify.py"
AGGREGATE_SCRIPT="$SCRIPT_DIR/aggregate_results.py"
PYTHON="python"

# Timing
START_TIME=$(date +%s)
WALL_LIMIT_HOURS=12
WALL_LIMIT_SEC=$((WALL_LIMIT_HOURS * 3600))
MAX_ITERATIONS=25
CONSECUTIVE_NAN_LIMIT=3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================================================
# Python helper — run Python with Windows paths
# ============================================================================

py_eval() {
    local code="$1"
    $PYTHON -c "$code" 2>/dev/null || echo ""
}

py_manifest_field() {
    local config_name="$1"
    local field="$2"
    $PYTHON -c "
import json
with open(r'${EXPERIMENT_DIR_WIN}/configs/manifest.json') as f:
    m = json.load(f)
for c in m['configs']:
    if c['name'] == '${config_name}':
        print(c.get('${field}', ''))
        break
" 2>/dev/null || echo ""
}

py_config_field() {
    local config_name="$1"
    local field="$2"
    $PYTHON -c "
import json
cfg_path = r'${EXPERIMENT_DIR_WIN}/configs/${config_name}.json'
print(json.load(open(cfg_path))['${field}'])
" 2>/dev/null || echo ""
}

py_metrics_status() {
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

# ============================================================================
# Helper Functions
# ============================================================================

get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

get_config_names() {
    # Get all config names from manifest, sorted
    $PYTHON -c "
import json
with open(r'${EXPERIMENT_DIR_WIN}/configs/manifest.json') as f:
    m = json.load(f)
for c in m['configs']:
    print(c['name'])
"
}

get_pending_configs() {
    local all_configs
    all_configs=$(get_config_names)
    local pending=""

    for cfg in $all_configs; do
        local metrics_file="$OUTPUTS_DIR/$cfg/metrics.json"
        if [ ! -f "$metrics_file" ]; then
            pending="$pending $cfg"
        else
            local status
            status=$(py_metrics_status "$metrics_file")
            if [ "$status" != "DONE" ] && [ "$status" != "FAILED_NAN" ]; then
                pending="$pending $cfg"
            fi
        fi
    done
    echo "$pending" | xargs
}

get_first_pending() {
    get_pending_configs | awk '{print $1}'
}

count_done() {
    local count=0
    for cfg in $(get_config_names); do
        local m="$OUTPUTS_DIR/$cfg/metrics.json"
        local status
        status=$(py_metrics_status "$m")
        if [ "$status" = "DONE" ]; then
            count=$((count + 1))
        fi
    done
    echo "$count"
}

count_failed() {
    local count=0
    for cfg in $(get_config_names); do
        local m="$OUTPUTS_DIR/$cfg/metrics.json"
        local status
        status=$(py_metrics_status "$m")
        if [ "$status" != "DONE" ] && [ "$status" != "MISSING" ]; then
            count=$((count + 1))
        fi
    done
    echo "$count"
}

# ============================================================================
# Wall Clock Check
# ============================================================================

check_wall_clock() {
    local now
    now=$(date +%s)
    local elapsed=$((now - START_TIME))
    if [ $elapsed -gt $WALL_LIMIT_SEC ]; then
        log_error "Wall clock limit ($WALL_LIMIT_HOURS hours) exceeded!"
        log_error "Elapsed: $((elapsed / 60)) minutes"
        return 1
    fi
    return 0
}

# ============================================================================
# Update STATE.md
# ============================================================================

update_state() {
    local total=$(get_config_names | wc -w)
    local done=$(count_done)
    local failed=$(count_failed)
    local pending=$((total - done - failed))
    local iteration="${1:-0}"
    local last_config="${2:-none}"
    local last_status="${3:-pending}"
    local next_step="${4:-All configs complete}"

    cat > "$STATE_FILE" << EOF
# Loop State — PINN Hyperparameter Search

**Status:** ${pending}/${total} pending — $done done, $failed failed

**Cycle info:**
- Started: $(date -u -d "@$START_TIME" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
- Last run: $(get_timestamp)
- Iterations: $iteration
- Wall clock elapsed: $((($(date +%s) - START_TIME) / 60)) minutes

**Progress:**
EOF

    for cfg in $(get_config_names); do
        local m="$OUTPUTS_DIR/$cfg/metrics.json"
        local s
        s=$(py_metrics_status "$m")
        case "$s" in
            DONE)
                echo "- [x] $cfg: DONE" >> "$STATE_FILE" ;;
            FAILED_NAN)
                echo "- [-] $cfg: FAILED (NaN)" >> "$STATE_FILE" ;;
            MISSING)
                echo "- [ ] $cfg: pending" >> "$STATE_FILE" ;;
            *)
                echo "- [~] $cfg: $s" >> "$STATE_FILE" ;;
        esac
    done

    cat >> "$STATE_FILE" << EOF

**Failures (last cycle):**
- $last_config: $last_status

**Next step:**
$next_step

**Limits:**
- Max iterations: $MAX_ITERATIONS
- Wall clock limit: $WALL_LIMIT_HOURS hours
- Consecutive NaN limit: $CONSECUTIVE_NAN_LIMIT
- Current iteration: $iteration
- Current wall elapsed: $((($(date +%s) - START_TIME) / 60)) min

**Escalation level:** $(if [ $failed -ge 3 ]; then echo "Level 3 — human intervention may be needed"; elif [ $failed -ge 1 ]; then echo "Level 2 — failures detected"; else echo "Level 0 — nominal"; fi)
EOF

    log_info "STATE.md updated"
}

# ============================================================================
# Run One Cycle
# ============================================================================

run_cycle() {
    local iteration="$1"

    # Check wall clock
    if ! check_wall_clock; then
        log_error "Wall clock limit hit. Aborting."
        log_error "Run aggregate results on partial data."
        update_state "$iteration" "SYSTEM" "WALL_CLOCK_LIMIT" "Wall clock limit hit. Run aggregation on partial data."
        exit 2
    fi

    # Find next pending config
    local next_config
    next_config=$(get_first_pending)

    if [ -z "$next_config" ]; then
        log_ok "All configs processed!"
        update_state "$iteration" "none" "complete" "All configs processed. Run aggregation."
        log_info "Running aggregation..."
        $PYTHON "$AGGREGATE_SCRIPT"
        log_ok "Sweep complete! See $OUTPUTS_DIR/sweep_ranking.md"
        exit 0
    fi

    log_info "=== Cycle $iteration: Processing $next_config ==="

    # --- STEP 1: Run Trainer --- #
    local config_file="$CONFIG_DIR/$next_config.json"
    local output_dir="$OUTPUTS_DIR/$next_config"

    mkdir -p "$output_dir"

    log_info "Training $next_config..."
    local train_start
    train_start=$(date +%s)

    set +e
    $PYTHON "$TRAIN_SCRIPT" \
        --lr "$(py_config_field "$next_config" learning_rate)" \
        --width "$(py_config_field "$next_config" hidden_width)" \
        --activation "$(py_config_field "$next_config" activation)" \
        --steps "$(py_config_field "$next_config" steps)" \
        --seed "$(py_config_field "$next_config" seed)" \
        --output-dir "$output_dir"
    TRAIN_EXIT=$?
    set -e

    local train_end
    train_end=$(date +%s)
    local train_duration=$((train_end - train_start))

    if [ $TRAIN_EXIT -ne 0 ]; then
        log_warn "Trainer exited with code $TRAIN_EXIT (may be NaN/error)"
    fi

    # --- STEP 2: Run Independent Verifier --- #
    log_info "Running independent verification gate on $next_config..."

    set +e
    $PYTHON "$VERIFY_SCRIPT" "$output_dir" --verbose
    VERIFY_EXIT=$?
    set -e

    # Read actual status from metrics.json
    local actual_status
    actual_status=$(py_metrics_status "$output_dir/metrics.json")

    # --- STEP 3: Update State --- #
    local next_step=""
    local cycle_status=""

    if [ "$actual_status" = "DONE" ] && [ $VERIFY_EXIT -eq 0 ]; then
        cycle_status="DONE"
        log_ok "$next_config: PASSED (trained in ${train_duration}s)"
        next_step="$(get_first_pending)"
        if [ -z "$next_step" ]; then
            next_step="All configs complete. Run: python scripts/aggregate_results.py"
        else
            next_step="Run next pending config: $next_step"
        fi
    elif [ "$actual_status" = "FAILED_NAN" ]; then
        cycle_status="FAILED_NAN"
        log_warn "$next_config: FAILED (NaN encountered)"
        next_step="$(get_first_pending)"
        if [ -z "$next_step" ]; then
            next_step="All configs complete. Run: python scripts/aggregate_results.py"
        else
            next_step="Run next pending config: $next_step"
        fi
    else
        cycle_status="FAILED"
        log_error "$next_config: FAILED (unknown error)"
        next_step="$(get_first_pending)"
        if [ -z "$next_step" ]; then
            next_step="All configs complete. Run: python scripts/aggregate_results.py"
        else
            next_step="Run next pending config: $next_step"
        fi
    fi

    update_state "$iteration" "$next_config" "$cycle_status" "$next_step"

    # --- STEP 4: Check Limits --- #
    local total_failed
    total_failed=$(count_failed)
    if [ $total_failed -ge $CONSECUTIVE_NAN_LIMIT ]; then
        log_warn "Failure limit reached ($total_failed >= $CONSECUTIVE_NAN_LIMIT)"
        log_warn "Continuing to next config anyway (failures may be unrelated)"
    fi

    if [ $iteration -ge $MAX_ITERATIONS ]; then
        log_error "Max iterations ($MAX_ITERATIONS) reached!"
        log_error "Run aggregation on partial results."
        $PYTHON "$AGGREGATE_SCRIPT"
        exit 2
    fi

    return 0
}

# ============================================================================
# Main
# ============================================================================

main() {
    local mode="${1:-single}"

    # Ensure config manifest exists
    if [ ! -f "$CONFIG_DIR/manifest.json" ]; then
        log_info "Generating config manifest..."
        $PYTHON "$CONFIG_DIR/generate_configs.py"
    fi

    mkdir -p "$OUTPUTS_DIR"

    local total_configs
    total_configs=$(get_config_names | wc -w)
    log_info "PINN Hyperparameter Search — $total_configs configs"
    log_info "Experiment dir: $EXPERIMENT_DIR"
    log_info "Output dir: $OUTPUTS_DIR"
    log_info "Wall clock limit: ${WALL_LIMIT_HOURS}h"
    echo ""

    if [ "$mode" = "--loop" ]; then
        # Loop mode: keep running until done or limit hit
        local iter=1
        while true; do
            log_info "--- Loop iteration $iter ---"
            run_cycle $iter
            local pending
            pending=$(get_pending_configs)
            if [ -z "$pending" ]; then
                log_ok "All configs complete!"
                break
            fi
            iter=$((iter + 1))
            if [ $iter -gt $MAX_ITERATIONS ]; then
                log_error "Max iterations ($MAX_ITERATIONS) reached. Stopping."
                break
            fi
            # Brief pause between cycles
            sleep 2
        done
    elif [ "$mode" = "--status" ]; then
        # Status mode: print current progress
        local total=$(get_config_names | wc -w)
        local done=$(count_done)
        local failed=$(count_failed)
        local pending=$((total - done - failed))
        echo ""
        echo "=== PINN Sweep Status ==="
        echo "Total:  $total"
        echo "Done:   $done"
        echo "Failed: $failed"
        echo "Pending: $pending"
        echo ""
        echo "Pending configs:"
        for cfg in $(get_pending_configs); do
            echo "  - $cfg"
        done
        echo ""
    else
        # Single cycle mode
        run_cycle 1
        local remaining
        remaining=$(get_pending_configs)
        if [ -n "$remaining" ]; then
            log_info "Pending configs remaining: $(echo $remaining | wc -w)"
            log_info "Run 'bash scripts/run_sweep_parent.sh --loop' to process all"
        fi
    fi
}

main "$@"
