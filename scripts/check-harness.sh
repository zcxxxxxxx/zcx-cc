#!/bin/bash
# Harness Integrity Check Script
# Central audit — registers all taste invariants and runs them together.
#
# Usage:
#   bash scripts/check-harness.sh          # full audit
#   bash scripts/check-harness.sh audit    # same as above
#   bash scripts/check-harness.sh setup    # pre-flight checks
#
# Adding a new invariant:
#   1. Write the check script in scripts/
#   2. Add a single line to the audit() function
#   3. Remove the prose reminder — the script enforces it forever

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "================================================"
echo " Harness Integrity Check"
echo " Repository: ${REPO_DIR}"
echo " Date:       $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "================================================"

audit() {
  echo ""
  echo "--- Taste Invariant: Seed Fields ---"
  bash "${SCRIPT_DIR}/check_seeds.sh" "${REPO_DIR}/experiments" || true

  echo ""
  echo "--- Taste Invariant: CFD Mesh Quality ---"
  if [[ -d "${REPO_DIR}/experiments/cfd" ]]; then
    bash "${REPO_DIR}/experiments/cfd/scripts/check-mesh-quality.sh" || true
  else
    echo "SKIP: cfd experiment not present"
  fi

  echo ""
  echo "--- Taste Invariant: CFD Residual Convergence ---"
  CFD_LOGS="${REPO_DIR}/experiments/cfd/logs"
  if [[ -d "${CFD_LOGS}" ]] && ls "${CFD_LOGS}"/mesh_*.log &>/dev/null 2>&1; then
    for logf in "${CFD_LOGS}"/mesh_*.log; do
      echo "  Checking: $(basename "$logf")"
      python3 "${REPO_DIR}/experiments/cfd/scripts/check_convergence.py" "$logf" --tol 1e-6 || true
    done
  else
    echo "SKIP: no CFD solver logs found (expected before first run)"
  fi

  echo ""
  echo "--- Audit Complete ---"
}

setup() {
  echo ""
  echo "--- Setup Checks ---"

  # Verify harness directory structure exists
  for DIR in "docs/harness/active" "docs/harness/completed"; do
    if [[ -d "${REPO_DIR}/${DIR}" ]]; then
      echo "OK: ${DIR}"
    else
      echo "WARN: ${DIR} missing — creating"
      mkdir -p "${REPO_DIR}/${DIR}"
    fi
  done

  echo "--- Setup Complete ---"
}

case "${1:-audit}" in
  audit)
    audit
    ;;
  setup)
    setup
    ;;
  *)
    echo "Usage: $0 {audit|setup}"
    exit 1
    ;;
esac
