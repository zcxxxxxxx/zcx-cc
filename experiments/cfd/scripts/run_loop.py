#!/usr/bin/env python3
"""
CFD Turbulence Simulation Loop — Batch Runner
==============================================
Automated batch loop for k-omega SST turbulence simulations over multiple meshes.

Features:
  - Sequentially processes mesh_1 through mesh_8 (or custom list)
  - Monitors convergence with configurable tolerance (default: 1e-6)
  - Detects divergence (NaN, spikes, persistent growth)
  - Auto-retries once with relaxed under-relaxation factors
  - Aggregates all results into outputs/summary.md
  - Resume-safe: skips meshes already marked as done
  - Generates detailed per-mesh logs and a CSV summary

Usage:
    python scripts/run_loop.py
    python scripts/run_loop.py --config configs/solver_config.yaml --meshes configs/mesh_list.yaml
    python scripts/run_loop.py --mesh-list mesh_2 mesh_5 mesh_7  # Run specific meshes
    python scripts/run_loop.py --dry-run                          # Print what would be done

Outputs:
    outputs/summary.md      — Human-readable markdown summary table
    outputs/summary.csv      — Machine-readable CSV of all results
    logs/run_loop_<timestamp>.log — Full execution log
    cases/<mesh_id>/        — Per-mesh case directories with solver logs
"""

import os
import sys
import yaml
import json
import re
import csv
import time
import logging
import argparse
import subprocess
import shutil
from pathlib import Path
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, field, asdict


# ============================================================================
# Data Model
# ============================================================================

@dataclass
class MeshConfig:
    """Configuration for a single mesh."""
    id: str
    file: str
    description: str = ""
    airfoil: str = ""
    mesh_type: str = "structured"
    cell_count: int = 0

@dataclass
class RunResult:
    """Result of a single simulation run (including retries)."""
    mesh_id: str
    status: str                    # PASS, FAIL, SKIP, ERROR
    convergence: bool              # True if converged to 1e-6
    max_residual: float            # Final max residual across all fields
    residuals: Dict[str, float]    # Per-field final residuals
    iterations: int                # Number of iterations completed
    wall_time_seconds: float       # Wall clock time
    retries: int                   # Number of retries performed
    solver_log: str                # Path to solver log file
    error_message: str = ""        # Error description if failed
    lift_coefficient: float = 0.0  # Cl (if available)
    drag_coefficient: float = 0.0  # Cd (if available)


# ============================================================================
# Configuration
# ============================================================================

class Config:
    """Loads and validates configuration from YAML files and CLI overrides."""

    DEFAULTS = {
        "solver": "simpleFoam",
        "turbulence_model": "kOmegaSST",
        "Reynolds_number": 1.0e6,
        "reference_velocity": 1.0,
        "reference_length": 1.0,
        "kinematic_viscosity": 1.0e-6,
        "convergence": {
            "criterion": "max_residual",
            "tolerance": 1.0e-6,
            "check_window": 50,
            "min_iterations": 100,
            "stagnation_window": 200,
        },
        "retry": {
            "max_retries": 1,
            "relaxation_factor": 0.3,
            "retry_log_suffix": "_retry",
        },
        "divergence_detection": {
            "nan_check": True,
            "residual_spike_threshold": 10.0,
            "consecutive_increase": 20,
            "large_residual_threshold": 1.0,
        },
        "solver_controls": {
            "max_iterations": 5000,
            "write_interval": 100,
        },
        "resources": {
            "n_procs": 4,
            "use_mpi": False,
            "max_wall_time_hours": 48,
        },
    }

    def __init__(self, config_path: str = "", mesh_list_path: str = ""):
        self.data = dict(self.DEFAULTS)

        if config_path and os.path.exists(config_path):
            with open(config_path, "r", encoding="utf-8") as f:
                user_cfg = yaml.safe_load(f) or {}
            self._deep_merge(self.data, user_cfg)

        self.meshes: List[MeshConfig] = []
        if mesh_list_path and os.path.exists(mesh_list_path):
            with open(mesh_list_path, "r", encoding="utf-8") as f:
                mesh_data = yaml.safe_load(f) or {}
            for m in mesh_data.get("meshes", []):
                self.meshes.append(MeshConfig(**m))

    def _deep_merge(self, base: dict, override: dict) -> None:
        """Recursively merge override dict into base dict."""
        for key, value in override.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self._deep_merge(base[key], value)
            else:
                base[key] = value

    @property
    def tolerance(self) -> float:
        return self.data["convergence"]["tolerance"]

    @property
    def max_retries(self) -> int:
        return self.data["retry"]["max_retries"]

    @property
    def relaxation_factor(self) -> float:
        return self.data["retry"]["relaxation_factor"]

    @property
    def max_iterations(self) -> int:
        return self.data["solver_controls"]["max_iterations"]

    def __getitem__(self, key):
        return self.data[key]

    def get(self, key, default=None):
        return self.data.get(key, default)


