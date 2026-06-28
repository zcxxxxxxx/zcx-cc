#!/bin/bash
# check-mesh-quality.sh — Validate mesh file presence and quality metadata
# ============================================================================
# Taste invariant: all mesh files must exist, be non-empty, and have valid
# metadata in mesh_list.yaml.
#
# Usage:
#   bash scripts/check-mesh-quality.sh
#   bash scripts/check-mesh-quality.sh meshes/mesh_1.msh
#
# Exit codes:
#   0 — All checks pass
#   1 — Warnings (e.g., small mesh, unusual cell count)
#   2 — Errors (missing files, empty files)
# ============================================================================

set -uo pipefail

# Auto-detect Python (handle Windows Store stub issue)
if command -v python &>/dev/null && python -c "import json; print('ok')" 2>/dev/null | grep -q ok; then
    PYTHON="python"
elif command -v python3 &>/dev/null && python3 -c "import json; print('ok')" 2>/dev/null | grep -q ok; then
    PYTHON="python3"
else
    echo "[FATAL] No working Python found."
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

HAS_ERRORS=0
HAS_WARNINGS=0

echo "=== Mesh Quality Check ==="
echo "Target: ${CFD_DIR}/meshes/"
echo ""

# Check all 8 meshes exist and record sizes
echo "--- Mesh file inventory ---"
for i in $(seq 1 8); do
    MF="${CFD_DIR}/meshes/mesh_${i}.msh"
    if [[ -f "$MF" ]]; then
        SIZE=$(stat -c%s "$MF" 2>/dev/null || stat -f%z "$MF" 2>/dev/null || echo "?")
        echo "  mesh_${i}.msh: ${SIZE} bytes"
        if [[ "$SIZE" -lt 50 ]]; then
            echo "    [WARN] Very small mesh file (possibly a stub)"
            HAS_WARNINGS=1
        fi
    else
        echo "  [ERROR] mesh_${i}.msh: NOT FOUND"
        HAS_ERRORS=1
    fi
done

echo ""
echo "--- Mesh metadata validation ---"
MESH_YAML="${CFD_DIR}/configs/mesh_list.yaml"
WIN_YAML="$(to_win_path "$MESH_YAML")"
if [[ -f "$MESH_YAML" ]]; then
    echo "[OK] mesh_list.yaml found"

    # Check YAML entry count (output-based, Windows-safe path)
    YAML_COUNT=$($PYTHON -c "
import yaml
with open(r'${WIN_YAML}', encoding='utf-8', errors='replace') as f:
    data = yaml.safe_load(f)
print(len(data.get('meshes', [])))
" 2>/dev/null || echo "0")

    if [[ "$YAML_COUNT" -eq 8 ]]; then
        echo "[OK] mesh_list.yaml defines ${YAML_COUNT} meshes"
    else
        echo "[WARN] mesh_list.yaml defines ${YAML_COUNT} meshes (expected 8)"
        HAS_WARNINGS=1
    fi

    # Check all entries have required fields (output-based)
    FIELD_CHECK=$($PYTHON -c "
import yaml
with open(r'${WIN_YAML}', encoding='utf-8', errors='replace') as f:
    data = yaml.safe_load(f)
errors = 0
for m in data.get('meshes', []):
    required = ['id', 'file', 'description', 'airfoil', 'mesh_type', 'cell_count']
    for r in required:
        if r not in m or m[r] is None:
            print(f'[ERROR] mesh {m.get(\"id\", \"?\")} missing field: {r}')
            errors += 1
if errors == 0:
    print('[OK] All mesh entries have required fields')
" 2>&1 || true)
    if echo "$FIELD_CHECK" | grep -q "\[OK\]"; then
        echo "  $FIELD_CHECK"
    else
        echo "  $FIELD_CHECK"
        HAS_ERRORS=1
    fi
else
    echo "[ERROR] mesh_list.yaml not found"
    HAS_ERRORS=1
fi

echo ""
if [[ "$HAS_ERRORS" -gt 0 ]]; then
    echo "Result: ${HAS_ERRORS} ERROR(S) — fix before running simulation."
    exit 2
elif [[ "$HAS_WARNINGS" -gt 0 ]]; then
    echo "Result: WARNINGS — review items above."
    exit 1
else
    echo "Result: ALL CHECKS PASSED."
    exit 0
fi
