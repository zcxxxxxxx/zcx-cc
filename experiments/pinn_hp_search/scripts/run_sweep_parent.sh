#!/bin/bash
# ============================================================================
# PINN Hyperparameter Search — Parent Orchestrator Loop
#
# Reads STATE.md, picks the next pending config, dispatches the trainer,
# runs the independent verifier, and updates STATE.md.
#
# Features:
#   - Per-config retry (3 retries per config before marking FAILED)
#   - Consecutive failure detection (escalate if 3 configs in a row fail)
#   - 3-level escalation ladder (Level 0/1/2/3)
#   - Retry state persisted in outputs/retry_state.json
#   - Independent writer/verifier separation
#
# Usage:
#   bash scripts/run_sweep_parent.sh              # Run one cycle
#   bash scripts/run_sweep_parent.sh --loop        # Run all cycles in a loop
#   bash scripts/run_sweep_parent.sh --status      # Print current status
#   bash scripts/run_sweep_parent.sh --reset-retry # Clear retry state + reset failed
#
# Exit codes:
#   0 = All configs complete
#   1 = Still have pending configs
#   2 = Error / Limit hit / Escalation triggered
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
RETRY_STATE_FILE="$OUTPUTS_DIR/retry_state.json"
PYTHON="python"

# Timing
START_TIME=$(date +%s)
WALL_LIMIT_HOURS=12
WALL_LIMIT_SEC=$((WALL_LIMIT_HOURS * 3600))
MAX_ITERATIONS=25
MAX_RETRIES_PER_CONFIG=3
CONSECUTIVE_FAILURE_LIMIT=3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_esc()   { echo -e "${MAGENTA}${BOLD}[ESCALATE]${NC} $1"; }

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
# Retry State Management
# ============================================================================

init_retry_state() {
    if [ ! -f "$RETRY_STATE_FILE" ]; then
        mkdir -p "$OUTPUTS_DIR"
        echo '{"per_config_retries": {}, "consecutive_failures": 0, "last_config_status": "NONE", "last_updated": ""}' > "$RETRY_STATE_FILE"
        log_info "Initialized retry state file"
    fi
}

get_retry_count() {
    local config_name="$1"
    $PYTHON -c "
import json
with open(r'${EXPERIMENT_DIR_WIN}/outputs/retry_state.json') as f:
    s = json.load(f)
print(s.get('per_config_retries', {}).get('${config_name}', 0))
" 2>/dev/null || echo "0"
}

set_retry_count() {
    local config_name="$1"
    local count="$2"
    $PYTHON -c "
import json
with open(r'${EXPERIMENT_DIR_WIN}/outputs/retry_state.json') as f:
    s = json.load(f)
if 'per_config_retries' not in s:
    s['per_config_retries'] = {}
s['per_config_retries']['${config_name}'] = $count
s['last_updated'] = '$(get_timestamp)'
with open(r'${EXPERIMENT_DIR_WIN}/outputs/retry_state.json', 'w') as f:
    json.dump(s, f, indent=2)
"
}

get_consecutive_failures() {
    $PYTHON -c "
import json
with open(r'${EXPERIMENT_DIR_WIN}/outputs/retry_state.json') as f:
    s = json.load(f)
print(s.get('consecutive_failures', 0))
" 2>/dev/null || echo "0"
}

set_consecutive_failures() {
    local count="$1"
    $PYTHON -c "
import json
with open(r'${EXPERIMENT_DIR_WIN}/outputs/retry_state.json') as f:
    s = json.load(f)
s['consecutive_failures'] = $count
s['last_updated'] = '$(get_timestamp)'
with open(r'${EXPERIMENT_DIR_WIN}/outputs/retry_state.json', 'w') as f:
    json.dump(s, f, indent=2)
"
}

