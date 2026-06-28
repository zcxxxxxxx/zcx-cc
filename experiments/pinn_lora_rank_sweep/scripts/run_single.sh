#!/bin/bash
# Run a single PINN LoRA rank configuration
# Usage: bash scripts/run_single.sh --rank 4 --seed 42 --epochs 1000
#
# This script is designed to be reproducible: it records the commit SHA,
# exact command, and all relevant environment information in the output log.

set -euo pipefail

# ---------- Parse arguments ----------
RANK=4
SEED=42
EPOCHS=1000
CONFIG_DIR="configs"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rank) RANK="$2"; shift 2 ;;
    --seed) SEED="$2"; shift 2 ;;
    --epochs) EPOCHS="$2"; shift 2 ;;
    --config-dir) CONFIG_DIR="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ---------- Paths ----------
RUN_ID="rank${RANK}_seed${SEED}"
CONFIG="${CONFIG_DIR}/rank${RANK}.yaml"
OUTPUT_DIR="outputs/${RUN_ID}"
CHECKPOINT_DIR="checkpoints/${RUN_ID}"

# ---------- Resume check (skip if already completed) ----------
if [[ -f "${OUTPUT_DIR}/metrics.json" ]]; then
  FINAL_LOSS=$(python3 -c "import json; d=json.load(open('${OUTPUT_DIR}/metrics.json')); print(d.get('final_loss', 'none'))" 2>/dev/null || echo "none")
  if [[ "$FINAL_LOSS" != "none" ]]; then
    echo "[SKIP] ${RUN_ID} already completed with final_loss=${FINAL_LOSS}. Remove ${OUTPUT_DIR}/metrics.json to force re-run."
    exit 0
  fi
fi

# ---------- Create output directories ----------
mkdir -p "${OUTPUT_DIR}" "${CHECKPOINT_DIR}"

# ---------- Log environment ----------
{
  echo "=============================================="
  echo "PINN LoRA Rank Sweep — Single Run"
  echo "=============================================="
  echo "Run ID:       ${RUN_ID}"
  echo "Rank:         ${RANK}"
  echo "Seed:         ${SEED}"
  echo "Epochs:       ${EPOCHS}"
  echo "Config:       ${CONFIG}"
  echo "Output:       ${OUTPUT_DIR}"
  echo "Date:         $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "Host:         $(hostname 2>/dev/null || echo 'unknown')"
  echo "Git SHA:      $(git rev-parse HEAD 2>/dev/null || echo 'not a git repo')"
  echo "Python:       $(python3 --version 2>/dev/null || echo 'not found')"
  echo "Command:      $0 --rank ${RANK} --seed ${SEED} --epochs ${EPOCHS}"
  echo "=============================================="
} | tee "${OUTPUT_DIR}/environment.log"

# ---------- Training command ----------
# Replace this with the actual PINN training command
python3 train.py \
  --config "${CONFIG}" \
  --seed "${SEED}" \
  --epochs "${EPOCHS}" \
  --output_dir "${OUTPUT_DIR}" \
  --checkpoint_dir "${CHECKPOINT_DIR}" \
  2>&1 | tee "${OUTPUT_DIR}/training.log"

EXIT_CODE=${PIPESTATUS[0]}

# ---------- Post-run summary ----------
if [[ $EXIT_CODE -eq 0 ]]; then
  echo "[DONE] ${RUN_ID} completed successfully."
else
  echo "[FAIL] ${RUN_ID} exited with code ${EXIT_CODE}."
fi

exit $EXIT_CODE
