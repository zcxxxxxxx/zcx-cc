#!/usr/bin/env python3
"""Reusable equation solver loop: reads problems from JSON, evaluates, writes STATE.md.

Usage:
    python equation-solver.py problems.json

Problems JSON format:
    [
        {"id": 1, "expr": "2 + 2", "expected": 4, "tolerance": 0.01},
        {"id": 2, "expr": "3 * 7", "expected": 21}
    ]

Customize by editing SOLVER_CONFIG below.
"""
import json
import math
import sys
from pathlib import Path

# ── Configuration (customize per task) ─────────────────────────────
SOLVER_CONFIG = {
    "default_tolerance": 0.01,
    "safe_builtins": {"abs": abs, "round": round, "min": min, "max": max,
                      "pow": pow, "sum": sum, "float": float, "int": int,
                      "math": math},
}
# ────────────────────────────────────────────────────────────────────


def safe_eval(expr: str) -> float:
    """Evaluate a mathematical expression safely using restricted builtins."""
    return float(eval(expr, {"__builtins__": {}}, SOLVER_CONFIG["safe_builtins"]))


def solve(problems_path: Path) -> list:
    """Read problems, evaluate each, return list of result dicts."""
    with open(problems_path) as f:
        problems = json.load(f)

    results = []
    for p in problems:
        pid = p["id"]
        expr = p["expr"]
        expected = float(p["expected"])
        tol = float(p.get("tolerance", SOLVER_CONFIG["default_tolerance"]))

        try:
            actual = safe_eval(expr)
            passed = abs(actual - expected) <= tol
        except Exception as e:
            actual = None
            passed = False
            error = str(e)

        results.append({
            "id": pid,
            "expr": expr,
            "expected": expected,
            "actual": actual,
            "passed": passed,
            "error": error if not passed and actual is None else "",
        })
    return results


def write_state(results: list):
    """Write lightweight code-task STATE.md with pass/fail per problem."""
    total = len(results)
    passed = sum(1 for r in results if r["passed"])
    lines = ["# Equation Solver State\n"]
    lines.append(f"**Total:** {total}  **Passed:** {passed}  **Failed:** {total - passed}\n")

    lines.append("| # | Expression | Expected | Actual | Status |")
    lines.append("|---|------------|----------|--------|--------|")
    for r in results:
        actual_str = f"{r['actual']:.6f}" if r["actual"] is not None else "ERR"
        status = "PASS" if r["passed"] else "FAIL"
        err = f" ({r['error']})" if r.get("error") else ""
        lines.append(f"| {r['id']} | `{r['expr']}` | {r['expected']} | {actual_str} | {status}{err} |")

    if passed == total:
        lines.append("\nAll problems passed.")
    else:
        lines.append(f"\n{total - passed} problem(s) failed — review above.")

    state_path = Path("STATE.md")
    state_path.write_text("\n".join(lines) + "\n")
    print(f"Wrote {state_path}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python equation-solver.py <problems.json>")
        sys.exit(1)

    problems_path = Path(sys.argv[1])
    if not problems_path.exists():
        print(f"File not found: {problems_path}")
        sys.exit(1)

    results = solve(problems_path)
    write_state(results)

    passed = sum(1 for r in results if r["passed"])
    print(f"\n{passed}/{len(results)} problems passed")
    sys.exit(0 if passed == len(results) else 1)
