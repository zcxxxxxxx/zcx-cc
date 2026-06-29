#!/usr/bin/env bash
# generate-contract.sh — Generate execution-contract.md from experiment artifacts
# Usage: bash scripts/generate-contract.sh [experiment-dir]
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"

# Determine project root and experiment directory
PROJECT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HERE")"
EXPERIMENT_DIR="${1:-$PROJECT}"

# Find plan artifacts
PLAN_FILE=""
DESIGN_FILE=""
TASKS_FILE=""

if [ -f "$EXPERIMENT_DIR/docs/experiment-plan.md" ]; then
  PLAN_FILE="$EXPERIMENT_DIR/docs/experiment-plan.md"
elif [ -f "$EXPERIMENT_DIR/docs/plan.md" ]; then
  PLAN_FILE="$EXPERIMENT_DIR/docs/plan.md"
fi

if [ -f "$EXPERIMENT_DIR/docs/experiment-design.md" ]; then
  DESIGN_FILE="$EXPERIMENT_DIR/docs/experiment-design.md"
elif [ -f "$EXPERIMENT_DIR/docs/design.md" ]; then
  DESIGN_FILE="$EXPERIMENT_DIR/docs/design.md"
fi

if [ -f "$EXPERIMENT_DIR/docs/tasks.md" ]; then
  TASKS_FILE="$EXPERIMENT_DIR/docs/tasks.md"
fi

echo "=== Generating Execution Contract ==="
echo "  Experiment: $EXPERIMENT_DIR"
echo "  Plan:       ${PLAN_FILE:-not found}"
echo "  Design:     ${DESIGN_FILE:-not found}"
echo "  Tasks:      ${TASKS_FILE:-not found}"
echo ""

CONTRACT_FILE="$EXPERIMENT_DIR/execution-contract.md"

# Helper: compute SHA256 of a file
sha256_file() {
  if [ -f "$1" ]; then
    sha256sum "$1" | cut -d' ' -f1
  else
    echo "FILE_NOT_FOUND"
  fi
}

# Extract objective from plan file
extract_objective() {
  if [ -f "$1" ]; then
    grep -i "^##\s*\(Intent\|Objective\|intent\)" "$1" -A 2 2>/dev/null | tail -1 || echo "See plan file"
  fi
}

# Extract scope from plan
extract_scope() {
  if [ -f "$1" ]; then
    local in_scope=false
    while IFS= read -r line; do
      if echo "$line" | grep -qi "^##\s*scope"; then in_scope=true; continue; fi
      if $in_scope && echo "$line" | grep -qi "^##\s"; then break; fi
      if $in_scope && echo "$line" | grep -qi "in scope"; then
        echo "$line"
      fi
    done < "$1"
  fi
}

# Extract tasks from tasks file
extract_tasks() {
  if [ -f "$1" ]; then
    grep -E "^- \[ \]|^[0-9]+\.|^### Batch" "$1" 2>/dev/null | head -20
  fi
}

# Write contract
cat > "$CONTRACT_FILE" << CONTRACT_EOF
# Execution Contract

Generated: $(date -Iseconds)
Source directory: ${EXPERIMENT_DIR##*/}

## Intent Lock

$(extract_objective "$PLAN_FILE" 2>/dev/null || echo "Define the experiment objective.")
Scope: $(extract_scope "$PLAN_FILE" 2>/dev/null || echo "See experiment plan.")

## Approved Behavior (In Scope)

- Run experiment configurations as defined in configs/
- Collect metrics and compare against acceptance criteria
- Update STATE.md with results
- Generate analysis summary

## Design Constraints

- Do not modify source code outside experiment directory
- Do not commit output files (outputs/ is in .gitignore)
- Config files must be committed before results are accepted

## Task Batches

$(extract_tasks "$TASKS_FILE" 2>/dev/null || echo "See docs/tasks.md for execution checklist.")

## Source Integrity

| Source File | SHA256 |
|-------------|--------|
| $(basename "${PLAN_FILE:-no-plan}") | $(sha256_file "$PLAN_FILE") |
| $(basename "${TASKS_FILE:-no-tasks}") | $(sha256_file "$TASKS_FILE") |
| $(basename "${DESIGN_FILE:-no-design}") | $(sha256_file "$DESIGN_FILE") |
| STATE.md | $(sha256_file "$EXPERIMENT_DIR/STATE.md") |

CONTRACT_EOF

echo "  ✓ Contract written to: $CONTRACT_FILE"
echo ""
echo "=== Contract Generated ==="
echo "Next: Review execution-contract.md, then proceed with execution."
echo "If source files change, re-run this script to refresh the contract."
