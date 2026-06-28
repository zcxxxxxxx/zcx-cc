#!/usr/bin/env bash
# check-harness.sh — Experiment integrity checks
# Usage: bash scripts/check-harness.sh [setup|audit|all]
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HERE")"

setup() {
  echo "=== Setup Checks ==="
  # Verify required directories exist
  for dir in docs/harness; do
    if [ ! -d "$PROJECT/$dir" ]; then
      echo "  WARN: $dir does not exist (create it if needed)"
    else
      echo "  OK: $dir exists"
    fi
  done
  echo "=== Setup Checks Complete ==="
}

audit() {
  echo "=== Audit ==="
  local errors=0

  # Check for uncommitted config changes
  if [ -n "$(git -C "$PROJECT" status --porcelain '*.yaml' '*.yml' '*.json' '*.toml' 2>/dev/null)" ]; then
    echo "  WARN: uncommitted config files detected"
    git -C "$PROJECT" status --short '*.yaml' '*.yml' '*.json' '*.toml' 2>/dev/null
    errors=$((errors + 1))
  fi

  # Check for active plans without results after 7 days
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

  if [ "$errors" -eq 0 ]; then
    echo "  PASS: no issues found"
  else
    echo "  FAIL: $errors issue(s) found"
    exit 1
  fi
  echo "=== Audit Complete ==="
}

all() {
  setup
  echo ""
  audit
}

case "${1:-all}" in
  setup) setup ;;
  audit) audit ;;
  all) all ;;
  *)
    echo "Usage: $0 [setup|audit|all]"
    exit 1
    ;;
esac
