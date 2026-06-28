#!/usr/bin/env python3
"""
Independent Verification Gate for PINN Training Outputs.

This script reads ONLY the output files (loss_curve.csv, metrics.json)
and verifies them. It has ZERO knowledge of the training internals,
chain-of-thought, or failure modes of the trainer.

This is the verifier in the loop's "Writer → Verifier" separation pattern.

Usage:
    python pinn/verify.py outputs/pinn_lr1e-3_w64_act_tanh

Exit code:
    0 = PASS (output is valid)
    1 = FAIL (output has issues)
"""

import argparse
import csv
import json
import os
import sys
import numpy as np


def verify_config(output_dir: str) -> dict:
    """Run all verification checks on a config output directory.

    Args:
        output_dir: Path to config output directory

    Returns:
        dict with keys: passed (bool), checks (list of check results),
        summary (str)
    """
    config_name = os.path.basename(os.path.normpath(output_dir))
    checks = []
    all_passed = True

    # ---- Check 1: Required files exist ---- #
    required_files = ["metrics.json", "loss_curve.csv", "config.json"]
    for fname in required_files:
        fpath = os.path.join(output_dir, fname)
        exists = os.path.isfile(fpath)
        checks.append({
            "check": f"file_exists:{fname}",
            "passed": exists,
            "detail": f"{fpath} {'exists' if exists else 'MISSING'}",
        })
        if not exists:
            all_passed = False

    # Early exit if critical files missing
    metrics_path = os.path.join(output_dir, "metrics.json")
    csv_path = os.path.join(output_dir, "loss_curve.csv")

    if not os.path.isfile(metrics_path):
        return {
            "passed": False,
            "checks": checks,
            "summary": "CRITICAL: metrics.json missing — cannot verify",
            "status": "FAILED_MISSING_METRICS",
            "config_name": config_name,
        }

    # ---- Check 2: metrics.json is valid JSON and contains required fields ---- #
    try:
        with open(metrics_path) as f:
            metrics = json.load(f)
    except json.JSONDecodeError as e:
        checks.append({
            "check": "metrics_json_valid",
            "passed": False,
            "detail": f"Invalid JSON: {e}",
        })
        return {
            "passed": False,
            "checks": checks,
            "summary": "CRITICAL: metrics.json is not valid JSON",
            "status": "FAILED_INVALID_JSON",
            "config_name": config_name,
        }

    required_metrics = ["status", "final_losses", "steps_completed"]
    for field in required_metrics:
        has = field in metrics
        checks.append({
            "check": f"metrics_field:{field}",
            "passed": has,
            "detail": f"Field '{field}' {'present' if has else 'MISSING'}",
        })
        if not has:
            all_passed = False

    # ---- Check 3: Status is DONE (not FAILED) ---- #
    status = metrics.get("status", "UNKNOWN")
    status_ok = status == "DONE"
    checks.append({
        "check": "status_done",
        "passed": status_ok,
        "detail": f"Status: {status}",
    })
    if not status_ok:
        all_passed = False

    # ---- Check 4: No NaN or Inf in final losses ---- #
    final_losses = metrics.get("final_losses", {})
    nan_found = False
    for key, val in final_losses.items():
        if val is None or (isinstance(val, float) and (np.isnan(val) or np.isinf(val))):
            checks.append({
                "check": f"loss_nan:{key}",
                "passed": False,
                "detail": f"{key} = {val}",
            })
            nan_found = True
            all_passed = False

    if not nan_found:
        checks.append({
            "check": "loss_nan_check",
            "passed": True,
            "detail": "No NaN/Inf in final losses",
        })

    # ---- Check 5: Steps completed >= expected ---- #
    steps = metrics.get("steps_completed", 0)
    # Read config to get expected steps
    expected_steps = 50000  # default
    config_path = os.path.join(output_dir, "config.json")
    if os.path.isfile(config_path):
        try:
            with open(config_path) as f:
                cfg = json.load(f)
            expected_steps = cfg.get("steps", 50000)
        except (json.JSONDecodeError, OSError):
            pass

    steps_ok = steps >= expected_steps
    checks.append({
        "check": "steps_completed",
        "passed": steps_ok,
        "detail": f"Steps: {steps}/{expected_steps}",
    })
    if not steps_ok:
        all_passed = False

    # ---- Check 6: loss_curve.csv parses and has valid entries ---- #
    if os.path.isfile(csv_path):
        try:
            with open(csv_path, newline="") as f:
                reader = csv.DictReader(f)
                rows = list(reader)

            n_rows = len(rows)
            rows_ok = n_rows >= 2  # at least some logging happened (step 1 + final)
            checks.append({
                "check": "csv_has_rows",
                "passed": rows_ok,
                "detail": f"CSV has {n_rows} rows",
            })
            if not rows_ok:
                all_passed = False

            # Check for NaN in CSV loss values
            csv_nan_count = 0
            for i, row in enumerate(rows):
                loss_total = row.get("loss_total", "")
                try:
                    val = float(loss_total)
                    if np.isnan(val) or np.isinf(val):
                        csv_nan_count += 1
                except (ValueError, TypeError):
                    csv_nan_count += 1

            csv_nan_ok = csv_nan_count == 0
            checks.append({
                "check": "csv_no_nan",
                "passed": csv_nan_ok,
                "detail": f"NaN/Invalid entries in loss_total: {csv_nan_count}/{n_rows}",
            })
            if not csv_nan_ok:
                all_passed = False

            # Check loss curve is monotonically decreasing-ish (not strictly)
            if n_rows >= 2:
                loss_vals = []
                for row in rows:
                    try:
                        loss_vals.append(float(row.get("loss_total", "nan")))
                    except (ValueError, TypeError):
                        loss_vals.append(float("nan"))

                valid_losses = [v for v in loss_vals if not np.isnan(v) and not np.isinf(v)]
                if len(valid_losses) >= 2:
                    # Check final loss < initial loss (convergence signal)
                    initial_avg = valid_losses[0]
                    final_avg = valid_losses[-1]
                    convergence = final_avg < initial_avg
                    checks.append({
                        "check": "loss_convergence",
                        "passed": convergence,
                        "detail": f"Initial avg loss: {initial_avg:.4e}, "
                                  f"Final avg loss: {final_avg:.4e} "
                                  f"({'converged' if convergence else 'DIVERGED'})",
                    })
                    if not convergence:
                        # Convergence failure is informational, not a hard fail
                        # (some configs genuinely diverge)
                        pass

        except Exception as e:
            checks.append({
                "check": "csv_parse",
                "passed": False,
                "detail": f"Error parsing CSV: {e}",
            })
            all_passed = False
    else:
        checks.append({
            "check": "csv_file",
            "passed": False,
            "detail": "loss_curve.csv not found",
        })
        all_passed = False

    # ---- Summary ---- #
    n_passed = sum(1 for c in checks if c["passed"])
    n_total = len(checks)

    summary = (
        f"VERIFICATION: {n_passed}/{n_total} checks passed"
        f" — {'PASS' if all_passed else 'FAIL'}"
    )

    return {
        "passed": all_passed,
        "checks": checks,
        "summary": summary,
        "status": "VERIFIED" if all_passed else "FAILED_VERIFICATION",
        "config_name": os.path.basename(output_dir),
    }


def main():
    parser = argparse.ArgumentParser(
        description="Verify PINN training output — independent gate"
    )
    parser.add_argument("output_dir", type=str, help="Path to config output directory")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show all checks")
    args = parser.parse_args()

    result = verify_config(args.output_dir)

    print("=" * 60)
    print(f"PINN Verification Gate — {result['config_name']}")
    print("=" * 60)

    for check in result["checks"]:
        status = "PASS" if check["passed"] else "FAIL"
        print(f"  [{status}] {check['check']}: {check['detail']}")

    print("-" * 60)
    print(result["summary"])
    print(f"Overall status: {result['status']}")

    return 0 if result["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