set_last_config_status() {
    local status="$1"
    $PYTHON -c "
import json
with open(r'${EXPERIMENT_DIR_WIN}/outputs/retry_state.json') as f:
    s = json.load(f)
s['last_config_status'] = '${status}'
s['last_updated'] = '$(get_timestamp)'
with open(r'${EXPERIMENT_DIR_WIN}/outputs/retry_state.json', 'w') as f:
    json.dump(s, f, indent=2)
"
}

reset_retry_state() {
    echo '{"per_config_retries": {}, "consecutive_failures": 0, "last_config_status": "NONE", "last_updated": ""}' > "$RETRY_STATE_FILE"
    log_ok "Retry state cleared"
}

clear_config_retries() {
    local config_name="$1"
    $PYTHON -c "
import json
with open(r'${EXPERIMENT_DIR_WIN}/outputs/retry_state.json') as f:
    s = json.load(f)
if 'per_config_retries' in s and '${config_name}' in s['per_config_retries']:
    del s['per_config_retries']['${config_name}']
with open(r'${EXPERIMENT_DIR_WIN}/outputs/retry_state.json', 'w') as f:
    json.dump(s, f, indent=2)
"
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
            if [ "$status" != "DONE" ] && [ "$status" != "FAILED_NAN" ] && [ "$status" != "FAILED_RETRY_EXHAUSTED" ]; then
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
        if [ "$status" = "FAILED_NAN" ] || [ "$status" = "FAILED_RETRY_EXHAUSTED" ] || [ "$status" = "FAILED_VERIFICATION" ]; then
            count=$((count + 1))
        fi
    done
    echo "$count"
}

get_escalation_level() {
    local consecutive
    consecutive=$(get_consecutive_failures)
    if [ "$consecutive" -ge 3 ]; then
        echo "3"
    elif [ "$consecutive" -ge 1 ]; then
        echo "2"
    else
        echo "0"
    fi
}

get_escalation_label() {
    local level="$1"
    case "$level" in
        0) echo "Level 0 — nominal" ;;
        1) echo "Level 1 — single failure, auto-retry" ;;
        2) echo "Level 2 — retries exhausted on config" ;;
        3) echo "Level 3 — 3 consecutive configs failed, PAUSED" ;;
        *) echo "Level $level — unknown" ;;
    esac
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
# Escalation Alert
# ============================================================================

print_escalation_alert() {
    local consecutive="$1"
    local failed_configs="$2"

    echo ""
    echo -e "${RED}${BOLD}============================================================${NC}"
    echo -e "${RED}${BOLD}  ESCALATION: $consecutive consecutive configs failed!${NC}"
    echo -e "${RED}${BOLD}  Loop PAUSED — human intervention required${NC}"
    echo -e "${RED}${BOLD}============================================================${NC}"
    echo ""
    echo -e "${YELLOW}  Last failed configs:${NC}"
    for cfg in $failed_configs; do
        echo -e "    - ${RED}$cfg${NC}"
    done
    echo ""
    echo -e "${YELLOW}  Possible causes:${NC}"
    echo "    1. Learning rate too high — check LR scheduler config"
    echo "    2. PDE parameters incorrect — verify nu, x_range, t_range"
    echo "    3. Environment issue — check Python/PyTorch installation"
    echo "    4. Data generation bug — check generate_collocation_points"
    echo ""
    echo -e "${CYAN}  To resume after fixing:${NC}"
    echo "    bash scripts/run_sweep_parent.sh --loop"
    echo ""
    echo -e "${CYAN}  To reset retry state:${NC}"
    echo "    bash scripts/run_sweep_parent.sh --reset-retry"
    echo ""
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
    local consecutive=$(get_consecutive_failures)
    local esc_level=$(get_escalation_level)
    local esc_label=$(get_escalation_label "$esc_level")
    local retry_details=""

    # Build retry detail lines
    for cfg in $(get_config_names); do
        local rc
        rc=$(get_retry_count "$cfg")
        if [ "$rc" -gt 0 ]; then
            local m="$OUTPUTS_DIR/$cfg/metrics.json"
            local s
            s=$(py_metrics_status "$m")
            if [ "$s" != "DONE" ]; then
                retry_details="$retry_details  - $cfg: $rc/3 retries\n"
            fi
        fi
    done

    cat > "$STATE_FILE" << STATE_EOF
# Loop State — PINN Hyperparameter Search

**Status:** ${pending}/${total} pending — $done done, $failed failed

**Cycle info:**
- Started: $(date -u -d "@$START_TIME" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
- Last run: $(get_timestamp)
- Iterations: $iteration
- Wall clock elapsed: $((($(date +%s) - START_TIME) / 60)) minutes

**Progress:**
STATE_EOF

    for cfg in $(get_config_names); do
        local m="$OUTPUTS_DIR/$cfg/metrics.json"
        local s
        s=$(py_metrics_status "$m")
        case "$s" in
            DONE)
                echo "- [x] $cfg: DONE" >> "$STATE_FILE" ;;
            FAILED_NAN|FAILED_VERIFICATION|FAILED_RETRY_EXHAUSTED)
                echo "- [-] $cfg: FAILED ($s)" >> "$STATE_FILE" ;;
            MISSING)
                echo "- [ ] $cfg: pending" >> "$STATE_FILE" ;;
            *)
                echo "- [~] $cfg: $s" >> "$STATE_FILE" ;;
        esac
    done

    cat >> "$STATE_FILE" << STATE_EOF

