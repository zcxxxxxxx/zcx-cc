#!/usr/bin/env bash
# check-harness.sh — Experiment integrity checks
# Usage: bash scripts/check-harness.sh [setup|audit|contract|all] [experiment-dir]
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HERE")"
EXPERIMENT_DIR="${2:-$PROJECT}"

# ─── Helpers ─────────────────────────────────────────────────────────────────
sha256_file() {
  if [ -f "$1" ]; then
    sha256sum "$1" | cut -d' ' -f1
  else
    echo ""
  fi
}

# ─── Modes ───────────────────────────────────────────────────────────────────

setup() {
  echo "=== Setup Checks ==="
  local errors=0

  for dir in docs/harness; do
    if [ ! -d "$PROJECT/$dir" ]; then
      echo "  WARN: $dir does not exist (create it if needed)"
      errors=$((errors + 1))
    else
      echo "  OK: $dir exists"
    fi
  done

  # Check for STATE.md
  if [ -f "$PROJECT/STATE.md" ]; then
    echo "  OK: STATE.md exists"
  else
    echo "  INFO: No STATE.md found (may be initial setup)"
  fi

  if [ "$errors" -eq 0 ]; then echo "  PASS"; else echo "  FAIL"; fi
  echo "=== Setup Checks Complete ==="
}

audit() {
  echo "=== Audit ==="
  local errors=0

  # ── Uncommitted config changes ──
  if [ -n "$(git -C "$PROJECT" status --porcelain '*.yaml' '*.yml' '*.json' '*.toml' 2>/dev/null)" ]; then
    echo "  WARN: uncommitted config files detected"
    git -C "$PROJECT" status --short '*.yaml' '*.yml' '*.json' '*.toml' 2>/dev/null
    errors=$((errors + 1))
  fi

  # ── Active plans stale > 7 days ──
  if [ -d "$PROJECT/docs/harness/active" ]; then
    for plan in "$PROJECT/docs/harness/active/"*.md; do
      [ -f "$plan" ] || continue
      local age=$(( ($(date +%s) - $(stat -c %Y "$plan")) / 86400 ))
      if [ "$age" -gt 7 ]; then
        echo "  WARN: active plan $(basename "$plan") is $age days old"
        errors=$((errors + 1))
      fi
    done
  fi

  # ── Content-level: STATE.md drift detection ──
  if [ -f "$PROJECT/STATE.md" ]; then
    local state_mtime age
    state_mtime=$(stat -c %Y "$PROJECT/STATE.md")
    age=$(( ($(date +%s) - state_mtime) / 86400 ))
    if [ "$age" -gt 1 ]; then
      echo "  WARN: STATE.md not updated in ${age} days (content may be stale)"
      errors=$((errors + 1))
    fi

    # Check for vague next steps (content-level)
    if grep -qi "continue\|to be determined\|tbd\|next:\s*$" "$PROJECT/STATE.md" 2>/dev/null; then
      echo "  WARN: STATE.md has vague next step (continue/TBD) — not actionable by a fresh agent"
      errors=$((errors + 1))
    fi
  fi

  # ── Contract staleness ──
  if [ -f "$EXPERIMENT_DIR/execution-contract.md" ]; then
    if ! validate_contract "$EXPERIMENT_DIR" > /dev/null 2>&1; then
      echo "  WARN: execution-contract.md is stale (source content has changed)"
      errors=$((errors + 1))
    fi
  fi

  if [ "$errors" -eq 0 ]; then
    echo "  PASS: no issues found"
  else
    echo "  FAIL: $errors issue(s) found"
    exit 1
  fi
  echo "=== Audit Complete ==="
}

contract() {
  echo "=== Contract Validation ==="
  local errors=0

  if [ ! -f "$EXPERIMENT_DIR/execution-contract.md" ]; then
    echo "  FAIL: execution-contract.md not found in $EXPERIMENT_DIR"
    echo "  Run: bash scripts/generate-contract.sh $EXPERIMENT_DIR"
    exit 1
  fi

  echo "  OK: execution-contract.md exists"

  if validate_contract "$EXPERIMENT_DIR"; then
    echo "  PASS: contract is fresh (all source integrity hashes match)"
  else
    echo "  FAIL: contract is stale — source artifacts have changed"
    echo "  Run: bash scripts/generate-contract.sh $EXPERIMENT_DIR"
    exit 1
  fi

  echo "=== Contract Validation Complete ==="
}

# ─── Contract validation (content-level SHA256 check) ────────────────────────
validate_contract() {
  local dir="$1"
  local contract_file="$dir/execution-contract.md"
  [ -f "$contract_file" ] || return 1

  local errors=0

  # Extract Source Integrity section — parse SHA256 values from the contract
  # Format: | filename | sha256hash |
  while IFS= read -r line; do
    # Match table rows: | filename | hash |
    if echo "$line" | grep -qE '^\|\s*.+\s*\|\s*[a-f0-9]{64}\s*\|$'; then
      # Extract filename and hash from markdown table
      local filename fhash actual_hash
      filename=$(echo "$line" | awk -F'|' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      fhash=$(echo "$line" | awk -F'|' '{print $3}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

      # Skip hash row header or separator
      [ "$fhash" = "SHA256" ] && continue
      [ "$filename" = "Source File" ] && continue
      [ "$filename" = "---" ] && continue

      # Compute actual hash
      local found=false
      for candidate in "$dir/$filename" "$dir/docs/$filename" "$PROJECT/$filename"; do
        if [ -f "$candidate" ]; then
          actual_hash=$(sha256_file "$candidate")
          found=true
          break
        fi
      done

      if [ "$found" = true ]; then
        if [ "$actual_hash" = "$fhash" ]; then
          echo "  OK: $filename (hash matches)"
        else
          echo "  FAIL: $filename (hash mismatch — content has changed)"
          errors=$((errors + 1))
        fi
      else
        echo "  WARN: $filename (source file not found, skipping hash check)"
      fi
    fi
  done < "$contract_file"

  [ "$errors" -eq 0 ]
}

all() {
  setup
  echo ""
  audit
  echo ""
  if [ -f "$EXPERIMENT_DIR/execution-contract.md" ]; then
    contract
  fi
}

# ─── Main ────────────────────────────────────────────────────────────────────
case "${1:-all}" in
  setup) setup ;;
  audit) audit ;;
  contract) contract ;;
  all) all ;;
  *)
    echo "Usage: $0 [setup|audit|contract|all] [experiment-dir]"
    echo ""
    echo "Modes:"
    echo "  setup     Check required directories and files exist"
    echo "  audit     Full integrity check with content-level staleness detection"
    echo "  contract  Validate execution-contract.md freshness via SHA256"
    echo "  all       Run setup + audit + contract"
    exit 1
    ;;
esac
