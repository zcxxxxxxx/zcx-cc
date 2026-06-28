#!/bin/bash
# ============================================================================
# PINN Hyperparameter Search -- Harness-Enhanced Orchestrator Loop
#
# Extends run_sweep_parent.sh with:
#   - Per-config retry counter (up to 3 retries per config)
#   - Consecutive config failure tracking (escalate at 3)
#   - Persistent retry state across restarts (outputs/.retry_state.json)
#   - Full escalation ladder (Level 0-3)
#
# Usage:
#   bash scripts/run_sweep_harness.sh              # Run one cycle
#   bash scripts/run_sweep_harness.sh --loop        # Run all cycles
#   bash scripts/run_sweep_harness.sh --status      # Print current status
#   bash scripts/run_sweep_harness.sh --reset-retry # Reset retry counters
#
# Exit codes:
#   0 = All configs complete
#   1 = Still have pending configs
#   2 = Error / Limit hit
#   3 = ESCALATION -- 3 consecutive configs failed
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPERIMENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Convert Git Bash paths for Python
if command -v cygpath &> /dev/null; then
    EXPERIMENT_DIR_WIN="$(cygpath -w "$EXPERIMENT_DIR")"
else
    EXPERIMENT_DIR_WIN="$EXPERIMENT_DIR"
fi

OUTPUTS_DIR="$EXPERIMENT_DIR/outputs"
STATE_FILE="$EXPERIMENT_DIR/STATE.md"
CONFIG_DIR="$EXPERIMENT_DIR/configs"
RETRY_FILE="$OUTPUTS_DIR/.retry_state.json"
TRAIN_SCRIPT="$EXPERIMENT_DIR/pinn/train.py"
VERIFY_SCRIPT="$EXPERIMENT_DIR/pinn/verify.py"
AGGREGATE_SCRIPT="$SCRIPT_DIR/aggregate_results.py"
PYTHON="python"

# Limits
MAX_RETRIES_PER_CONFIG=3
CONSECUTIVE_FAIL_LIMIT=3
WALL_LIMIT_HOURS=12
WALL_LIMIT_SEC=$((WALL_LIMIT_HOURS * 3600))
MAX_ITERATIONS=25
PER_CONFIG_TIMEOUT_SEC=$((2 * 3600))  # 2 hours

# Timing
START_TIME=$(date +%s)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_esc()   { echo -e "${MAGENTA}[ESCALATE]${NC} $1"; }

# ============================================================================
# Retry State Persistence
# ============================================================================

retry_state_init() {
    mkdir -p "$OUTPUTS_DIR"
    if [ ! -f "$RETRY_FILE" ]; then
        echo '{"retries": {}, "consecutive_failures": 0}' > "$RETRY_FILE"
    fi
}

retry_state_get() {
    local cfg_name="$1"
    $PYTHON -c "
import json
data = json.load(open(r'${RETRY_FILE}'))
print(data.get('retries', {}).get('${cfg_name}', 0))
" 2>/dev/null || echo "0"
}

retry_state_set() {
    local cfg_name="$1"
    local count="$2"
    $PYTHON -c "
import json
data = json.load(open(r'${RETRY_FILE}'))
data['retries']['${cfg_name}'] = $count
json.dump(data, open(r'${RETRY_FILE}', 'w'), indent=2)
" 2>/dev/null || true
}

retry_state_get_consecutive() {
    $PYTHON -c "
import json
data = json.load(open(r'${RETRY_FILE}'))
print(data.get('consecutive_failures', 0))
" 2>/dev/null || echo "0"
}

retry_state_set_consecutive() {
    local count="$1"
    $PYTHON -c "
import json
data = json.load(open(r'${RETRY_FILE}'))
data['consecutive_failures'] = $count
json.dump(data, open(r'${RETRY_FILE}', 'w'), indent=2)
" 2>/dev/null || true
}

