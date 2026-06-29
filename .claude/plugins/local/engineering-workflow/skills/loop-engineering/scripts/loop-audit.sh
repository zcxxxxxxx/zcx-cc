#!/bin/bash
# Loop Audit Script v3 — content-level state detection
# Checks: hard stop conditions, state freshness (content-level), verification gates, cost limits, contract integrity
set -euo pipefail

echo "=== Loop Audit ==="
echo ""

HAS_ISSUES=0
PROJECT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# ─── Helper: SHA256 ──────────────────────────────────────────────────────────
sha256_file() {
  if [ -f "$1" ]; then sha256sum "$1" | cut -d' ' -f1; else echo ""; fi
}

# ─── 1. STATE.md content-level checks ────────────────────────────────────────
echo "── 1. STATE.md Integrity ──"
STATE_FILES=$(find . -name "STATE.md" 2>/dev/null)
if [ -z "$STATE_FILES" ]; then
  echo "  [WARN] No STATE.md files found. Loops may lack persistent state."
  HAS_ISSUES=1
else
  echo "  [OK] Found state files."
  echo "$STATE_FILES" | while IFS= read -r f; do
    # Content-level: vague next step
    if grep -qi "continue\|to be determined\|tbd\|next:\s*$" "$f" 2>/dev/null; then
      echo "  [WARN] $f has vague next step (continue/TBD) — not actionable by a fresh agent"
    fi

    # Content-level: missing hard stop limits
    if ! grep -qi "max.*iter\|timeout\|max.*fail\|token.*limit\|cost.*cap" "$f" 2>/dev/null; then
      echo "  [WARN] $f missing documented hard stop limits (iteration/timeout/failure threshold)"
    fi

    # Content-level: check recency by content (no "updated" timestamp in last 5 lines)
    if grep -qi "updated:\|last run:\|last updated:" "$f" 2>/dev/null; then
      : # has timestamp
    else
      echo "  [INFO] $f has no 'Last updated:' timestamp — consider adding one for recency checks"
    fi
  done
fi

# ─── 2. Hard stop conditions ─────────────────────────────────────────────────
echo ""
echo "── 2. Hard Stop Conditions ──"
if grep -rq "token.*limit\|max.*iter\|timeout\|cost.*cap\|hard.*stop" --include="*.md" --include="*.json" --include="*.yaml" . 2>/dev/null; then
  echo "  [OK] Found hard stop conditions (token/iteration/time/cost limits)."
else
  echo "  [WARN] No hard stop conditions detected. Loops may run unbounded."
  HAS_ISSUES=1
fi

# ─── 3. Verification gates ───────────────────────────────────────────────────
echo ""
echo "── 3. Verification Gates ──"
if grep -rq "verif\|gate\|check.*script\|test\|lint\|convergen" --include="*.md" --include="*.sh" --include="*.py" . 2>/dev/null; then
  echo "  [OK] Verification gates detected."
else
  echo "  [WARN] No verification gates found. Loops may accept bad output."
  HAS_ISSUES=1
fi

# ─── 4. Writer/verifier separation ───────────────────────────────────────────
echo ""
echo "── 4. Writer/Verifier Separation ──"
if grep -rq "separate.*agent\|independent.*verif\|context.*isolat\|different.*model\|verif.*not.*see\|verifier.*own" --include="*.md" . 2>/dev/null; then
  echo "  [OK] Writer/verifier separation referenced."
else
  echo "  [INFO] Writer/verifier separation not explicitly documented."
fi

# ─── 5. Cost tracking ────────────────────────────────────────────────────────
echo ""
echo "── 5. Cost Tracking ──"
if grep -rq "cost\|accept.*rate\|token.*budget\|acceptance.*rate" --include="*.md" . 2>/dev/null; then
  echo "  [OK] Cost tracking or acceptance metric found."
else
  echo "  [INFO] No cost/acceptance metric found."
fi

# ─── 6. Execution contract integrity (content-level SHA256) ──────────────────
echo ""
echo "── 6. Execution Contract ──"
CONTRACT="$PROJECT/execution-contract.md"
if [ -f "$CONTRACT" ]; then
  # Check SHA256 of STATE.md vs contract
  CONTRACT_HASH=$(grep "STATE.md" "$CONTRACT" 2>/dev/null | grep -oE '[a-f0-9]{64}' | head -1 || true)
  if [ -n "$CONTRACT_HASH" ]; then
    ACTUAL_HASH=$(sha256_file "$PROJECT/STATE.md")
    if [ "$CONTRACT_HASH" = "$ACTUAL_HASH" ]; then
      echo "  [OK] execution-contract.md STATE.md hash matches."
    else
      echo "  [WARN] execution-contract.md stale — STATE.md content changed since contract generated."
      HAS_ISSUES=1
    fi
  else
    echo "  [INFO] No STATE.md hash in execution-contract.md (contract may need regeneration)."
  fi
else
  echo "  [INFO] No execution-contract.md found (optional for non-contract tasks)."
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
if [ "$HAS_ISSUES" -eq 1 ]; then
  echo "=== Audit Complete — Issues Found ==="
  exit 1
else
  echo "=== Audit Complete — All Clear ==="
  exit 0
fi