# ============================================================================
# Log Parser (OpenFOAM residual format)
# ============================================================================

class ResidualParser:
    """
    Parses OpenFOAM solver logs to extract residual history and detect divergence.

    OpenFOAM residual log format:
        smoothSolver:  Solving for Ux, Initial residual = 0.00567, Final residual = 8.90e-07, No Iterations 2
        GAMG:  Solving for p, Initial residual = 0.00123, Final residual = 4.56e-07, No Iterations 3
    """

    RESIDUAL_PATTERN = re.compile(
        r"Solving for\s+(?P<field>\w+),\s*"
        r"Initial residual\s*=\s*(?P<initial>[0-9.eE+\-]+),\s*"
        r"Final residual\s*=\s*(?P<final>[0-9.eE+\-]+)"
    )

    DIVERGENCE_PATTERNS = [
        re.compile(r"NA?N", re.IGNORECASE),
        re.compile(r"inf", re.IGNORECASE),
        re.compile(r"divergence", re.IGNORECASE),
        re.compile(r"failed", re.IGNORECASE),
        re.compile(r"extremely\s+large", re.IGNORECASE),
        re.compile(r"Floating point exception", re.IGNORECASE),
        re.compile(r"file:\s+core", re.IGNORECASE),
    ]

    @staticmethod
    def parse_log(log_path: str) -> Tuple[bool, Dict[str, float], Dict[str, List[float]], List[str]]:
        """
        Parse an OpenFOAM log file.

        Returns:
            diverged: True if divergence detected
            final_residuals: Per-field final residual values
            history: Per-field residual history (list of values)
            warnings: List of warning/error messages
        """
        final_residuals: Dict[str, float] = {}
        history: Dict[str, List[float]] = {}
        warnings: List[str] = []
        diverged = False

        if not os.path.exists(log_path):
            return True, {}, {}, [f"Log file not found: {log_path}"]

        with open(log_path, "r") as f:
            for line in f:
                # Check for divergence patterns
                for pattern in ResidualParser.DIVERGENCE_PATTERNS:
                    if pattern.search(line):
                        if not diverged:  # Log first divergence only
                            warnings.append(f"Divergence detected: {line.strip()}")
                        diverged = True

                # Parse residuals
                match = ResidualParser.RESIDUAL_PATTERN.search(line)
                if match:
                    field = match.group("field")
                    initial = float(match.group("initial"))
                    final_val = float(match.group("final"))

                    # Check for residual spikes
                    if initial > 10.0:
                        warnings.append(f"Residual spike: {field} initial={initial:.2e}")

                    # Update final residual for this field
                    final_residuals[field] = final_val

                    # Track history
                    if field not in history:
                        history[field] = []
                    history[field].append(final_val)

        return diverged, final_residuals, history, warnings


    @staticmethod
    def check_stagnation(history: Dict[str, List[float]], window: int = 200, tolerance: float = 1e-6) -> bool:
        """Check if residuals have stagnated (not improving)."""
        for field, values in history.items():
            if len(values) < window:
                continue
            recent = values[-window:]
            # If the mean residual in the window is not below tolerance and not decreasing
            if abs(recent[-1] - recent[0]) / max(abs(recent[0]), 1e-15) < 0.01:
                return True  # Stagnated
        return False

    @staticmethod
    def check_consecutive_increase(history: Dict[str, List[float]], threshold: int = 20) -> bool:
        """Check if any field's residual has been increasing for N consecutive iterations."""
        for field, values in history.items():
            if len(values) < threshold:
                continue
            recent = values[-threshold:]
            increasing = all(
                recent[i] >= recent[i - 1] * 0.99  # Allow 1% jitter
                for i in range(1, len(recent))
            )
            if increasing and recent[-1] > 1e-4:
                return True
        return False

    @staticmethod
    def extract_iteration_count(log_path: str) -> int:
        """Extract the final iteration/time step number from the log."""
        if not os.path.exists(log_path):
            return 0
        time_pattern = re.compile(r"^Time\s*=\s*(\d+)", re.MULTILINE)
        with open(log_path, "r") as f:
            content = f.read()
        matches = time_pattern.findall(content)
        return int(matches[-1]) if matches else 0

    @staticmethod
    def extract_forces(log_path: str) -> Tuple[float, float]:
        """
        Extract lift and drag coefficients from forceCoeffs output.
        Format: "Cm    = 0.001234" or "Cl    = 0.567890"
        """
        cl = 0.0
        cd = 0.0
        if not os.path.exists(log_path):
            return cl, cd

        cl_pattern = re.compile(r"Cl\s*=\s*([0-9.eE+\-]+)")
        cd_pattern = re.compile(r"Cd\s*=\s*([0-9.eE+\-]+)")

        with open(log_path, "r") as f:
            for line in f:
                m = cl_pattern.search(line)
                if m:
                    cl = float(m.group(1))
                m = cd_pattern.search(line)
                if m:
                    cd = float(m.group(1))

        return cl, cd


