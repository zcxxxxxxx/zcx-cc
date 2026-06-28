# Taste Invariants — Experiment Standards as Executable Checks

A "taste invariant" encodes a human standard as an automated check.
Use these templates to create checks for your own experiments.

## How to Add a New Invariant

1. Identify a standard that was violated or forgotten.
2. Write a check script (bash, Python, or pytest assertion).
3. Register it in `scripts/check-harness.sh`.
4. Remove the prose reminder — the script replaces it.

## Template: Config Completeness

```bash
# check_config_fields.sh — verify required fields in YAML configs
REQUIRED_FIELDS=("seed" "epochs" "learning_rate" "batch_size" "loss_type")
for cfg in "$@"; do
  for field in "${REQUIRED_FIELDS[@]}"; do
    if ! grep -q "^${field}:" "$cfg"; then
      echo "FAIL: $cfg missing required field: $field"
      exit 1
    fi
  done
done
echo "PASS: all configs have required fields"
```

## Template: Convergence Check

```bash
# check_convergence.sh — verify loss below threshold in training log
# Usage: check_convergence.sh <log_file> <threshold>
LOG=$1
THRESHOLD=${2:-1e-4}
FINAL_LOSS=$(tail -n 10 "$LOG" | grep -oP 'loss[=:]\s*[\d.]+' | tail -1 | grep -oP '[\d.]+')
if [ -z "$FINAL_LOSS" ]; then
  echo "FAIL: could not extract final loss from $LOG"
  exit 1
fi
if (( $(echo "$FINAL_LOSS > $THRESHOLD" | bc -l) )); then
  echo "FAIL: loss=$FINAL_LOSS exceeds threshold=$THRESHOLD"
  exit 1
fi
echo "PASS: loss=$FINAL_LOSS < threshold=$THRESHOLD"
```

## Template: Seed Recording

```bash
# check_seeds.sh — verify seed is set in all configs
for cfg in "$@"; do
  SEED=$(grep -oP '^seed[=:]\s*\d+' "$cfg" | grep -oP '\d+')
  if [ -z "$SEED" ]; then
    echo "FAIL: $cfg has no seed"
    exit 1
  fi
done
echo "PASS: all configs have seeds"
```

## Template: Figure Completeness

```bash
# check_figures.sh — verify each figure has a caption or description
# Usage: check_figures.sh <figures_dir>
FIGS_DIR=$1
for fig in "$FIGS_DIR"/*.png "$FIGS_DIR"/*.pdf; do
  [ -f "$fig" ] || continue
  CAP_FILE="${fig%.*}.txt"
  if [ ! -f "$CAP_FILE" ]; then
    echo "WARN: $fig has no caption file ($CAP_FILE)"
  fi
done
```

## Template: NaN Detection in CSVs

```bash
# check_nans.sh — verify no NaN values in experiment CSVs
for csv in "$@"; do
  if grep -qi "nan\|inf\|null" "$csv"; then
    echo "FAIL: $csv contains NaN/Inf values"
    exit 1
  fi
done
echo "PASS: no NaN/Inf values found"
```

## Template: Data Split Verification

```bash
# check_split.sh — verify train/val/test split ratios sum to 1.0
# Expects CSV with columns: split,count
DATA=$1
python3 -c "
import csv
from collections import defaultdict
totals = defaultdict(int)
with open('$DATA') as f:
    for row in csv.DictReader(f):
        totals[row['split']] += int(row['count'])
total = sum(totals.values())
for s, c in totals.items():
    print(f'{s}: {c/total:.3f}')
assert abs(sum(c/total for c in totals.values()) - 1.0) < 0.01, 'split ratios do not sum to 1.0'
print('PASS: split ratios verified')
"
```

## Adding to check-harness.sh

Each new invariant adds a single line to the audit function:

```bash
audit() {
  check_config_fields.sh experiments/*/configs/*.yaml
  check_seeds.sh experiments/*/configs/*.yaml
  check_nans.sh experiments/*/results/*.csv
  echo "Audit complete."
}
```
