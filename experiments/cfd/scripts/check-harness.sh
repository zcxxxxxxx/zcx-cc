#!/bin/bash
# check-harness.sh — Taste-Invariant Checks for CFD Mesh Sweep
# =============================================================
# Encodes harness standards as executable checks so they are
# enforced forever, not just remembered.
#
# Usage:
#   bash scripts/check-harness.sh            # Run all checks (default: audit)
#   bash scripts/check-harness.sh setup      # Verify environment is ready
#   bash scripts/check-harness.sh audit      # Full integrity audit
#
# Exit codes:
#   0 — All checks pass
#   1 — Warnings (non-critical issues)
#   2 — Errors (critical issues, do not proceed)
#
# =============================================================

set -uo pipefail

# Auto-detect Python: prefer real Python over Windows Store stubs
if command -v python &>/dev/null && python -c "import json; print('ok')" 2>/dev/null | grep -q ok; then
    PYTHON="python"
elif command -v python3 &>/dev/null && python3 -c "import json; print('ok')" 2>/dev/null | grep -q ok; then
    PYTHON="python3"
else
    echo "[FATAL] No working Python found. Install Python 3."
    exit 2
fi

# Convert Git Bash paths to Windows format for native Windows Python
to_win_path() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*) cygpath -w "$1" 2>/dev/null || echo "$1" ;;
        *) echo "$1" ;;
    esac
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CFD_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODE="${1:-audit}"

HAS_ERRORS=0
HAS_WARNINGS=0

echo "============================================================"
echo "CFD Mesh Sweep — Harness Check"
echo "Mode:       ${MODE}"
echo "Target:     ${CFD_DIR}"
echo "Date:       $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "Git SHA:    $(git -C "${CFD_DIR}" rev-parse HEAD 2>/dev/null || echo 'n/a')"
echo "============================================================"
echo ""

# =============================================================
# SETUP CHECKS — Run before starting experiment
# =============================================================