# ============================================================================
# Solver Interface
# ============================================================================

class SolverInterface:
    """
    Interfaces with the CFD solver (OpenFOAM simpleFoam).

    Responsible for:
      - Setting up the case directory for a mesh
      - Running the solver with proper configuration
      - Handling retry with relaxed under-relaxation
    """

    def __init__(self, config: Config, project_dir: Path, log: logging.Logger):
        self.config = config
        self.project_dir = project_dir
        self.log = log
        self.template_dir = project_dir / "templates"
        self.cases_dir = project_dir / "cases"

    def setup_case(self, mesh: MeshConfig, is_retry: bool = False) -> Path:
        """
        Create an OpenFOAM case directory for a given mesh.

        1. Copy template system/constant/0 directories
        2. Link or copy the mesh
        3. If retry, apply relaxed under-relaxation factors

        Returns path to the case directory.
        """
        case_dir = self.cases_dir / mesh.id
        if is_retry:
            case_dir = self.cases_dir / f"{mesh.id}_retry"

        if case_dir.exists():
            self.log.info(f"  Case directory exists: {case_dir}")
            return case_dir

        self.log.info(f"  Setting up case directory: {case_dir}")

        # Create case directory structure
        for subdir in ["0", "constant", "system"]:
            src = self.template_dir / subdir
            dst = case_dir / subdir
            if src.exists() and not dst.exists():
                shutil.copytree(src, dst)

        # Convert mesh file to OpenFOAM polyMesh format
        mesh_src = self.project_dir / mesh.file
        poly_mesh_dir = case_dir / "constant" / "polyMesh"
        poly_mesh_dir.mkdir(parents=True, exist_ok=True)

        if not mesh_src.exists():
            self.log.error(f"  Mesh file not found: {mesh_src}")
            return case_dir

        # Try Gmsh-to-OpenFOAM conversion first
        gmsh_converted = False
        if mesh_src.suffix.lower() in (".msh", ".gmsh"):
            try:
                self.log.info(f"  Converting mesh via gmshToFoam: {mesh_src.name}")
                result = subprocess.run(
                    ["gmshToFoam", str(mesh_src), "-case", str(case_dir)],
                    capture_output=True, text=True, timeout=300
                )
                if result.returncode == 0:
                    gmsh_converted = True
                    self.log.info(f"  gmshToFoam conversion successful")
                else:
                    self.log.warning(f"  gmshToFoam failed (stderr): {result.stderr[:200]}")
            except (FileNotFoundError, subprocess.TimeoutExpired) as e:
                self.log.warning(f"  gmshToFoam not available or timed out: {e}")

        if not gmsh_converted:
            # Fallback: try Fluent mesh conversion
            try:
                self.log.info(f"  Trying fluentMeshToFoam: {mesh_src.name}")
                result = subprocess.run(
                    ["fluentMeshToFoam", str(mesh_src), "-case", str(case_dir)],
                    capture_output=True, text=True, timeout=300
                )
                if result.returncode == 0:
                    self.log.info(f"  fluentMeshToFoam conversion successful")
                else:
                    self.log.warning(f"  fluentMeshToFoam failed: {result.stderr[:200]}")
            except (FileNotFoundError, subprocess.TimeoutExpired) as e:
                self.log.warning(f"  fluentMeshToFoam not available or timed out: {e}")

        # Verify polyMesh was populated
        if not any(poly_mesh_dir.iterdir()):
            self.log.warning(f"  polyMesh is empty after conversion attempts; copying .msh as fallback")
            shutil.copy2(mesh_src, poly_mesh_dir / "points")

        # If retry, apply relaxed under-relaxation using foamDictionary
        if is_retry:
            self._apply_relaxed_urf(case_dir)

        return case_dir

    def _apply_relaxed_urf(self, case_dir: Path) -> None:
        """
        Apply relaxed under-relaxation factors for retry.
        Uses foamDictionary to modify fvSolution.
        """
        relax = self.config.relaxation_factor
        fv_solution = case_dir / "system" / "fvSolution"
        self.log.info(f"  Applying relaxed under-relaxation factors: {relax}")

        # Ideally use foamDictionary; fallback to direct file edit
        try:
            subprocess.run(
                ["foamDictionary", "-entry", "relaxationFactors.equations.U", "-set", str(relax),
                 str(fv_solution)],
                capture_output=True, timeout=30
            )
            subprocess.run(
                ["foamDictionary", "-entry", "relaxationFactors.equations.k", "-set", str(relax),
                 str(fv_solution)],
                capture_output=True, timeout=30
            )
            subprocess.run(
                ["foamDictionary", "-entry", "relaxationFactors.equations.omega", "-set", str(relax),
                 str(fv_solution)],
                capture_output=True, timeout=30
            )
            subprocess.run(
                ["foamDictionary", "-entry", "SIMPLE.p", "-set", str(relax * 0.5),
                 str(fv_solution)],
                capture_output=True, timeout=30
            )
        except (FileNotFoundError, subprocess.TimeoutExpired, subprocess.CalledProcessError):
            # Direct file manipulation fallback
            self.log.warning("  foamDictionary not available; using sed-like replacement")
            self._edit_relaxation_factors(fv_solution, relax)

    def _edit_relaxation_factors(self, fv_solution_path: Path, relax: float) -> None:
        """Directly edit fvSolution dictionary to set relaxed under-relaxation."""
        if not fv_solution_path.exists():
            self.log.error(f"  fvSolution not found: {fv_solution_path}")
            return

        with open(fv_solution_path, "r") as f:
            content = f.read()

        # Replace equation relaxation factors
        content = re.sub(
            r'U\s+\d+\.\d+;\s*$',
            f'U                {relax};',
            content, flags=re.MULTILINE
        )
        content = re.sub(
            r'k\s+\d+\.\d+;\s*$',
            f'k                {relax};',
            content, flags=re.MULTILINE
        )
        content = re.sub(
            r'omega\s+\d+\.\d+;\s*$',
            f'omega            {relax};',
            content, flags=re.MULTILINE
        )

        with open(fv_solution_path, "w") as f:
            f.write(content)

    def run_solver(self, case_dir: Path, mesh: MeshConfig, is_retry: bool = False) -> Tuple[int, float]:
        """
        Execute the CFD solver (simpleFoam).

        Args:
            case_dir: Path to the case directory
            mesh: Mesh configuration
            is_retry: Whether this is a retry

        Returns:
            (return_code, wall_time_seconds)
        """
        max_iter = self.config.max_iterations
        n_procs = self.config.data["resources"]["n_procs"]
        use_mpi = self.config.data["resources"]["use_mpi"]
        suffix = "_retry" if is_retry else ""

        solver_log = self.project_dir / "logs" / f"{mesh.id}{suffix}.log"
        self.log.info(f"  Running solver (max {max_iter} iterations)...")
        self.log.info(f"  Log: {solver_log}")

        # Build the solver command
        if use_mpi:
            cmd = ["mpirun", "-np", str(n_procs), self.config.data["solver"], "-case", str(case_dir)]
        else:
            cmd = [self.config.data["solver"], "-case", str(case_dir)]

        start_time = time.time()

        try:
            with open(solver_log, "w") as log_file:
                log_file.write(f"# CFD Simulation: {mesh.id}\n")
                log_file.write(f"# Mesh: {mesh.file}\n")
                log_file.write(f"# Solver: {self.config.data['solver']}\n")
                log_file.write(f"# Turbulence: {self.config.data['turbulence_model']}\n")
                log_file.write(f"# Re: {self.config.data['Reynolds_number']}\n")
                log_file.write(f"# Max Iterations: {max_iter}\n")
                log_file.write(f"# Tolerance: {self.config.convergence['tolerance']}\n")
                log_file.write(f"# Retry: {is_retry}\n")
                log_file.write(f"# Started: {datetime.now(timezone.utc).isoformat()}\n")
                log_file.write("#" + "=" * 70 + "\n\n")

                process = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                )

                # Stream output to log file in real-time
                for line in process.stdout:
                    log_file.write(line)
                    log_file.flush()

                process.wait()
                return_code = process.returncode

        except FileNotFoundError:
            self.log.error(f"  Solver '{self.config.data['solver']}' not found. Is OpenFOAM installed?")
            return 127, time.time() - start_time
        except Exception as e:
            self.log.error(f"  Solver execution failed: {e}")
            return 1, time.time() - start_time

        wall_time = time.time() - start_time
        return return_code, wall_time