retry_state_reset_config() {
    local cfg_name="$1"
    $PYTHON -c "
import json
data = json.load(open(r'${RETRY_FILE}'))
data['retries'].pop('${cfg_name}', None)
json.dump(data, open(r'${RETRY_FILE}', 'w'), indent=2)
" 2>/dev/null || true
}

retry_state_reset_all() {
    echo '{"retries": {}, "consecutive_failures": 0}' > "$RETRY_FILE"
    log_info "Retry state reset."
}

# ============================================================================
# Helper Functions
# ============================================================================

get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

get_config_names() {
    $PYTHON -c "
import json
with open(r'${EXPERIMENT_DIR_WIN}/configs/manifest.json') as f:
    m = json.load(f)
for c in m['configs']:
    print(c['name'])
"
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

py_metrics_field() {
    local metrics_file="$1"
    local field="$2"
    if [ ! -f "$metrics_file" ]; then
        echo ""
        return
    fi
    $PYTHON -c "
import json
print(json.load(open(r'${metrics_file}')).get('${field}', ''))
" 2>/dev/null || echo ""
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
            if [ "$status" != "DONE" ] && [ "$status" != "FAILED_NAN" ] && [ "$status" != "FAILED_EXHAUSTED" ]; then
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
        if [ "$status" = "FAILED_NAN" ] || [ "$status" = "FAILED_EXHAUSTED" ]; then
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
        return 1
    fi
    return 0
}

# ============================================================================
# Escalation Check
# ============================================================================

check_escalation() {
    local consecutive
    consecutive=$(retry_state_get_consecutive)
    if [ "$consecutive" -ge "$CONSECUTIVE_FAIL_LIMIT" ]; then
        log_esc "============================================"
        log_esc " ESCALATION TRIGGERED"
        log_esc " $consecutive consecutive configs have failed"
        log_esc " Max consecutive failures: $CONSECUTIVE_FAIL_LIMIT"
        log_esc " This indicates a systemic issue."
        log_esc " Possible causes:"
        log_esc "   - PyTorch/torch not installed"
        log_esc "   - NaN in PDE residual (Burgers equation)"
        log_esc "   - Architecture too large for device"
        log_esc "   - Data generation error"
        log_esc "============================================"
        return 1
    fi
    return 0
}

# ============================================================================
# Update STATE.md (Harness-Enhanced)
# ============================================================================

update_state() {
    local total=$(get_config_names | wc -w)
    local done=$(count_done)
    local failed=$(count_failed)
    local pending=$((total - done - failed))
    local iteration="${1:-0}"
    local last_config="${2:-none}"
    local last_status="${3:-pending}"
    local consecutive=$(retry_state_get_consecutive)

    # Determine escalation level
    local esc_level="Level 0 -- nominal"
    if [ "$consecutive" -ge 3 ]; then
        esc_level="Level 3 -- ESCALATION: $consecutive consecutive config failures"
    elif [ "$consecutive" -ge 2 ]; then
        esc_level="Level 2 -- warning: $consecutive consecutive failures"
    elif [ "$consecutive" -ge 1 ]; then
        esc_level="Level 1 -- minor: $consecutive consecutive failures"
    fi

    # Build next step
    local next_step
    local next_pending
    next_pending=$(get_first_pending)
    if [ -z "$next_pending" ]; then
        next_step="All configs processed. Run: python scripts/aggregate_results.py"
    else
        next_step="Run next pending config: $next_pending"
    fi

    cat > "$STATE_FILE" << EOF
# Loop State -- PINN Hyperparameter Search (Harness-Enhanced)

**Status:** ${pending}/${total} pending -- $done done, $failed failed

**Retry Tracking:**
- Per-config retries remaining: $MAX_RETRIES_PER_CONFIG max each
- Consecutive config failures: $consecutive
- Escalation level: $esc_level

**Cycle Info:**
- Started: $(date -u -d "@$START_TIME" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
- Last run: $(get_timestamp)
- Iterations: $iteration
- Wall clock elapsed: $((($(date +%s) - START_TIME) / 60)) minutes

**Config Status:**

| Config | Status | Retries | Val Loss |
|--------|--------|---------|----------|
EOF

    for cfg in $(get_config_names); do
        local m="$OUTPUTS_DIR/$cfg/metrics.json"
        local s
        s=$(py_metrics_status "$m")
        local r=$(retry_state_get "$cfg")
        local val_loss="--"

        # Get val loss from metrics if available
        if [ -f "$m" ]; then
            val_loss=$(py_metrics_field "$m" "val_loss" 2>/dev/null || echo "--")
            if [ "$val_loss" = "" ]; then
                # Try nested final_losses.val
                val_loss=$($PYTHON -c "
import json
m = json.load(open(r'${m}'))
fl = m.get('final_losses', {})
vl = fl.get('val', '--')
if vl != '--':
    try:
        vl = f'{float(vl):.4e}'
    except:
        pass
print(vl)
" 2>/dev/null || echo "--")
            fi
        fi

        local status_display
        case "$s" in
            DONE)              status_display="DONE" ;;
            FAILED_NAN)        status_display="FAILED (NaN)" ;;
            FAILED_EXHAUSTED)  status_display="FAILED (retries exhausted)" ;;
            MISSING)           status_display="pending" ;;
            *)                 status_display="$s" ;;
        esac
        echo "| $cfg | $status_display | $r/$MAX_RETRIES_PER_CONFIG | $val_loss |" >> "$STATE_FILE"
    done

    cat >> "$STATE_FILE" << EOF

