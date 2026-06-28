#!/usr/bin/env bash
# run-mesh-sweep.sh — Run OpenFOAM k-omega SST across all meshes
# Usage: bash scripts/run-mesh-sweep.sh [convert|run|resume|all]
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
MESHES_DIR="$HERE/meshes"
CONFIGS_DIR="$HERE/configs"
OUTPUTS_DIR="$HERE/outputs"
SOLVER="simpleFoam"
RE="1e6"

# Solver parameters
MAX_ITER=5000
WRITE_INTERVAL=100
RESIDUAL_TOL=1e-6

# Source OpenFOAM environment (adjust path for your installation)
FOAM_BASH="${FOAM_BASH:-/opt/openfoam10/etc/bashrc}"
if [ -f "$FOAM_BASH" ]; then
  # shellcheck disable=SC1090
  source "$FOAM_BASH"
fi

mkdir -p "$CONFIGS_DIR" "$OUTPUTS_DIR"

convert_mesh() {
  local mesh_file="$1"
  local mesh_name
  mesh_name="$(basename "$mesh_file" .msh)"
  local case_dir="$CONFIGS_DIR/$mesh_name"

  echo "[CONVERT] $mesh_name — converting $mesh_file"
  mkdir -p "$case_dir/system" "$case_dir/constant" "$case_dir/0"

  # Convert mesh based on format
  # Heuristic: check file header for format hints
  if head -5 "$mesh_file" | grep -qi "gmsh\|grd"; then
    gmshToFoam "$mesh_file" -case "$case_dir" 2>&1 | tail -5
  elif head -5 "$mesh_file" | grep -qi "unv\|ideas"; then
    ideasUnvToFoam "$mesh_file" -case "$case_dir" 2>&1 | tail -5
  else
    echo "  WARN: unknown format, trying gmshToFoam"
    gmshToFoam "$mesh_file" -case "$case_dir" 2>&1 | tail -5
  fi

  echo "[CONVERT] $mesh_name — done"
}

setup_case() {
  local mesh_name="$1"
  local case_dir="$CONFIGS_DIR/$mesh_name"

  # controlDict
  cat > "$case_dir/system/controlDict" << CTLDICT
application     simpleFoam;
startFrom       startTime;
startTime       0;
stopAt          endTime;
endTime         $MAX_ITER;
deltaT          1;
writeControl    timeStep;
writeInterval   $WRITE_INTERVAL;
purgeWrite      0;
writeFormat     ascii;
writePrecision  8;
writeCompression off;
timeFormat      general;
timePrecision   8;
runTimeModifiable true;
functions
{
    residuals
    {
        type            residuals;
        fields          (U p k omega);
        executionControl timeStep;
        writeControl    timeStep;
        writeInterval   1;
    }
}
CTLDICT

  # fvSchemes
  cat > "$case_dir/system/fvSchemes" << FVSCHEMES
ddtSchemes
{
    default         steadyState;
}
gradSchemes
{
    default         Gauss linear;
    grad(p)         Gauss linear;
    grad(U)         Gauss linear;
}
divSchemes
{
    default         none;
    div(phi,U)      bounded Gauss upwind;
    div(phi,k)      bounded Gauss upwind;
    div(phi,omega)  bounded Gauss upwind;
    div((nuEff*dev2(T(grad(U))))) Gauss linear;
}
laplacianSchemes
{
    default         Gauss linear limited 0.5;
}
interpolationSchemes
{
    default         linear;
}
snGradSchemes
{
    default         limited 0.5;
}
wallDist
{
    method          meshWave;
}
FVSCHEMES

  # fvSolution
  cat > "$case_dir/system/fvSolution" << FVSOLUTION
solvers
{
    p
    {
        solver          GAMG;
        tolerance       1e-8;
        relTol          0.01;
        smoother        DIC;
    }
    U
    {
        solver          PBiCGStab;
        preconditioner  DILU;
        tolerance       1e-8;
        relTol          0.1;
    }
    k
    {
        solver          PBiCGStab;
        preconditioner  DILU;
        tolerance       1e-8;
        relTol          0.1;
    }
    omega
    {
        solver          PBiCGStab;
        preconditioner  DILU;
        tolerance       1e-8;
        relTol          0.1;
    }
}
SIMPLE
{
    nNonOrthogonalCorrectors 2;
    residualControl
    {
        U               1e-6;
        p               1e-6;
        k               1e-6;
        omega           1e-6;
    }
}
FVSOLUTION

  # turbulenceProperties
  cat > "$case_dir/constant/turbulenceProperties" << TURB
simulationType RAS;
RAS
{
    RASModel        kOmegaSST;
    turbulence      on;
    printCoeffs     on;
}
TURB

  # transportProperties (air at Re=1e6)
  cat > "$case_dir/constant/transportProperties" << TRANSPORT
transportModel  Newtonian;
nu              [0 2 -1 0 0 0 0] 1e-5;
TRANSPORT
}

run_case() {
  local mesh_name="$1"
  local case_dir="$CONFIGS_DIR/$mesh_name"
  local output_dir="$OUTPUTS_DIR/$mesh_name"
  local log_file="$output_dir/simpleFoam.log"

  if [ -f "$output_dir/.done" ]; then
    echo "[SKIP] $mesh_name — already completed"
    return 0
  fi

  mkdir -p "$output_dir"

  echo "[RUN] $mesh_name — starting simpleFoam (max $MAX_ITER iters)"
  cd "$case_dir"

  # Optional: potentialFoam initialisation for better convergence
  # potentialFoam -case "$case_dir" > "$output_dir/potentialFoam.log" 2>&1

  simpleFoam -case "$case_dir" > "$log_file" 2>&1

  # Check for NaN/divergence
  if grep -qi "nan\|inf\|divergence\|failed" "$log_file"; then
    echo "[FAIL] $mesh_name — solver instability detected"
    echo "DIVERGED" > "$output_dir/.status"
    return 1
  fi

  echo "[DONE] $mesh_name — finished"
  echo "COMPLETE" > "$output_dir/.status"
  date +"%Y-%m-%d %H:%M:%S" > "$output_dir/.done"
  cd "$HERE"
}

##########
# ACTIONS
##########

do_convert() {
  echo "=== Converting all meshes ==="
  for mesh_file in "$MESHES_DIR"/*.msh; do
    [ -f "$mesh_file" ] || continue
    local mesh_name
    mesh_name="$(basename "$mesh_file" .msh)"
    convert_mesh "$mesh_file"
    setup_case "$mesh_name"
  done
  echo "=== Conversion complete ==="
}

do_run() {
  echo "=== Running all meshes ==="
  for mesh_file in "$MESHES_DIR"/*.msh; do
    [ -f "$mesh_file" ] || continue
    local mesh_name
    mesh_name="$(basename "$mesh_file" .msh)"
    run_case "$mesh_name"
  done
  echo "=== Run complete ==="
}

do_resume() {
  echo "=== Resuming incomplete meshes ==="
  for mesh_file in "$MESHES_DIR"/*.msh; do
    [ -f "$mesh_file" ] || continue
    local mesh_name
    mesh_name="$(basename "$mesh_file" .msh)"
    if [ ! -f "$OUTPUTS_DIR/$mesh_name/.done" ]; then
      run_case "$mesh_name"
    fi
  done
  echo "=== Resume complete ==="
}

case "${1:-all}" in
  convert) do_convert ;;
  run) do_run ;;
  resume) do_resume ;;
  all)
    do_convert
    do_run
    ;;
  *)
    echo "Usage: $0 [convert|run|resume|all]"
    exit 1
    ;;
esac