# ============================================================================
# Convergence Checker
# ============================================================================

class ConvergenceChecker:
    """
    Evaluates convergence based on solver log residuals.

    Convergence criteria (default: max residual < 1e-6 for all fields):
      1. No divergence markers in log
      2. All field final residuals below tolerance
      3. Residuals not stagnated for extended period
    """

    def __init__(self, config: Config):
        self.config = config
        self.tolerance = config.tolerance

    def check(self, log_path: str, mesh_id: str) -> Dict[str, Any]:
        """
        Perform comprehensive convergence check.

        Returns a dict with keys:
            converged: bool
            max_residual: float
            residuals: Dict[str, float]
            diverged: bool
            stagnation: bool
            iterations: int
            warnings: List[str]
        """
        result = {
            "converged": False,
            "max_residual": float("inf"),
            "residuals": {},
            "diverged": False,
            "stagnation": False,
            "iterations": 0,
            "warnings": [],
            "lift_coefficient": 0.0,
            "drag_coefficient": 0.0,
        }

        if not os.path.exists(log_path):
            result["warnings"].append(f"Log file not found: {log_path}")
            return result

        # Parse residuals
        diverged, final_residuals, history, warnings = ResidualParser.parse_log(log_path)
        result["diverged"] = diverged
        result["warnings"] = warnings

        # Check stagnation
        stagnation = ResidualParser.check_stagnation(
            history, self.config.data["convergence"]["stagnation_window"]
        )
        result["stagnation"] = stagnation

        # Check consecutive increase (diverging trend)
        increasing = ResidualParser.check_consecutive_increase(
            history, self.config.data["divergence_detection"]["consecutive_increase"]
        )
        if increasing:
            result["warnings"].append("Residuals increasing consecutively (diverging trend)")

        # Compute max residual
        if final_residuals:
            max_res = max(final_residuals.values())
            result["max_residual"] = max_res
            result["residuals"] = final_residuals

            # Convergence check
            result["converged"] = (
                not diverged
                and max_res < self.tolerance
                and not stagnation
            )

        # Extract iteration count
        result["iterations"] = ResidualParser.extract_iteration_count(log_path)

        # Extract forces
        cl, cd = ResidualParser.extract_forces(log_path)
        result["lift_coefficient"] = cl
        result["drag_coefficient"] = cd

        return result

    def format_residuals(self, residuals: Dict[str, float]) -> str:
        """Format residuals for display."""
        return ", ".join(f"{f}={v:.2e}" for f, v in sorted(residuals.items()))