check_setup() {
    echo "--- [Setup] Validating environment ---"

    # S-1: OpenFOAM availability
    if command -v simpleFoam &>/dev/null; then
        echo "[OK] simpleFoam found in PATH"
    else
        echo "[WARN] simpleFoam not in PATH (expected if OpenFOAM not sourced)"
        HAS_WARNINGS=1
    fi

    # S-2: Python availability (output-based, since exit codes are unreliable on Windows)
    if command -v $PYTHON &>/dev/null; then
        PV=$($PYTHON --version 2>&1 || true)
        echo "[OK] Python available (${PV})"
    else
        echo "[ERROR] python3 not found"
        HAS_ERRORS=1
    fi

    # S-3: Required Python packages (output-based detection)
    PY_MISSING=0
    for pkg in yaml json re csv argparse; do
        OUT=$($PYTHON -c "import ${pkg}; print('ok')" 2>&1 || true)
        if echo "$OUT" | grep -q "^ok$"; then
            :
        else
            echo "[ERROR] Python package '${pkg}' not available: ${OUT}"
            PY_MISSING=1
        fi
    done
    if [[ "$PY_MISSING" -eq 0 ]]; then
        echo "[OK] All required Python packages available"
    else
        HAS_ERRORS=1
    fi

    # S-4: Mesh files exist and non-empty
    MISSING=0
    for i in $(seq 1 8); do
        MF="${CFD_DIR}/meshes/mesh_${i}.msh"
        if [[ -f "$MF" && -s "$MF" ]]; then
            :
        else
            echo "[ERROR] Mesh file missing or empty: mesh_${i}.msh"
            MISSING=$((MISSING + 1))
            HAS_ERRORS=1
        fi
    done
    if [[ "$MISSING" -eq 0 ]]; then
        echo "[OK] All 8 mesh files present and non-empty"
    fi

    # S-5: Config YAMLs parse correctly (output-based detection)
    for cfg in "configs/solver_config.yaml" "configs/mesh_list.yaml"; do
        CFG_PATH="$(to_win_path "${CFD_DIR}/${cfg}")"
        OUT=$($PYTHON -c "import yaml, sys
try:
    with open(r'${CFG_PATH}', encoding='utf-8', errors='replace') as f:
        yaml.safe_load(f)
    print('OK')
except Exception as e:
    print('ERROR:', e)
" 2>&1 || true)
        if echo "$OUT" | grep -q "^OK$"; then
            echo "[OK] YAML valid: ${cfg}"
        else
            echo "[ERROR] YAML parse error in ${cfg}: ${OUT}"
            HAS_ERRORS=1
        fi
    done

    # S-6: Template directories present
    TDIR_MISSING=0
    for tdir in "0" "constant" "system"; do
        if [[ -d "${CFD_DIR}/templates/${tdir}" ]]; then
            :
        else
            echo "[ERROR] Template directory missing: templates/${tdir}"
            TDIR_MISSING=1
        fi
    done
    if [[ "$TDIR_MISSING" -eq 0 ]]; then
        echo "[OK] All template directories present (0/, constant/, system/)"
    else
        HAS_ERRORS=1
    fi

    echo ""
}

# =============================================================
# AUDIT CHECKS — Run during/after experiment
# =============================================================

check_audit() {
    echo "--- [Audit] Checking experiment integrity ---"

    # A-1: Verifier independence (taste invariant)
    echo "[Taste] Verifier-writer independence"
    if grep -q "from run_loop\|import run_loop\|run_loop" "${SCRIPT_DIR}/check_convergence.py" 2>/dev/null; then
        echo "  [FAIL] Verifier (check_convergence.py) imports from writer (run_loop.py)!"
        echo "  Context leak: verifier must NOT share code with writer."
        HAS_ERRORS=1
    else
        echo "  [PASS] Verifier is independent from writer."
    fi

    # A-2: Hard stop conditions defined (taste invariant)
    echo "[Taste] Hard stop condition coverage"
    STOPS=0
    for term in "max_iterations" "max_retries" "tolerance" "max_wall_time_hours" "residual_spike_threshold"; do
        if grep -rq "$term" "${CFD_DIR}/configs/" --include="*.yaml" 2>/dev/null; then
            STOPS=$((STOPS + 1))
        fi
    done
    if [[ "$STOPS" -ge 4 ]]; then
        echo "  [PASS] ${STOPS}/5 hard stop criteria found in configs."
    else
        echo "  [WARN] Only ${STOPS}/5 hard stop criteria found."
        HAS_WARNINGS=1
    fi

    # A-3: STATE.md exists with limits
    echo "[Check] STATE.md"
    if [[ -f "${CFD_DIR}/STATE.md" ]]; then
        if grep -qi "hard stop\|Iteration limit\|Wall-clock\|Escalation" "${CFD_DIR}/STATE.md"; then
            echo "  [PASS] STATE.md with hard stop limits found."
        else
            echo "  [WARN] STATE.md missing hard stop documentation."
            HAS_WARNINGS=1
        fi
    else
        echo "  [FAIL] STATE.md not found."
        HAS_ERRORS=1
    fi

    # A-4: Per-mesh result JSON files (output-based detection)
    RESULT_FILES=$(ls "${CFD_DIR}/outputs"/mesh_*_result.json 2>/dev/null || true)
    if [[ -n "$RESULT_FILES" ]]; then
        COUNT=$(echo "$RESULT_FILES" | wc -l)
        echo "[Check] Per-mesh result files: ${COUNT} found."
        for f in $RESULT_FILES; do
            WIN_F="$(to_win_path "$f")"
            STATUS=$($PYTHON -c "import json
d = json.load(open(r'${WIN_F}'))
print(d.get('status', '?'))
" 2>/dev/null || echo "parse-error")
            echo "  $(basename ${f}): status=${STATUS}"
        done
    else
        echo "[INFO] No per-mesh result files (expected before first run)."
    fi

    # A-5: Summary outputs
    if [[ -f "${CFD_DIR}/outputs/summary.md" ]]; then
        echo "[Check] summary.md exists."
        ROWS=$(grep -c "| mesh_" "${CFD_DIR}/outputs/summary.md" 2>/dev/null || echo "0")
        echo "  Result rows: ${ROWS}"
    else
        echo "[INFO] summary.md not yet generated."
    fi
    if [[ -f "${CFD_DIR}/outputs/summary.csv" ]]; then
        echo "[Check] summary.csv exists."
    fi

    # A-6: Log files (output-based convergence check)
    LOG_COUNT=$(ls "${CFD_DIR}/logs"/mesh_*.log 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$LOG_COUNT" -gt 0 ]]; then
        echo "[Check] ${LOG_COUNT} solver log files found."
        for log in "${CFD_DIR}/logs"/mesh_*.log; do
            WIN_LOG="$(to_win_path "$log")"
            OUT=$($PYTHON "${SCRIPT_DIR}/check_convergence.py" "$WIN_LOG" 2>&1 || true)
            if echo "$OUT" | grep -q "^PASS"; then
                echo "  $(basename ${log}): PASS"
            else
                echo "  $(basename ${log}): FAIL"
            fi
        done
    else
        echo "[INFO] No solver logs (expected before first run)."
    fi

    # A-7: Harness plan exists and is current
    echo "[Check] Harness plan"
    PLAN_FILE="${CFD_DIR}/../../docs/harness/active/2026-06-28-cfd-mesh-sweep.md"
    if [[ -f "$PLAN_FILE" ]]; then
        echo "  [PASS] Harness plan found: $(basename $PLAN_FILE)"
    else
        echo "  [WARN] Harness plan not found at docs/harness/active/"
        HAS_WARNINGS=1
    fi

    # A-8: Validation scripts present
    echo "[Check] Validation scripts"
    for chk in "check-residuals.sh" "check-mesh-quality.sh"; do
        if [[ -f "${SCRIPT_DIR}/${chk}" ]]; then
            echo "  [PASS] ${chk} present"
        else
            echo "  [FAIL] ${chk} missing"
            HAS_ERRORS=1
        fi
    done

    # A-9: Git integrity
    echo "[Check] Git integrity"
    cd "${CFD_DIR}"
    UNTRACKED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$UNTRACKED" -eq 0 ]]; then
        echo "  [PASS] Working tree clean."
    else
        echo "  [INFO] ${UNTRACKED} untracked/modified files (expected during active experiment)."
    fi

    echo ""
}

# =============================================================
# MAIN
# =============================================================

case "$MODE" in
    setup)
        check_setup
        ;;
    audit)
        check_setup
        check_audit
        ;;
    *)
        echo "[ERROR] Unknown mode: ${MODE}. Use 'setup' or 'audit'."
        exit 2
        ;;
esac

# =============================================================
# SUMMARY
# =============================================================
echo "=== Check Complete ==="
if [[ "$HAS_ERRORS" -gt 0 ]]; then
    echo "Result: ${HAS_ERRORS} ERROR(S) — resolve before proceeding."
    exit 2
elif [[ "$HAS_WARNINGS" -gt 0 ]]; then
    echo "Result: ${HAS_WARNINGS} WARNING(S) — review items above."
    exit 1
else
    echo "Result: ALL CHECKS PASSED."
    exit 0
fi
