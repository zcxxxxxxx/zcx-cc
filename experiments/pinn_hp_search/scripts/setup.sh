#!/bin/bash
# ============================================================================
# PINN Hyperparameter Search — Setup Script
#
# Installs dependencies, generates configs, and validates the environment.
#
# Usage:
#   bash scripts/setup.sh
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPERIMENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo "=== PINN Hyperparameter Search — Setup ==="
echo ""

# ---- Step 1: Check Python ---- #
echo "[1/5] Checking Python..."
PYTHON=""
if command -v python &> /dev/null; then
    PYTHON="python"
elif command -v python3 &> /dev/null; then
    PYTHON="python3"
else
    echo "[ERROR] Python not found. Install Python 3.10+."
    exit 1
fi

PY_VERSION=$($PYTHON --version 2>&1)
echo "  Found: $PY_VERSION"

# ---- Step 2: Install dependencies ---- #
echo ""
echo "[2/5] Installing Python dependencies..."
$PYTHON -m pip install --quiet numpy 2>&1 | tail -1
echo "  numpy: installed"
echo "  Note: For full PINN training, install PyTorch:"
echo "    pip install torch matplotlib"

# ---- Step 3: Generate configs ---- #
echo ""
echo "[3/5] Generating hyperparameter configs..."
$PYTHON "$EXPERIMENT_DIR/configs/generate_configs.py"

# ---- Step 4: Create output directories ---- #
echo ""
echo "[4/5] Creating output directories..."
mkdir -p "$EXPERIMENT_DIR/outputs"
echo "  outputs/ ready"

# ---- Step 5: Verify structure ---- #
echo ""
echo "[5/5] Verifying experiment structure..."
EXPECTED=(
    "pinn/model.py"
    "pinn/train.py"
    "pinn/utils.py"
    "pinn/verify.py"
    "configs/generate_configs.py"
    "configs/manifest.json"
    "scripts/run_sweep_parent.sh"
    "scripts/check_completion.sh"
    "scripts/aggregate_results.py"
    "sweep_config.json"
    "STATE.md"
)
ALL_OK=1
for f in "${EXPECTED[@]}"; do
    if [ -f "$EXPERIMENT_DIR/$f" ]; then
        echo "  [OK] $f"
    else
        echo "  [MISSING] $f"
        ALL_OK=0
    fi
done

if [ $ALL_OK -eq 1 ]; then
    echo ""
    echo -e "\033[0;32m=== Setup Complete! ===\033[0m"
    echo ""
    echo "To run the full sweep:"
    echo "  bash scripts/run_sweep_parent.sh --loop"
    echo ""
    echo "To check status:"
    echo "  bash scripts/check_completion.sh"
    echo ""
else
    echo ""
    echo -e "\033[0;31m=== Setup Incomplete — some files missing ===\033[0m"
    exit 1
fi