**Failures (last cycle):**
- $last_config: $last_status
STATE_EOF

    if [ -n "$retry_details" ]; then
        printf "\n**Active retries:**\n$retry_details" >> "$STATE_FILE"
    fi

    cat >> "$STATE_FILE" << STATE_EOF

**Next step:**
$next_step

**Limits:**
- Max iterations: $MAX_ITERATIONS
- Max retries per config: $MAX_RETRIES_PER_CONFIG
- Wall clock limit: $WALL_LIMIT_HOURS hours
- Consecutive failure limit: $CONSECUTIVE_FAILURE_LIMIT
- Current iteration: $iteration
- Current wall elapsed: $((($(date +%s) - START_TIME) / 60)) min
- Consecutive failures: $consecutive

**Escalation level:** $esc_label
STATE_EOF

    log_info "STATE.md updated"
}

# ============================================================================
# Check Escalation
# ============================================================================

check_escalation() {
    local consecutive
    consecutive=$(get_consecutive_failures)

    if [ "$consecutive" -ge "$CONSECUTIVE_FAILURE_LIMIT" ]; then
        # Build list of last failed configs for the alert
        local failed_list=""
        for cfg in $(get_config_names); do
            local m="$OUTPUTS_DIR/$cfg/metrics.json"
            local s
            s=$(py_metrics_status "$m")
            if [ "$s" = "FAILED_NAN" ] || [ "$s" = "FAILED_VERIFICATION" ] || [ "$s" = "FAILED_RETRY_EXHAUSTED" ]; then
                failed_list="$cfg $failed_list"
            fi
        done
        # Take last 3
        local last_three=$(echo "$failed_list" | awk '{for(i=1;i<=3;i++) print $i}')

        print_escalation_alert "$consecutive" "$last_three"
        log_esc "3 consecutive configs failed. Loop PAUSED."

        update_state "$iteration" "SYSTEM" "ESCALATION_LEVEL_3" \
            "ESCALATION: 3 consecutive configs failed. Fix root cause, then run: bash scripts/run_sweep_parent.sh --loop"

        return 1  # Escalation triggered
    fi
    return 0
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
        $PYTHON "$AGGREGATE_SCRIPT"
        exit 2
    fi

    # Check pre-emptive escalation (in case loop was resumed after pause without reset)
    if ! check_escalation; then
        exit 2
    fi

    # Find next pending config
    local next_config
    next_config=$(get_first_pending)

    if [ -z "$next_config" ]; then
        log_ok "All configs processed!"
        update_state "$iteration" "none" "complete" "All configs processed. Run aggregation."
        log_info "Running aggregation..."
        $PYTHON "$AGGREGATE_SCRIPT" || log_warn "Aggregation script had issues"
        log_ok "Sweep complete! See $OUTPUTS_DIR/sweep_ranking.md"
        exit 0
    fi

    # Check retry count for this config
    local retry_count
    retry_count=$(get_retry_count "$next_config")

    if [ "$retry_count" -ge "$MAX_RETRIES_PER_CONFIG" ]; then
        log_warn "$next_config has exhausted $MAX_RETRIES_PER_CONFIG retries. Marking FAILED."
        # Mark as failed by writing metrics
        mkdir -p "$OUTPUTS_DIR/$next_config"
        cat > "$OUTPUTS_DIR/$next_config/metrics.json" << METRICS_EOF
{
    "status": "FAILED_RETRY_EXHAUSTED",
    "config_name": "$next_config",
    "error": "$MAX_RETRIES_PER_CONFIG retries exhausted",
    "steps_completed": 0,
    "wall_time_sec": 0
}
METRICS_EOF
        # Copy config for reference
        if [ -f "$CONFIG_DIR/$next_config.json" ]; then
            cp "$CONFIG_DIR/$next_config.json" "$OUTPUTS_DIR/$next_config/config.json"
        fi

        # Increment consecutive failures
        local consecutive
        consecutive=$(get_consecutive_failures)
        consecutive=$((consecutive + 1))
        set_consecutive_failures "$consecutive"
        set_last_config_status "FAILED_RETRY_EXHAUSTED"

        log_warn "Consecutive failures: $consecutive"

        update_state "$iteration" "$next_config" "FAILED_RETRY_EXHAUSTED" \
            "Config $next_config exhausted retries. $(get_first_pending || echo 'All configs processed.')"

        # Check escalation
        if ! check_escalation; then
            exit 2
        fi

        return 0
    fi

    log_info "=== Cycle $iteration: Processing $next_config ==="
    if [ "$retry_count" -gt 0 ]; then
        log_warn "This is retry $((retry_count + 1))/$MAX_RETRIES_PER_CONFIG for $next_config"
    fi

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

    # --- STEP 3: Update State with Retry/Consecutive Logic --- #
    local next_step=""
    local cycle_status=""
    local consecutive
    consecutive=$(get_consecutive_failures)

    if [ "$actual_status" = "DONE" ] && [ $VERIFY_EXIT -eq 0 ]; then
        # SUCCESS — config passed
        cycle_status="DONE"
        log_ok "$next_config: PASSED (trained in ${train_duration}s)"

        # Clear retry count for this config
        clear_config_retries "$next_config"
        # Reset consecutive failures counter (streak broken)
        consecutive=0
        set_consecutive_failures 0
        set_last_config_status "DONE"

        next_step="$(get_first_pending)"
        if [ -z "$next_step" ]; then
            next_step="All configs complete. Run: python scripts/aggregate_results.py"
        else
            next_step="Run next pending config: $next_step"
        fi

    elif [ "$actual_status" = "FAILED_NAN" ]; then
        # FAILURE — NaN encountered, handle retry logic
        local new_retry=$((retry_count + 1))
        set_retry_count "$next_config" "$new_retry"
        set_last_config_status "FAILED_NAN"

        if [ "$new_retry" -lt "$MAX_RETRIES_PER_CONFIG" ]; then
            # Level 1: auto-retry
            cycle_status="FAILED_NAN (retry ${new_retry}/${MAX_RETRIES_PER_CONFIG})"
            log_warn "$next_config: FAILED (NaN) — retry ${new_retry}/${MAX_RETRIES_PER_CONFIG}"

            # Remove metrics so it appears as pending again
            rm -f "$output_dir/metrics.json"

            next_step="Retry $next_config (attempt ${new_retry}/${MAX_RETRIES_PER_CONFIG})"
            update_state "$iteration" "$next_config" "$cycle_status" "$next_step"

            log_info "Re-queued $next_config for retry ${new_retry}/${MAX_RETRIES_PER_CONFIG}"
            return 0
        else
            # Level 2: retries exhausted
            cycle_status="FAILED_RETRY_EXHAUSTED"
            log_warn "$next_config: FAILED after $MAX_RETRIES_PER_CONFIG retries"

            # Update metrics status
            local metrics_path="$output_dir/metrics.json"
            if [ -f "$metrics_path" ]; then
                $PYTHON -c "
import json
with open(r'${metrics_path}') as f:
    m = json.load(f)
m['status'] = 'FAILED_RETRY_EXHAUSTED'
with open(r'${metrics_path}', 'w') as f:
    json.dump(m, f, indent=2)
"
            fi

            # Increment consecutive failures
            consecutive=$((consecutive + 1))
            set_consecutive_failures "$consecutive"

            next_step="$(get_first_pending)"
            if [ -z "$next_step" ]; then
                next_step="All configs processed. Run: python scripts/aggregate_results.py"
            else
                next_step="Run next pending config: $next_step"
            fi
        fi

    else
        # FAILURE — unknown error
        local new_retry=$((retry_count + 1))
        set_retry_count "$next_config" "$new_retry"
        set_last_config_status "FAILED"

        if [ "$new_retry" -lt "$MAX_RETRIES_PER_CONFIG" ]; then
            # Level 1: auto-retry
            cycle_status="FAILED (retry ${new_retry}/${MAX_RETRIES_PER_CONFIG})"
            log_warn "$next_config: FAILED — retry ${new_retry}/${MAX_RETRIES_PER_CONFIG}"

            # Remove metrics so it appears as pending again
            rm -f "$output_dir/metrics.json"

            next_step="Retry $next_config (attempt ${new_retry}/${MAX_RETRIES_PER_CONFIG})"
            update_state "$iteration" "$next_config" "$cycle_status" "$next_step"

            log_info "Re-queued $next_config for retry ${new_retry}/${MAX_RETRIES_PER_CONFIG}"
            return 0
        else
            # Level 2: retries exhausted
            cycle_status="FAILED_RETRY_EXHAUSTED"
            log_warn "$next_config: FAILED after $MAX_RETRIES_PER_CONFIG retries"

            local metrics_path="$output_dir/metrics.json"
            if [ -f "$metrics_path" ]; then
                $PYTHON -c "
import json
with open(r'${metrics_path}') as f:
    m = json.load(f)
m['status'] = 'FAILED_RETRY_EXHAUSTED'
with open(r'${metrics_path}', 'w') as f:
    json.dump(m, f, indent=2)
"
            fi

            consecutive=$((consecutive + 1))
            set_consecutive_failures "$consecutive"

            next_step="$(get_first_pending)"
            if [ -z "$next_step" ]; then
                next_step="All configs processed. Run: python scripts/aggregate_results.py"
            else
                next_step="Run next pending config: $next_step"
            fi
        fi
    fi

    update_state "$iteration" "$next_config" "$cycle_status" "$next_step"

    # --- STEP 4: Check Limits --- #
    if [ "$consecutive" -ge "$CONSECUTIVE_FAILURE_LIMIT" ]; then
        log_error "ESCALATION: $consecutive consecutive configs failed!"
        log_error "Check system/environment before resuming."
        update_state "$iteration" "$next_config" "$cycle_status" \
            "ESCALATION: $consecutive consecutive configs failed. Fix root cause and retry."
        print_escalation_alert "$consecutive" "$next_config"
        exit 2
    fi

    if [ $iteration -ge $MAX_ITERATIONS ]; then
        log_error "Max iterations ($MAX_ITERATIONS) reached!"
        log_error "Run aggregation on partial results."
        $PYTHON "$AGGREGATE_SCRIPT" || log_warn "Aggregation script had issues"
        exit 2
    fi

    local total_failed
    total_failed=$(count_failed)
    if [ $total_failed -ge $CONSECUTIVE_FAILURE_LIMIT ]; then
        log_warn "Total failures: $total_failed (not necessarily consecutive)"
    fi

    return 0
}

