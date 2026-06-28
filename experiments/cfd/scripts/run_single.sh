#!/bin/bash
# Run a single mesh through the CFD turbulence simulation pipeline
# Usage: bash scripts/run_single.sh --mesh mesh_1
#
# This script follows the conventions established in
# experiments/pinn_lora_rank_sweep/scripts/run_single.sh

set -euo pipefail

# ---------- Paths ----------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ---------- Parse arguments ----------
MESH_ID=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mesh) MESH_ID="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$MESH_ID" ]]; then
  echo "Usage: $0 --mesh <mesh_id>"
  echo "  mesh_id: one of mesh_1 .. mesh_8"
  exit 1
fi

# ---------- Validate mesh ----------
MESH_FILE="${PROJECT_DIR}/meshes/${MESH_ID}.msh"
if [[ ! -f "$MESH_FILE" ]]; then
  echo "[ERROR] Mesh file not found: ${MESH_FILE}"
  exit 1
fi

# ---------- Output paths ----------
OUTPUT_DIR="${PROJECT_DIR}/outputs/${MESH_ID}"
CASE_DIR="${PROJECT_DIR}/cases/${MESH_ID}"
LOG_DIR="${PROJECT_DIR}/logs"
SOLVER_LOG="${LOG_DIR}/${MESH_ID}.log"
RESULT_FILE="${OUTPUT_DIR}/result.json"

mkdir -p "$OUTPUT_DIR" "$CASE_DIR" "$LOG_DIR"

# ---------- Resume check ----------
if [[ -f "$RESULT_FILE" ]]; then
  STATUS=$(python3 -c "import json; d=json.load(open('${RESULT_FILE}')); print(d.get('status',''))" 2>/dev/null || echo "")
  if [[ "$STATUS" == "PASS" || "$STATUS" == "FAIL" ]]; then
    echo "[SKIP] ${MESH_ID} already completed (status=${STATUS}). Remove ${RESULT_FILE} to re-run."
    exit 0
  fi
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY RUN] Would process: ${MESH_ID}"
  echo "  Mesh:      ${MESH_FILE}"
  echo "  Case dir:  ${CASE_DIR}"
  echo "  Output:    ${OUTPUT_DIR}"
  echo "  Solver:    simpleFoam (k-omega SST, Re=1e6, tolerance=1e-6)"
  exit 0
fi

# ---------- Environment logging ----------
{
  echo "=============================================="
  echo "CFD Single Mesh Run"
  echo "=============================================="
  echo "Mesh ID:      ${MESH_ID}"
  echo "Mesh File:    ${MESH_FILE}"
  echo "Case Dir:     ${CASE_DIR}"
  echo "Output:       ${OUTPUT_DIR}"
  echo "Solver:       simpleFoam (kOmegaSST)"
  echo "Re:           1e6"
  echo "Tolerance:    1e-6"
  echo "Max Retries:  1"
  echo "Date:         $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "Host:         $(hostname 2>/dev/null || echo 'unknown')"
  echo "Git SHA:      $(git -C "${PROJECT_DIR}" rev-parse HEAD 2>/dev/null || echo 'n/a')"
  echo "Command:      $0 --mesh ${MESH_ID}"
  echo "=============================================="
} | tee "${OUTPUT_DIR}/environment.log"

# ---------- Run via Python orchestrator (single mesh) ----------
cd "${PROJECT_DIR}"

python3 "${SCRIPT_DIR}/run_loop.py" \
  --project-dir "${PROJECT_DIR}" \
  --mesh-list "${MESH_ID}" \
  2>&1 | tee "${OUTPUT_DIR}/run.log"

EXIT_CODE=${PIPESTATUS[0]}

# ---------- Post-run summary ----------
if [[ $EXIT_CODE -eq 0 ]]; then
  echo "[DONE] ${MESH_ID} completed successfully."
else
  echo "[FAIL] ${MESH_ID} encountered errors."
fi

exit $EXIT_CODE
