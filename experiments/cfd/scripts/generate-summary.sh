#!/usr/bin/env bash
# generate-summary.sh — Tabulate CFD mesh sweep results into summary.md / summary.csv
# ============================================================================
# Taste invariant: after all meshes run, this script produces the result matrix.
# Usage:
#   bash scripts/generate-summary.sh
#   bash scripts/generate-summary.sh --output-dir /path/to/outputs
#
# Outputs:
#   outputs/summary.md    — human-readable results table
#   outputs/summary.csv   — machine-readable results table
# ============================================================================

set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUTS_DIR="${1:-$HERE/outputs}"
MESHES_YAML="$HERE/configs/mesh_list.yaml"
TOLERANCE="1e-6"
TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

# Auto-detect Python
if command -v python &>/dev/null && python -c "import json; print('ok')" 2>/dev/null | grep -q ok; then
    PYTHON="python"
elif command -v python3 &>/dev/null && python3 -c "import json; print('ok')" 2>/dev/null | grep -q ok; then
    PYTHON="python3"
else
    echo "[FATAL] No working Python found."
    exit 2
fi

# Convert Git Bash paths to Windows format for native Windows Python
to_win_path() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*) cygpath -w "$1" 2>/dev/null || echo "$1" ;;
        *) echo "$1" ;;
    esac
}

mkdir -p "$OUTPUTS_DIR"

echo "[INFO] Generating summary in ${OUTPUTS_DIR}"

# Collect results via Python
WIN_MESHES="$(to_win_path "$MESHES_YAML")"
WIN_OUTPUTS="$(to_win_path "$OUTPUTS_DIR")"
WIN_HERE="$(to_win_path "$HERE")"

$PYTHON << PYEOF
import json, os, sys, yaml, re
from pathlib import Path

here = Path(r"${WIN_HERE}")
outputs = Path(r"${WIN_OUTPUTS}")

# Load mesh config
with open(r"${WIN_MESHES}", encoding="utf-8") as f:
    config = yaml.safe_load(f)

meshes = config.get("meshes", [])

# Compile results
results = []
for m in meshes:
    mid = m["id"]
    log_dir = outputs / mid
    log_file = log_dir / "simpleFoam.log"

    entry = {
        "id": mid,
        "airfoil": m.get("airfoil", ""),
        "cell_count": m.get("cell_count", 0),
        "mesh_type": m.get("mesh_type", ""),
        "status": "PENDING",
        "iterations": "",
        "residuals": {},
        "wall_time": "",
    }

    if log_file.exists():
        content = log_file.read_text(encoding="utf-8", errors="replace")

        # Check divergence
        diverged = bool(re.search(r"NA?N|inf|divergence|failed", content, re.IGNORECASE))

        # Extract final residuals
        residuals = {}
        for match in re.finditer(
            r"Solving for\s+(\w+),\s*Initial residual\s*=\s*([0-9.eE+\-]+),\s*Final residual\s*=\s*([0-9.eE+\-]+)",
            content,
        ):
            residuals[match.group(1)] = float(match.group(3))

        entry["residuals"] = residuals

        # Extract iteration count
        time_matches = re.findall(r"^Time\s*=\s*(\d+)", content, re.MULTILINE)
        entry["iterations"] = int(time_matches[-1]) if time_matches else "?"

        # Check wall time if available
        wt_match = re.search(r"ExecutionTime\s*=\s*([0-9.]+)\s*s", content)
        entry["wall_time"] = f"{float(wt_match.group(1)):.1f}s" if wt_match else ""

        if diverged:
            entry["status"] = "DIVERGED"
        elif residuals and max(residuals.values()) < 1e-6:
            entry["status"] = "PASS"
        elif residuals:
            entry["status"] = "FAIL"
        else:
            entry["status"] = "NO_RESIDUALS"
    else:
        # Check if .status file exists
        status_file = log_dir / ".status"
        if status_file.exists():
            entry["status"] = status_file.read_text(encoding="utf-8").strip()
        done_file = log_dir / ".done"
        if done_file.exists():
            entry["wall_time"] = done_file.read_text(encoding="utf-8").strip()

    results.append(entry)

# --- Write summary.md ---
md_lines = [
    "# CFD Mesh Sweep — Results Summary",
    "",
    f"**Generated:** {TIMESTAMP}",
    f"**Tolerance:** {TOLERANCE}",
    f"**Solver:** simpleFoam + kOmegaSST at Re=1e6",
    "",
    "## Results Matrix",
    "",
    "| Mesh | Airfoil | Cells | Type | Iterations | Residual Ux | Residual Uy | Residual p | Residual k | Residual omega | Wall time | Status |",
    "|------|---------|-------|------|------------|-------------|-------------|------------|-------------|----------------|-----------|--------|",
]

for e in results:
    def resid(field):
        v = e["residuals"].get(field, "")
        return f"{v:.2e}" if isinstance(v, float) else ""

    def status_tag(s):
        if s == "PASS":
            return "**PASS**"
        elif s == "FAIL":
            return "FAIL"
        elif s == "DIVERGED":
            return "**DIVERGED**"
        elif s == "PENDING":
            return "PENDING"
        else:
            return s

    row = (
        f"| {e['id']} | {e['airfoil']} | {e['cell_count']} | {e['mesh_type']} "
        f"| {e['iterations']} | {resid('Ux')} | {resid('Uy')} | {resid('p')} "
        f"| {resid('k')} | {resid('omega')} | {e['wall_time']} | {status_tag(e['status'])} |"
    )
    md_lines.append(row)

md_lines.extend([
    "",
    "## Summary Statistics",
    "",
])

pass_count = sum(1 for e in results if e["status"] == "PASS")
fail_count = sum(1 for e in results if e["status"] == "FAIL")
diverged_count = sum(1 for e in results if e["status"] == "DIVERGED")
pending_count = sum(1 for e in results if e["status"] == "PENDING")

md_lines.append(f"- **PASS:** {pass_count}/8")
md_lines.append(f"- **FAIL:** {fail_count}/8")
md_lines.append(f"- **DIVERGED:** {diverged_count}/8")
md_lines.append(f"- **PENDING:** {pending_count}/8")
md_lines.append("")

with open(outputs / "summary.md", "w", encoding="utf-8") as f:
    f.write("\n".join(md_lines) + "\n")
print(f"[OK] summary.md written ({pass_count} pass, {fail_count} fail, {diverged_count} diverged, {pending_count} pending)")

# --- Write summary.csv ---
csv_lines = ["mesh_id,airfoil,cells,mesh_type,iterations,residual_Ux,residual_Uy,residual_p,residual_k,residual_omega,wall_time,status"]
for e in results:
    csv_lines.append(
        f"{e['id']},{e['airfoil']},{e['cell_count']},{e['mesh_type']},"
        f"{e['iterations']},{resid('Ux')},{resid('Uy')},{resid('p')},{resid('k')},{resid('omega')},"
        f"{e['wall_time']},{e['status']}"
    )

with open(outputs / "summary.csv", "w", encoding="utf-8") as f:
    f.write("\n".join(csv_lines) + "\n")
print(f"[OK] summary.csv written ({len(results)} rows)")

# Aggregate acceptance summary
if pending_count > 0:
    print(f"[WARN] {pending_count} meshes still pending — summary is incomplete")
    sys.exit(1)
elif pass_count == len(results):
    print(f"[PASS] All {len(results)} meshes converged below {TOLERANCE}")
    sys.exit(0)
else:
    print(f"[FAIL] {fail_count + diverged_count}/{len(results)} meshes did not converge")
    sys.exit(1)
PYEOF