# ============================================================================
# Main
# ============================================================================

main() {
    local mode="${1:-single}"

    # Initialize retry state
    mkdir -p "$OUTPUTS_DIR"
    init_retry_state

    # Ensure config manifest exists
    if [ ! -f "$CONFIG_DIR/manifest.json" ]; then
        log_info "Generating config manifest..."
        $PYTHON "$CONFIG_DIR/generate_configs.py"
    fi

    # Handle --reset-retry
    if [ "$mode" = "--reset-retry" ]; then
        reset_retry_state
        log_ok "Retry state reset. You can now resume the loop."
        echo ""
        log_info "To resume: bash scripts/run_sweep_parent.sh --loop"
        exit 0
    fi

    local total_configs
    total_configs=$(get_config_names | wc -w)
    log_info "PINN Hyperparameter Search — $total_configs configs"
    log_info "Experiment dir: $EXPERIMENT_DIR"
    log_info "Output dir: $OUTPUTS_DIR"
    log_info "Wall clock limit: ${WALL_LIMIT_HOURS}h"
    log_info "Max retries per config: $MAX_RETRIES_PER_CONFIG"
    log_info "Consecutive failure limit: $CONSECUTIVE_FAILURE_LIMIT"
    echo ""

    if [ "$mode" = "--loop" ]; then
        # Loop mode: keep running until done or limit hit
        local iter=1
        while true; do
            log_info "--- Loop iteration $iter ---"
            run_cycle $iter || {
                local rc=$?
                if [ $rc -eq 2 ]; then
                    log_error "Loop terminated due to limit or escalation."
                fi
                exit $rc
            }
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

        # Final aggregation
        log_info "Running final aggregation..."
        $PYTHON "$AGGREGATE_SCRIPT" || log_warn "Aggregation script had issues"
        log_ok "Sweep complete! See $OUTPUTS_DIR/sweep_ranking.md"

    elif [ "$mode" = "--status" ]; then
        # Status mode: print current progress
        local total=$(get_config_names | wc -w)
        local done=$(count_done)
        local failed=$(count_failed)
        local pending=$((total - done - failed))
        local consecutive=$(get_consecutive_failures)
        local esc_level=$(get_escalation_level)
        local esc_label=$(get_escalation_label "$esc_level")

        echo ""
        echo "=== PINN Sweep Status ==="
        echo "Total:       $total"
        echo "Done:        $done"
        echo "Failed:      $failed"
        echo "Pending:     $pending"
        echo "Consecutive failures: $consecutive"
        echo "Escalation:  $esc_label"
        echo ""
        echo "Pending configs:"
        for cfg in $(get_pending_configs); do
            local rc
            rc=$(get_retry_count "$cfg")
            if [ "$rc" -gt 0 ]; then
                echo "  - $cfg (retry $rc/$MAX_RETRIES_PER_CONFIG)"
            else
                echo "  - $cfg"
            fi
        done
        echo ""

    elif [ "$mode" = "--retry-status" ]; then
        # Show detailed retry status
        echo ""
        echo "=== Retry State ==="
        if [ -f "$RETRY_STATE_FILE" ]; then
            $PYTHON -c "
import json
with open(r'${EXPERIMENT_DIR_WIN}/outputs/retry_state.json') as f:
    s = json.load(f)
print('Consecutive failures:', s.get('consecutive_failures', 0))
print('Last config status:', s.get('last_config_status', 'NONE'))
print('Last updated:', s.get('last_updated', 'NEVER'))
print()
retries = s.get('per_config_retries', {})
if retries:
    print('Per-config retries:')
    for cfg, count in sorted(retries.items()):
        print(f'  {cfg}: {count}/3 retries')
else:
    print('No active retries')
"
        else
            echo "No retry state file (loop has not run yet)"
        fi
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
