#!/bin/bash
# CFD Loop Audit Script
# Checks an active or completed CFD batch loop for health and completeness.
#
# Usage:
#   bash scripts/cfd-loop-audit.sh                    # Audit current directory
#   bash scripts/cfd-loop-audit.sh /path/to/cfd/      # Audit specific CFD dir
#
# Exit codes:
#   0 — All checks pass
#   1 — Issues found (warnings)
#   2 — Critical issues found (errors)

set -euo pipefail

CFD_DIR="${1:-$(pwd)}"
cd "$CFD_DIR"

echo "=== CFD Loop Audit ==="
echo "Target: ${CFD_DIR}"
echo "Date:   $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo ""

HAS_ERRORS=0
HAS_WARNINGS=0

# ---- 1. Check harness STATE.md ----
echo "--- [1/8] Checking STATE.md ---"
if [ -f "STATE.md" ]; then
    echo "[OK] STATE.md found."
    if grep -qi "continue\|to be determined\|TBD\|pending$" "STATE.md" 2>/dev/null; then
        echo "  [INFO] STATE.md has pending items (expected if loop is active)."
    fi
else
    echo "[WARN] No STATE.md found. Loop lacks persistent memory."
    HAS_WARNINGS=1
fi
echo ""

# ---- 2. Check hard stop conditions ----
echo "--- [2/8] Checking hard stop conditions ---"
STOPS_FOUND=0
for key in "max_iterations" "max_retries" "tolerance" "max_wall"; do
    if grep -rq "$key" --include="*.yaml" --include="*.py" --include="*.md" . 2>/dev/null; then
        STOPS_FOUND=$((STOPS_FOUND + 1))
    fi
done
if [ "$STOPS_FOUND" -ge 3 ]; then
    echo "[OK] Hard stop conditions detected (${STOPS_FOUND}/4 criteria found)."
else
    echo "[WARN] Only ${STOPS_FOUND}/4 hard stop criteria found. Loop may run unbounded."
    HAS_WARNINGS=1
fi
echo ""

# ---- 3. Check verification gates ----
echo "--- [3/8] Checking verification gates ---"
if [ -f "scripts/check_convergence.py" ]; then
    echo "[OK] Standalone verifier found: scripts/check_convergence.py"
    # Check it has no imports from run_loop.py
    if grep -q "from run_loop\|import run_loop\|run_loop" "scripts/check_convergence.py" 2>/dev/null; then
        echo "  [WARN] Verifier imports from run_loop — potential context leak!"
        HAS_WARNINGS=1
    else
        echo "  [OK] Verifier has no dependency on writer (run_loop.py)."
    fi
else
    echo "[WARN] No standalone verifier found."
    HAS_WARNINGS=1
fi
echo ""

# ---- 4. Check outputs exist and are valid ----
echo "--- [4/8] Checking outputs ---"
SUMMARY_MD="outputs/summary.md"
SUMMARY_CSV="outputs/summary.csv"

if [ -f "$SUMMARY_MD" ]; then
    echo "[OK] summary.md found."
    # Check it has result rows
    ROW_COUNT=$(grep -c "| mesh_" "$SUMMARY_MD" 2>/dev/null || echo "0")
    if [ "${ROW_COUNT}" -gt 0 ] 2>/dev/null; then
        echo "  [OK] ${ROW_COUNT} mesh result rows in summary.md."
        PASS_COUNT=$(grep "| PASS |" "$SUMMARY_MD" 2>/dev/null | wc -l || echo "0")
        FAIL_COUNT=$(grep "| FAIL |" "$SUMMARY_MD" 2>/dev/null | wc -l || echo "0")
        echo "  PASS: ${PASS_COUNT}, FAIL: ${FAIL_COUNT}"
    else
        echo "  [WARN] summary.md exists but has no mesh result rows."
        HAS_WARNINGS=1
    fi
else
    echo "[INFO] summary.md not found (expected if loop hasn't run yet)."
fi

if [ -f "$SUMMARY_CSV" ]; then
    echo "[OK] summary.csv found."
    CSV_ROWS=$(tail -n +2 "$SUMMARY_CSV" 2>/dev/null | wc -l || echo "0")
    echo "  ${CSV_ROWS} data rows."
fi
echo ""

# ---- 5. Check per-mesh result JSON files (resume safety) ----
echo "--- [5/8] Checking per-mesh result files (resume safety) ---"
RESULT_FILES=$(ls outputs/mesh_*_result.json 2>/dev/null || true)
if [ -n "$RESULT_FILES" ]; then
    echo "[OK] Per-mesh result files found:"
    for f in $RESULT_FILES; do
        STATUS=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('status','?'))" 2>/dev/null || echo "parse-error")
        echo "  ${f}: status=${STATUS}"
    done
else
    echo "[INFO] No per-mesh result files found (expected before first run)."
fi
echo ""

# ---- 6. Check log files ----
echo "--- [6/8] Checking solver logs ---"
LOG_COUNT=$(ls logs/mesh_*.log 2>/dev/null | wc -l | tr -d ' ' || echo "0")
if [ "${LOG_COUNT}" -gt 0 ] 2>/dev/null; then
    echo "[OK] ${LOG_COUNT} solver log files found."
    # Quick convergence check using standalone verifier
    for log in logs/mesh_*.log; do
        if [ -f "scripts/check_convergence.py" ]; then
            VERDICT=$(python3 "scripts/check_convergence.py" "$log" 2>/dev/null && echo "PASS" || echo "FAIL")
            echo "  ${log}: ${VERDICT}"
        fi
    done
else
    echo "[INFO] No solver logs found (expected before first run)."
fi
echo ""

# ---- 7. Check mesh files exist ----
echo "--- [7/8] Checking mesh files ---"
MESH_COUNT=0
for i in 1 2 3 4 5 6 7 8; do
    if [ -f "meshes/mesh_${i}.msh" ]; then
        MESH_COUNT=$((MESH_COUNT + 1))
    fi
done
echo "[OK] ${MESH_COUNT}/8 mesh files present." 2>/dev/null
if [ "$MESH_COUNT" -ne 8 ]; then
    echo "[ERROR] Missing mesh files! Expected 8, found ${MESH_COUNT}."
    HAS_ERRORS=1
fi
echo ""

# ---- 8. Check config files ----
echo "--- [8/8] Checking configuration files ---"
for cfg in "configs/solver_config.yaml" "configs/mesh_list.yaml"; do
    if [ -f "$cfg" ]; then
        echo "[OK] ${cfg}"
        # Validate YAML syntax
        python3 -c "import yaml; yaml.safe_load(open('$cfg'))" 2>/dev/null && \
            echo "  [OK] YAML syntax valid." || \
            echo "  [INFO] YAML validation skipped (pyyaml not available) or parse error."
    else
        echo "[ERROR] ${cfg} not found!"
        HAS_ERRORS=1
    fi
done
echo ""

# ---- Summary ----
echo "=== Audit Complete ==="
if [ "$HAS_ERRORS" -gt 0 ]; then
    echo "Result: CRITICAL ISSUES FOUND — see errors above."
    exit 2
elif [ "$HAS_WARNINGS" -gt 0 ]; then
    echo "Result: WARNINGS FOUND — review items above."
    exit 1
else
    echo "Result: ALL CHECKS PASSED."
    exit 0
fi