# ============================================================================
# Summary Generator
# ============================================================================

class SummaryGenerator:
    """Generates summary.md and summary.csv from run results."""

    def __init__(self, config: Config, project_dir: Path):
        self.config = config
        self.project_dir = project_dir
        self.output_dir = project_dir / "outputs"

    def generate_markdown(self, results: List[RunResult], run_start: float, run_end: float) -> str:
        """Generate a comprehensive summary markdown file."""
        total_duration = run_end - run_start
        passed = sum(1 for r in results if r.status == "PASS")
        failed = sum(1 for r in results if r.status == "FAIL")
        skipped = sum(1 for r in results if r.status == "SKIP")

        lines = []
        lines.append("# CFD Turbulence Simulation Batch Summary")
        lines.append("")
        lines.append(f"**Date:** {datetime.fromtimestamp(run_start, tz=timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}")
        lines.append(f"**Solver:** {self.config.data['solver']} ({self.config.data['turbulence_model']})")
        lines.append(f"**Reynolds Number:** {self.config.data['Reynolds_number']:.0e}")
        lines.append(f"**Convergence Tolerance:** {self.config.tolerance:.0e}")
        lines.append(f"**Total Wall Time:** {self._format_duration(total_duration)}")
        lines.append(f"**Meshes:** {len(results)} total, {passed} passed, {failed} failed, {skipped} skipped")
        lines.append("")

        # Summary table
        lines.append("## Results Overview")
        lines.append("")
        lines.append("| Mesh | Airfoil | Cells | Status | Max Residual | Iterations | Cl | Cd | Wall Time | Retries |")
        lines.append("|------|---------|-------|--------|-------------|-----------|----|----|-----------|---------|")

        for r in results:
            mesh_cfg = next((m for m in self.config.meshes if m.id == r.mesh_id), None)
            airfoil = mesh_cfg.airfoil if mesh_cfg else "-"
            cells = str(mesh_cfg.cell_count) if mesh_cfg else "-"

            max_res_str = f"{r.max_residual:.2e}" if r.max_residual < float("inf") else "N/A"
            status_emoji = {"PASS": "PASS", "FAIL": "FAIL", "SKIP": "SKIP", "ERROR": "ERROR"}
            cl_str = f"{r.lift_coefficient:.4f}" if r.lift_coefficient != 0.0 else "-"
            cd_str = f"{r.drag_coefficient:.4f}" if r.drag_coefficient != 0.0 else "-"

            lines.append(
                f"| {r.mesh_id} | {airfoil} | {cells} | {status_emoji.get(r.status, r.status)} | "
                f"{max_res_str} | {r.iterations} | {cl_str} | {cd_str} | "
                f"{self._format_duration(r.wall_time_seconds)} | {r.retries} |"
            )

        lines.append("")

        # Per-field residuals
        lines.append("## Detailed Residuals")
        lines.append("")
        for r in results:
            if r.residuals:
                lines.append(f"### {r.mesh_id}")
                lines.append("")
                lines.append("| Field | Final Residual | Converged? |")
                lines.append("|-------|---------------|------------|")
                for field, val in sorted(r.residuals.items()):
                    tick = "Yes" if val < self.config.tolerance else "No"
                    lines.append(f"| {field} | {val:.2e} | {tick} |")
                lines.append("")

        # Error log
        if any(r.error_message for r in results if r.status != "PASS"):
            lines.append("## Errors and Warnings")
            lines.append("")
            for r in results:
                if r.error_message:
                    lines.append(f"- **{r.mesh_id}:** {r.error_message}")
            lines.append("")

        # Configuration reference
        lines.append("## Configuration")
        lines.append("")
        lines.append(f"- Tolerance: {self.config.tolerance:.0e}")
        lines.append(f"- Max retries: {self.config.max_retries}")
        lines.append(f"- Retry relaxation factor: {self.config.relaxation_factor}")
        lines.append(f"- Max iterations: {self.config.max_iterations}")
        lines.append(f"- Divergence threshold: {self.config.data['divergence_detection']['residual_spike_threshold']}")
        lines.append("")

        return "\n".join(lines)

    def generate_csv(self, results: List[RunResult]) -> str:
        """Generate CSV summary."""
        import io
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow([
            "mesh_id", "status", "converged", "max_residual",
            "iterations", "wall_time_seconds", "retries",
            "lift_coefficient", "drag_coefficient", "error_message"
        ])
        for r in results:
            writer.writerow([
                r.mesh_id, r.status, r.convergence, r.max_residual,
                r.iterations, r.wall_time_seconds, r.retries,
                r.lift_coefficient, r.drag_coefficient, r.error_message
            ])
        return output.getvalue()

    def _format_duration(self, seconds: float) -> str:
        """Format wall time for human display."""
        if seconds < 60:
            return f"{seconds:.1f}s"
        elif seconds < 3600:
            return f"{seconds/60:.1f}m"
        else:
            hours = int(seconds // 3600)
            minutes = int((seconds % 3600) // 60)
            return f"{hours}h{minutes}m"

    def write_all(self, results: List[RunResult], run_start: float, run_end: float) -> None:
        """Write both summary.md and summary.csv."""
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Markdown
        md_path = self.output_dir / "summary.md"
        md_content = self.generate_markdown(results, run_start, run_end)
        with open(md_path, "w") as f:
            f.write(md_content)
        print(f"[INFO] Summary written to {md_path}")

        # CSV
        csv_path = self.output_dir / "summary.csv"
        csv_content = self.generate_csv(results)
        with open(csv_path, "w") as f:
            f.write(csv_content)
        print(f"[INFO] CSV written to {csv_path}")


# ============================================================================
# Main Loop Orchestrator
# ============================================================================

class LoopOrchestrator:
    """
    Main automation loop.

    For each mesh:
      1. Check if already completed (resume safety)
      2. Set up case directory from template
      3. Run solver (simpleFoam, k-omega SST)
      4. Check convergence (residuals < 1e-6)
      5. If converged -> record as PASS
      6. If diverged -> retry once with relaxed URF
      7. If retry also fails -> mark as FAIL/SKIP
      8. Generate summary after all meshes processed
    """

    def __init__(self, config: Config, project_dir: Path, dry_run: bool = False):
        self.config = config
        self.project_dir = project_dir
        self.dry_run = dry_run

        # Setup logging
        self.log_dir = project_dir / "logs"
        self.log_dir.mkdir(parents=True, exist_ok=True)

        log_file = self.log_dir / f"run_loop_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s [%(levelname)s] %(message)s",
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(),
            ]
        )
        self.log = logging.getLogger("CFD_Loop")

        self.solver = SolverInterface(config, project_dir, self.log)
        self.checker = ConvergenceChecker(config)
        self.summarizer = SummaryGenerator(config, project_dir)
        self.results: List[RunResult] = []

        self.log.info("=" * 70)
        self.log.info("CFD Turbulence Simulation Loop — Initialized")
        self.log.info(f"Project: {project_dir}")
        self.log.info(f"Solver: {config.data['solver']} ({config.data['turbulence_model']})")
        self.log.info(f"Meshes: {len(config.meshes)}")
        self.log.info(f"Tolerance: {config.tolerance}")
        self.log.info(f"Max retries: {config.max_retries}")
        self.log.info(f"Dry run: {dry_run}")
        self.log.info("=" * 70)

    def run(self) -> int:
        """Execute the full batch loop."""
        run_start = time.time()
        self.log.info(f"Starting batch loop at {datetime.fromtimestamp(run_start, tz=timezone.utc).isoformat()}")

        for idx, mesh in enumerate(self.config.meshes, 1):
            self.log.info(f"\n[{idx}/{len(self.config.meshes)}] Processing mesh: {mesh.id} ({mesh.description})")

            result = self._process_mesh(mesh)
            self.results.append(result)

        run_end = time.time()
        self.log.info("\n" + "=" * 70)
        self.log.info(f"Batch loop complete. Total time: {self._format_duration(run_end - run_start)}")
        passed = sum(1 for r in self.results if r.status == "PASS")
        failed = sum(1 for r in self.results if r.status == "FAIL")
        self.log.info(f"Results: {passed} passed, {failed} failed")
        self.log.info("=" * 70)

        # Generate summaries
        if not self.dry_run:
            self.summarizer.write_all(self.results, run_start, run_end)

        return 0 if failed == 0 else 1

    def _process_mesh(self, mesh: MeshConfig) -> RunResult:
        """Process a single mesh through the simulation pipeline."""

        # --- Resume check ---
        result_file = self.project_dir / "outputs" / f"{mesh.id}_result.json"
        if result_file.exists():
            try:
                with open(result_file) as f:
                    data = json.load(f)
                self.log.info(f"  Already completed (found {result_file}). Skipping.")
                return RunResult(**data)
            except (json.JSONDecodeError, KeyError):
                self.log.info(f"  Incomplete result file found; re-running.")

        # --- Initial run ---
        self.log.info(f"  Phase 1: Initial run")

        if self.dry_run:
            return RunResult(
                mesh_id=mesh.id,
                status="SKIP",
                convergence=False,
                max_residual=float("inf"),
                residuals={},
                iterations=0,
                wall_time_seconds=0.0,
                retries=0,
                solver_log="",
            )

        case_dir = self.solver.setup_case(mesh, is_retry=False)
        return_code, wall_time = self.solver.run_solver(case_dir, mesh, is_retry=False)

        log_path = self.project_dir / "logs" / f"{mesh.id}.log"
        check = self.checker.check(str(log_path), mesh.id)

        # --- Check result ---
        if check["converged"]:
            result = RunResult(
                mesh_id=mesh.id,
                status="PASS",
                convergence=True,
                max_residual=check["max_residual"],
                residuals=check["residuals"],
                iterations=check["iterations"],
                wall_time_seconds=wall_time,
                retries=0,
                solver_log=str(log_path),
                lift_coefficient=check["lift_coefficient"],
                drag_coefficient=check["drag_coefficient"],
            )
            self.log.info(f"  PASS: Converged in {check['iterations']} iterations. "
                         f"Max residual: {check['max_residual']:.2e}")
            self._save_result(result)
            return result

        # --- Handle failure / divergence ---
        failure_reason = []
        if check["diverged"]:
            failure_reason.append("diverged")
        if check["stagnation"]:
            failure_reason.append("stagnated")
        if not check["residuals"]:
            failure_reason.append("no residuals extracted")
        if return_code != 0:
            failure_reason.append(f"solver exited with code {return_code}")

        reason = ", ".join(failure_reason) if failure_reason else "unknown"
        self.log.warning(f"  Initial run FAILED: {reason}")

        # --- Retry logic ---
        if self.config.max_retries > 0:
            self.log.info(f"  Phase 2: Retry #{1} with relaxed under-relaxation ({self.config.relaxation_factor})")
            retry_case_dir = self.solver.setup_case(mesh, is_retry=True)
            retry_return, retry_wall = self.solver.run_solver(retry_case_dir, mesh, is_retry=True)

            retry_log_path = self.project_dir / "logs" / f"{mesh.id}_retry.log"
            retry_check = self.checker.check(str(retry_log_path), mesh.id)

            if retry_check["converged"]:
                result = RunResult(
                    mesh_id=mesh.id,
                    status="PASS",
                    convergence=True,
                    max_residual=retry_check["max_residual"],
                    residuals=retry_check["residuals"],
                    iterations=retry_check["iterations"],
                    wall_time_seconds=wall_time + retry_wall,
                    retries=1,
                    solver_log=str(retry_log_path),
                    error_message=f"Initial run failed ({reason}); converged on retry",
                    lift_coefficient=retry_check["lift_coefficient"],
                    drag_coefficient=retry_check["drag_coefficient"],
                )
                self.log.info(f"  PASS on retry: Converged in {retry_check['iterations']} iterations. "
                             f"Max residual: {retry_check['max_residual']:.2e}")
                self._save_result(result)
                return result
            else:
                retry_reason = "diverged" if retry_check["diverged"] else "not converged"
                self.log.warning(f"  Retry also FAILED: {retry_reason}")
                result = RunResult(
                    mesh_id=mesh.id,
                    status="FAIL",
                    convergence=False,
                    max_residual=retry_check["max_residual"],
                    residuals=retry_check["residuals"],
                    iterations=retry_check["iterations"],
                    wall_time_seconds=wall_time + retry_wall,
                    retries=1,
                    solver_log=str(retry_log_path),
                    error_message=f"Initial run failed ({reason}); retry also {retry_reason}",
                )
                self._save_result(result)
                return result

        # --- No retries left, mark as FAIL ---
        result = RunResult(
            mesh_id=mesh.id,
            status="FAIL",
            convergence=False,
            max_residual=check["max_residual"],
            residuals=check["residuals"],
            iterations=check["iterations"],
            wall_time_seconds=wall_time,
            retries=0,
            solver_log=str(log_path),
            error_message=reason,
        )
        self._save_result(result)
        return result

    def _save_result(self, result: RunResult) -> None:
        """Save per-mesh result as JSON for resume safety."""
        output_dir = self.project_dir / "outputs"
        output_dir.mkdir(parents=True, exist_ok=True)
        result_path = output_dir / f"{result.mesh_id}_result.json"
        with open(result_path, "w") as f:
            json.dump(asdict(result), f, indent=2, default=str)
        self.log.info(f"  Result saved: {result_path}")

    @staticmethod
    def _format_duration(seconds: float) -> str:
        if seconds < 60:
            return f"{seconds:.1f}s"
        elif seconds < 3600:
            return f"{seconds/60:.1f}m"
        else:
            hours = int(seconds // 3600)
            minutes = int((seconds % 3600) // 60)
            return f"{hours}h{minutes}m"


# ============================================================================
# CLI Entry Point
# ============================================================================

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="CFD Turbulence Simulation Loop — Batch Automation",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                                          # Run all meshes with defaults
  %(prog)s --mesh-list mesh_1 mesh_3 mesh_5        # Run specific meshes only
  %(prog)s --config my_config.yaml                  # Use custom config
  %(prog)s --dry-run                                # Print plan without executing
  %(prog)s --tolerance 1e-8                         # Override convergence tolerance
        """
    )
    parser.add_argument("--config", default="configs/solver_config.yaml",
                        help="Solver configuration YAML (default: configs/solver_config.yaml)")
    parser.add_argument("--meshes", default="configs/mesh_list.yaml",
                        help="Mesh list YAML (default: configs/mesh_list.yaml)")
    parser.add_argument("--mesh-list", nargs="+", default=None,
                        help="Space-separated list of mesh IDs to run (overrides --meshes)")
    parser.add_argument("--tolerance", type=float, default=None,
                        help="Convergence tolerance override (default: 1e-6)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print execution plan without running simulations")
    parser.add_argument("--project-dir", default=".",
                        help="Project root directory (default: current directory)")
    return parser.parse_args()


def main():
    args = parse_args()

    # Resolve project directory
    project_dir = Path(args.project_dir).resolve()
    if not project_dir.exists():
        print(f"[ERROR] Project directory not found: {project_dir}")
        sys.exit(1)

    # Load configuration
    config_path = str(project_dir / args.config) if not os.path.isabs(args.config) else args.config
    meshes_path = str(project_dir / args.meshes) if not os.path.isabs(args.meshes) else args.meshes

    config = Config(config_path, meshes_path)

    # Override tolerance from CLI
    if args.tolerance is not None:
        config.data["convergence"]["tolerance"] = args.tolerance

    # Override mesh list from CLI
    if args.mesh_list:
        all_meshes = {m.id: m for m in config.meshes}
        config.meshes = [all_meshes[mid] for mid in args.mesh_list if mid in all_meshes]
        if len(config.meshes) != len(args.mesh_list):
            missing = set(args.mesh_list) - set(all_meshes.keys())
            print(f"[WARNING] Unknown meshes: {missing}")

    if not config.meshes:
        print("[ERROR] No meshes configured. Check mesh_list.yaml.")
        sys.exit(1)

    # Print execution plan
    print("=" * 70)
    print("CFD Turbulence Simulation Loop — Execution Plan")
    print("=" * 70)
    print(f"  Solver:      {config.data['solver']} ({config.data['turbulence_model']})")
    print(f"  Re:          {config.data['Reynolds_number']:.0e}")
    print(f"  Tolerance:   {config.tolerance:.0e}")
    print(f"  Max retries: {config.max_retries}")
    print(f"  Dry run:     {args.dry_run}")
    print(f"  Meshes:")
    for m in config.meshes:
        print(f"    - {m.id:8s} | {m.description:40s} | {m.cell_count:>6d} cells")
    print("=" * 70)

    if args.dry_run:
        print("\n[Dry run mode] No simulations will be executed.")
        sys.exit(0)

    # Run the loop
    orchestrator = LoopOrchestrator(config, project_dir)
    exit_code = orchestrator.run()
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