**Last cycle:**
- Config: $last_config
- Status: $last_status

**Escalation History:**
EOF

    # Add escalation alert if triggered
    if [ "$consecutive" -ge 3 ]; then
        echo "- **ESCALATION at $(get_timestamp):** $consecutive consecutive configs failed. Manual intervention required." >> "$STATE_FILE"
    elif [ "$consecutive" -ge 1 ]; then
        echo "- $(get_timestamp): $consecutive consecutive config failure(s) detected" >> "$STATE_FILE"
    else
        echo "- (no escalation events)" >> "$STATE_FILE"
    fi

    cat >> "$STATE_FILE" << EOF

**Limits:**
- Max per-config retries: $MAX_RETRIES_PER_CONFIG
- Consecutive config failure limit: $CONSECUTIVE_FAIL_LIMIT
- Max iterations: $MAX_ITERATIONS
- Wall clock limit: $WALL_LIMIT_HOURS hours
- Per-config timeout: $((PER_CONFIG_TIMEOUT_SEC / 60)) minutes

**Next step:**
$next_step
EOF

    log_info "STATE.md updated (escalation level: $esc_level)"
}

# ============================================================================
# Run One Cycle (with Retry + Escalation)
# ============================================================================

run_cycle() {
    local iteration="$1"

    # Check wall clock
    if ! check_wall_clock; then
        log_error "Wall clock limit hit. Aborting."
        update_state "$iteration" "SYSTEM" "WALL_CLOCK_LIMIT"
        log_error "Run aggregation on partial data."
        $PYTHON "$AGGREGATE_SCRIPT" 2>/dev/null || true
        exit 2
    fi

    # Check escalation
    if ! check_escalation; then
        update_state "$iteration" "SYSTEM" "ESCALATION"
        log_esc "Loop paused due to escalation. Run --reset-retry to clear and retry."
        exit 3
    fi

    # Find next pending config
    local next_config
    next_config=$(get_first_pending)

    if [ -z "$next_config" ]; then
        log_ok "All configs processed!"
        update_state "$iteration" "none" "complete"
        log_info "Running aggregation..."
        $PYTHON "$AGGREGATE_SCRIPT"
        log_ok "Sweep complete! See $OUTPUTS_DIR/sweep_ranking.md"
        exit 0
    fi

    log_info "=== Cycle $iteration: $next_config ==="

    local config_file="$CONFIG_DIR/$next_config.json"
    local output_dir="$OUTPUTS_DIR/$next_config"
    mkdir -p "$output_dir"

    # --- STEP 1: Run Trainer --- #
    log_info "Training $next_config..."
    local train_start
    train_start=$(date +%s)

    LR=$($PYTHON -c "
import json
cfg = json.load(open(r'${config_file}'))
print(cfg['learning_rate'])
")
    WIDTH=$($PYTHON -c "
import json
cfg = json.load(open(r'${config_file}'))
print(cfg['hidden_width'])
")
    ACT=$($PYTHON -c "
import json
cfg = json.load(open(r'${config_file}'))
print(cfg['activation'])
")
    STEPS=$($PYTHON -c "
import json
cfg = json.load(open(r'${config_file}'))
print(cfg['steps'])
")
    SEED=$($PYTHON -c "
import json
cfg = json.load(open(r'${config_file}'))
print(cfg['seed'])
")

    set +e
    # Use timeout for per-config time limit
    timeout "$PER_CONFIG_TIMEOUT_SEC" \
        $PYTHON "$TRAIN_SCRIPT" \
            --lr "$LR" --width "$WIDTH" --activation "$ACT" \
            --steps "$STEPS" --seed "$SEED" --output-dir "$output_dir"
    TRAIN_EXIT=$?
    set -e

    local train_end
    train_end=$(date +%s)
    local train_duration=$((train_end - train_start))

    if [ $TRAIN_EXIT -eq 124 ]; then
        log_warn "Trainer timed out after ${PER_CONFIG_TIMEOUT_SEC}s"
    elif [ $TRAIN_EXIT -ne 0 ]; then
        log_warn "Trainer exited with code $TRAIN_EXIT"
    fi

    # --- STEP 2: Run Independent Verifier --- #
    log_info "Running verification gate on $next_config..."

    set +e
    $PYTHON "$VERIFY_SCRIPT" "$output_dir" --verbose
    VERIFY_EXIT=$?
    set -e

    local actual_status
    actual_status=$(py_metrics_status "$output_dir/metrics.json")

    # --- STEP 3: Retry / Escalation Logic --- #
    local cycle_status=""
    local retries_left=0

    if [ "$actual_status" = "DONE" ] && [ $VERIFY_EXIT -eq 0 ]; then
        # SUCCESS: Reset counters
        cycle_status="DONE"
        retry_state_reset_config "$next_config"
        retry_state_set_consecutive 0
        log_ok "$next_config: PASSED (${train_duration}s)"
        log_info "Consecutive failures reset to 0."

    elif [ "$actual_status" = "FAILED_NAN" ] || [ $TRAIN_EXIT -ne 0 ] || [ $VERIFY_EXIT -ne 0 ]; then
        # FAILURE: Check retries
        local current_retries
        current_retries=$(retry_state_get "$next_config")
        local new_retries=$((current_retries + 1))

        if [ "$new_retries" -lt "$MAX_RETRIES_PER_CONFIG" ]; then
            # Retry available: re-queue config
            cycle_status="RETRY ($new_retries/$MAX_RETRIES_PER_CONFIG)"
            retry_state_set "$next_config" "$new_retries"
            log_warn "$next_config: FAILED (retry $new_retries/$MAX_RETRIES_PER_CONFIG)"

            # Clean up old metrics so it appears pending again
            rm -f "$output_dir/metrics.json"

        else
            # Retries exhausted: mark permanently FAILED
            cycle_status="FAILED_EXHAUSTED"
            retry_state_set "$next_config" "$new_retries"

            # Update metrics.json with exhausted status
            $PYTHON -c "
import json, os
mp = r'${output_dir}/metrics.json'
if os.path.isfile(mp):
    m = json.load(open(mp))
else:
    m = {}
m['status'] = 'FAILED_EXHAUSTED'
m['retries_used'] = $new_retries
json.dump(m, open(mp, 'w'), indent=2)
" 2>/dev/null || true

            # Increment consecutive failures
            local consecutive
            consecutive=$(retry_state_get_consecutive)
            local new_consecutive=$((consecutive + 1))
            retry_state_set_consecutive "$new_consecutive"
            log_error "$next_config: FAILED (retries exhausted, consecutive failures=$new_consecutive)"

            # Alert on escalation boundary
            if [ "$new_consecutive" -ge "$CONSECUTIVE_FAIL_LIMIT" ]; then
                log_esc "ESCALATION: $new_consecutive consecutive configs failed!"
            fi
        fi
    else
        cycle_status="FAILED_UNKNOWN"
        log_error "$next_config: FAILED (unknown status: $actual_status)"
    fi

    # --- STEP 4: Update State --- #
    update_state "$iteration" "$next_config" "$cycle_status"

    # --- STEP 5: Check Iteration Limit --- #
    if [ "$iteration" -ge "$MAX_ITERATIONS" ]; then
        log_error "Max iterations ($MAX_ITERATIONS) reached!"
        $PYTHON "$AGGREGATE_SCRIPT" 2>/dev/null || true
        exit 2
    fi

    return 0
}

# ============================================================================
# Main
# ============================================================================

main() {
    local mode="${1:-single}"

    # Initialize retry state
    retry_state_init

    # Handle special modes
    if [ "$mode" = "--reset-retry" ]; then
        retry_state_reset_all
        log_info "Retry state cleared. Run --loop to start fresh."
        exit 0
    fi

    # Ensure config manifest exists
    if [ ! -f "$CONFIG_DIR/manifest.json" ]; then
        log_info "Generating config manifest..."
        $PYTHON "$CONFIG_DIR/generate_configs.py"
    fi

    mkdir -p "$OUTPUTS_DIR"

    local total_configs
    total_configs=$(get_config_names | wc -w)
    log_info "PINN Hyperparameter Search -- $total_configs configs"
    log_info "Harness-enhanced loop with retry ($MAX_RETRIES_PER_CONFIG max) and escalation ($CONSECUTIVE_FAIL_LIMIT consecutive)"
    log_info "Experiment dir: $EXPERIMENT_DIR"
    echo ""

    if [ "$mode" = "--loop" ]; then
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
            sleep 2
        done

        # Final aggregation
        log_info "Running final aggregation..."
        $PYTHON "$AGGREGATE_SCRIPT" || true
        log_ok "Sweep complete!"

    elif [ "$mode" = "--status" ]; then
        local total=$(get_config_names | wc -w)
        local done=$(count_done)
        local failed=$(count_failed)
        local pending=$((total - done - failed))
        local consecutive=$(retry_state_get_consecutive)
        echo ""
        echo "=== PINN Sweep Status (Harness-Enhanced) ==="
        echo "Total:               $total"
        echo "Done:                $done"
        echo "Failed:              $failed"
        echo "Pending:             $pending"
        echo "Consecutive failures: $consecutive"
        echo "Escalation limit:    $CONSECUTIVE_FAIL_LIMIT"
        echo ""
        echo "Pending configs:"
        for cfg in $(get_pending_configs); do
            local r=$(retry_state_get "$cfg")
            echo "  - $cfg (retries used: $r/$MAX_RETRIES_PER_CONFIG)"
        done
        echo ""
        if [ "$consecutive" -ge "$CONSECUTIVE_FAIL_LIMIT" ]; then
            log_esc "ESCALATION ACTIVE: $consecutive consecutive failures!"
        fi

    else
        # Single cycle
        run_cycle 1
        local remaining
        remaining=$(get_pending_configs)
        if [ -n "$remaining" ]; then
            log_info "$(echo $remaining | wc -w) config(s) remaining"
            log_info "Run --loop to process all"
        fi
    fi
}

main "$@"
