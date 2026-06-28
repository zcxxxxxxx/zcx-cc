#!/bin/bash
# Run all configurations in the PINN LoRA rank sweep
# Executes sequentially: rank1, rank2, rank4, rank8
# Each with seed=42, epochs=1000
#
# Usage: bash scripts/run_all.sh
#
# Resume-safe: skips any run that already has metrics.json with final_loss.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_DIR}"

echo "=============================================="
echo "PINN LoRA Rank Sweep — Batch Run"
echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "Configurations: rank=[1,2,4,8] seed=42 epochs=1000"
echo "=============================================="

START_TIME=$(date +%s)

RESULTS=()

for RANK in 1 2 4 8; do
  RUN_ID="rank${RANK}_seed42"
  echo ""
  echo ">>> [$(date -u '+%H:%M:%S')] Starting ${RUN_ID} ..."

  RUN_START=$(date +%s)

  if bash "${SCRIPT_DIR}/run_single.sh" --rank "${RANK}" --seed 42 --epochs 1000; then
    RUN_END=$(date +%s)
    DURATION=$((RUN_END - RUN_START))
    RESULTS+=("${RUN_ID}: PASS (${DURATION}s)")
    echo "<<< [$(date -u '+%H:%M:%S')] ${RUN_ID} finished in ${DURATION}s (PASS)"
  else
    RUN_END=$(date +%s)
    DURATION=$((RUN_END - RUN_START))
    RESULTS+=("${RUN_ID}: FAIL (${DURATION}s)")
    echo "<<< [$(date -u '+%H:%M:%S')] ${RUN_ID} finished in ${DURATION}s (FAIL)"
  fi
done

END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))

echo ""
echo "=============================================="
echo "Sweep Complete (${TOTAL_DURATION}s total)"
echo "=============================================="
for RESULT in "${RESULTS[@]}"; do
  echo "  ${RESULT}"
done
echo "=============================================="

# Generate aggregate CSV
python3 -c "
import json, csv, os, glob

outputs_dir = '${PROJECT_DIR}/outputs'
rows = []
for run_dir in sorted(glob.glob(os.path.join(outputs_dir, 'rank*_seed42'))):
    metrics_file = os.path.join(run_dir, 'metrics.json')
    if os.path.exists(metrics_file):
        with open(metrics_file) as f:
            m = json.load(f)
        rows.append(m)

if rows:
    fieldnames = list(rows[0].keys())
    with open(os.path.join(outputs_dir, 'sweep_results.csv'), 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f'[INFO] Wrote sweep_results.csv with {len(rows)} runs')
else:
    print('[INFO] No metrics found, skipping sweep_results.csv')
" 2>&1 || true

echo ""
echo "[DONE] All runs submitted. See outputs/ for results."
