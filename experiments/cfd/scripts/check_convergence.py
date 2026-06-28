#!/usr/bin/env python3
"""
CFD Convergence Checker
=======================
Standalone script to check if an OpenFOAM solver log shows convergence.

Usage:
    python scripts/check_convergence.py logs/mesh_1.log          # Check with default tolerance (1e-6)
    python scripts/check_convergence.py logs/mesh_1.log --tol 1e-8  # Custom tolerance
    python scripts/check_convergence.py logs/mesh_1.log --json      # JSON output

Exit codes:
    0 — PASS (all residuals below tolerance)
    1 — FAIL (residuals above tolerance or divergence detected)
    2 — ERROR (log file not found or unparseable)
"""

import os
import sys
import re
import json
import argparse


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
    re.compile(r"Floating point exception", re.IGNORECASE),
]


def check_convergence(log_path: str, tolerance: float) -> dict:
    """Check convergence of an OpenFOAM solver log."""
    result = {
        "status": "ERROR",
        "converged": False,
        "max_residual": float("inf"),
        "residuals": {},
        "iterations": 0,
        "diverged": False,
        "warnings": [],
    }

    if not os.path.exists(log_path):
        result["warnings"].append(f"File not found: {log_path}")
        return result

    final_residuals = {}
    diverged = False

    with open(log_path, "r") as f:
        for line in f:
            # Check divergence
            for pat in DIVERGENCE_PATTERNS:
                if pat.search(line):
                    diverged = True
                    result["warnings"].append(f"Divergence: {line.strip()}")
                    break

            # Parse residuals
            match = RESIDUAL_PATTERN.search(line)
            if match:
                field = match.group("field")
                final_residuals[field] = float(match.group("final"))

    result["diverged"] = diverged

    if final_residuals:
        max_res = max(final_residuals.values())
        result["residuals"] = final_residuals
        result["max_residual"] = max_res
        result["converged"] = (not diverged and max_res < tolerance)
        # Extract iteration count by counting time steps in the log
        time_pattern = re.compile(r"^Time\s*=\s*(\d+)", re.MULTILINE)
        with open(log_path, "r") as f:
            content = f.read()
        time_matches = time_pattern.findall(content)
        result["iterations"] = int(time_matches[-1]) if time_matches else 0
        result["status"] = "PASS" if result["converged"] else "FAIL"
    else:
        result["warnings"].append("No residuals found in log")

    return result


def main():
    parser = argparse.ArgumentParser(description="Check OpenFOAM solver log convergence")
    parser.add_argument("log_file", help="Path to solver log file")
    parser.add_argument("--tol", type=float, default=1e-6, help="Convergence tolerance (default: 1e-6)")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    result = check_convergence(args.log_file, args.tol)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        if result["status"] == "PASS":
            print(f"PASS: max_residual={result['max_residual']:.2e} < tol={args.tol:.0e}")
        elif result["status"] == "FAIL":
            print(f"FAIL: max_residual={result['max_residual']:.2e} >= tol={args.tol:.0e}")
            if result["diverged"]:
                print("       Divergence detected in log.")
        else:
            print(f"ERROR: {'; '.join(result['warnings'])}")

    # Exit codes matching shell convention
    if result["status"] == "PASS":
        sys.exit(0)
    elif result["status"] == "FAIL":
        sys.exit(1)
    else:
        sys.exit(2)


if __name__ == "__main__":
    main()
