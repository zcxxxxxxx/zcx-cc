#!/bin/bash
# Loop Audit Script v2
# Checks active loops for: hard stop conditions, state freshness, verification gates, cost limits

echo "=== Loop Audit ==="
echo ""

HAS_ISSUES=0

# 1. Check for STATE.md files — loop memory
STATE_FILES=$(find . -name "STATE.md" 2>/dev/null)
if [ -z "$STATE_FILES" ]; then
  echo "[WARN] No STATE.md files found. Loops may lack persistent state."
  HAS_ISSUES=1
else
  echo "[OK] Found state files."
  echo "$STATE_FILES" | while read f; do
    # Check if next step is concrete
    if grep -qi "continue\|to be determined\|tbd\|next:\s*$" "$f" 2>/dev/null; then
      echo "  [WARN] $f has vague next step (continue/TBD)"
    fi
    # Check recency
    if [ -n "$(find "$f" -mtime +1 -print 2>/dev/null)" ]; then
      echo "  [WARN] $f not updated in > 24h"
    fi
  done
fi

# 2. Check for hard stop conditions
if grep -rq "token.*limit\|max.*iter\|timeout\|cost.*cap\|hard.*stop" --include="*.md" --include="*.json" --include="*.yaml" . 2>/dev/null; then
  echo "[OK] Found hard stop conditions (token/iteration/time/cost limits)."
else
  echo "[WARN] No hard stop conditions detected. Loops may run unbounded."
  HAS_ISSUES=1
fi

# 3. Check for verification gates
if grep -rq "verif\|gate\|check.*script\|test\|lint\|convergen" --include="*.md" --include="*.sh" --include="*.py" . 2>/dev/null; then
  echo "[OK] Verification gates detected."
else
  echo "[WARN] No verification gates found. Loops may accept bad output."
  HAS_ISSUES=1
fi

# 4. Check for writer/verifier separation
if grep -rq "separate.*agent\|independent.*verif\|context.*isolat\|different.*model\|verif.*not.*see\|verifier.*own" --include="*.md" . 2>/dev/null; then
  echo "[OK] Writer/verifier separation referenced."
else
  echo "[INFO] Writer/verifier separation not explicitly documented."
fi

# 5. Check for cost tracking
if grep -rq "cost\|accept.*rate\|token.*budget\|acceptance.*rate" --include="*.md" . 2>/dev/null; then
  echo "[OK] Cost tracking or acceptance metric found."
else
  echo "[INFO] No cost/acceptance metric found."
fi

echo ""
if [ "$HAS_ISSUES" -eq 1 ]; then
  echo "=== Audit Complete — Issues Found ==="
  exit 1
else
  echo "=== Audit Complete — All Clear ==="
  exit 0
fi
