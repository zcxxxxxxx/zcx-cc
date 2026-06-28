#!/usr/bin/env python3
"""
Aggregate all PINN sweep results, rank by validation loss,
and produce parameter influence analysis.

This is the final step after all configs have been processed
(DONE or FAILED).

Output:
    - outputs/sweep_results.csv — all configs with metrics
    - outputs/sweep_ranking.md — ranked results with influence analysis

Usage:
    python scripts/aggregate_results.py experiments/pinn_hp_search
    (run from the experiments/pinn_hp_search directory)
"""

import csv
import json
import os
import sys
import numpy as np


def collect_results(experiment_dir):
    """Walk all config output dirs and collect metrics."""
    outputs_dir = os.path.join(experiment_dir, "outputs")
    if not os.path.isdir(outputs_dir):
        print(f"[ERROR] Outputs directory not found: {outputs_dir}")
        return []

    results = []
    for item in sorted(os.listdir(outputs_dir)):
        item_path = os.path.join(outputs_dir, item)
        metrics_path = os.path.join(item_path, "metrics.json")
        config_path = os.path.join(item_path, "config.json")

        if not os.path.isdir(item_path):
            continue
        if not os.path.isfile(metrics_path):
            results.append({
                "config_name": item,
                "status": "NO_DATA",
                "learning_rate": None,
                "hidden_width": None,
                "activation": None,
                "val_loss": None,
                "train_loss": None,
                "wall_time_sec": None,
                "steps_completed": 0,
                "file": item_path,
            })
            continue

        with open(metrics_path) as f:
            metrics = json.load(f)

        # Get hyperparams from config
        lr = None
        width = None
        act = None
        if os.path.isfile(config_path):
            with open(config_path) as f:
                cfg = json.load(f)
            lr = cfg.get("learning_rate", None)
            width = cfg.get("hidden_width", None)
            act = cfg.get("activation", None)

        final_losses = metrics.get("final_losses", {})
        val_loss = final_losses.get("val", None)
        if val_loss is not None:
            try:
                val_loss = float(val_loss)
            except (ValueError, TypeError):
                val_loss = None

        train_loss = final_losses.get("total", None)
        if train_loss is not None:
            try:
                train_loss = float(train_loss)
            except (ValueError, TypeError):
                train_loss = None

        results.append({
            "config_name": item,
            "status": metrics.get("status", "UNKNOWN"),
            "learning_rate": lr,
            "hidden_width": width,
            "activation": act,
            "val_loss": val_loss,
            "train_loss": train_loss,
            "wall_time_sec": metrics.get("wall_time_sec", None),
            "steps_completed": metrics.get("steps_completed", 0),
            "file": item_path,
        })

    return results


def analyze_parameter_influence(results):
    """Analyze which parameters most affect validation loss.

    Groups results by each hyperparameter and computes mean val_loss
    per group to isolate parameter influence.

    Returns dict of parameter influence analysis.
    """
    done_results = [r for r in results if r["status"] == "DONE"
                    and r["val_loss"] is not None
                    and not np.isnan(r["val_loss"])]

    if len(done_results) < 4:
        return {"warning": "Too few DONE results for meaningful analysis",
                "n_successful": len(done_results)}

    analysis = {"n_successful": len(done_results)}

    # Influence of learning rate
    lr_groups = {}
    for r in done_results:
        lr = r["learning_rate"]
        if lr not in lr_groups:
            lr_groups[lr] = []
        lr_groups[lr].append(r["val_loss"])

    analysis["learning_rate_analysis"] = {
        str(lr): {
            "mean_val_loss": float(np.mean(vals)),
            "std_val_loss": float(np.std(vals)),
            "min_val_loss": float(np.min(vals)),
            "count": len(vals),
        }
        for lr, vals in sorted(lr_groups.items())
    }

    # Influence of hidden width
    width_groups = {}
    for r in done_results:
        w = r["hidden_width"]
        if w not in width_groups:
            width_groups[w] = []
        width_groups[w].append(r["val_loss"])

    analysis["width_analysis"] = {
        str(w): {
            "mean_val_loss": float(np.mean(vals)),
            "std_val_loss": float(np.std(vals)),
            "min_val_loss": float(np.min(vals)),
            "count": len(vals),
        }
        for w, vals in sorted(width_groups.items())
    }

    # Influence of activation
    act_groups = {}
    for r in done_results:
        a = r["activation"]
        if a not in act_groups:
            act_groups[a] = []
        act_groups[a].append(r["val_loss"])

    analysis["activation_analysis"] = {
        a: {
            "mean_val_loss": float(np.mean(vals)),
            "std_val_loss": float(np.std(vals)),
            "min_val_loss": float(np.min(vals)),
            "count": len(vals),
        }
        for a, vals in sorted(act_groups.items())
    }

    # Best combination analysis
    # Find the best config in each parameter group
    analysis["best_by_parameter"] = {
        "learning_rate": min(
            analysis["learning_rate_analysis"].items(),
            key=lambda x: x[1]["mean_val_loss"]
        )[0],
        "hidden_width": min(
            analysis["width_analysis"].items(),
            key=lambda x: x[1]["mean_val_loss"]
        )[0],
        "activation": min(
            analysis["activation_analysis"].items(),
            key=lambda x: x[1]["mean_val_loss"]
        )[0],
    }

    return analysis


def write_csv(results, path):
    """Write aggregated results to CSV."""
    fieldnames = [
        "config_name", "status", "learning_rate", "hidden_width",
        "activation", "val_loss", "train_loss", "wall_time_sec",
        "steps_completed",
    ]
    with open(path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in results:
            writer.writerow({k: r.get(k, "") for k in fieldnames})
    print(f"[AGG] Results written to: {path}")


def write_ranking_md(results, analysis, path):
    """Write ranked results with analysis to markdown."""
    done_results = [r for r in results if r["status"] == "DONE"
                    and r["val_loss"] is not None
                    and not (isinstance(r["val_loss"], float) and np.isnan(r["val_loss"]))]

    # Sort by val_loss ascending
    ranked = sorted(done_results, key=lambda r: r["val_loss"])

    with open(path, "w", encoding="utf-8") as f:
        f.write("# PINN Hyperparameter Search — Results Ranking\n\n")

        f.write(f"**Generated:** 2026-06-28\n\n")
        f.write(f"**Total configs:** {len(results)}\n")
        f.write(f"**DONE:** {len(done_results)}\n")
        failed = [r for r in results if r["status"] != "DONE"]
        f.write(f"**FAILED:** {len(failed)}\n\n")

        f.write("---\n\n")
        f.write("## Top-3 Configurations\n\n")

        if ranked:
            f.write("| Rank | Config | Learning Rate | Width | Activation | Validation Loss | Wall Time |\n")
            f.write("|------|--------|---------------|-------|------------|----------------|-----------|\n")
            for i, r in enumerate(ranked[:3], 1):
                val_loss = f"{r['val_loss']:.6e}" if r['val_loss'] is not None else "N/A"
                wall_time = f"{r['wall_time_sec']:.0f}s" if r['wall_time_sec'] else "N/A"
                f.write(
                    f"| {i} | {r['config_name']} | {r['learning_rate']} | "
                    f"{r['hidden_width']} | {r['activation']} | "
                    f"{val_loss} | {wall_time} |\n"
                )
        else:
            f.write("No successful configurations.\n")

        f.write("\n## All Ranked Results\n\n")
        if ranked:
            f.write("| Rank | Config | LR | Width | Act | Val Loss | Wall Time | Steps |\n")
            f.write("|------|--------|----|-------|-----|----------|-----------|-------|\n")
            for i, r in enumerate(ranked, 1):
                val_loss = f"{r['val_loss']:.6e}" if r['val_loss'] is not None else "N/A"
                wall_time = f"{r['wall_time_sec']:.0f}s" if r['wall_time_sec'] else "N/A"
                steps = r.get("steps_completed", 0)
                f.write(
                    f"| {i} | {r['config_name']} | {r['learning_rate']} | "
                    f"{r['hidden_width']} | {r['activation']} | "
                    f"{val_loss} | {wall_time} | {steps} |\n"
                )

        if failed:
            f.write("\n## Failed Configurations\n\n")
            f.write("| Config | Status |\n")
            f.write("|--------|--------|\n")
            for r in failed:
                f.write(f"| {r['config_name']} | {r['status']} |\n")

        f.write("\n---\n\n")
        f.write("## Parameter Influence Analysis\n\n")

        if "warning" in analysis:
            f.write(f"*{analysis['warning']}*\n\n")
        else:
            f.write("### Learning Rate Influence\n\n")
            f.write("| LR | Mean Val Loss | Std | Min | Count |\n")
            f.write("|----|--------------|-----|-----|-------|\n")
            for lr, stats in sorted(analysis.get("learning_rate_analysis", {}).items()):
                f.write(
                    f"| {lr} | {stats['mean_val_loss']:.4e} | "
                    f"{stats['std_val_loss']:.4e} | "
                    f"{stats['min_val_loss']:.4e} | {stats['count']} |\n"
                )

            f.write("\n### Hidden Width Influence\n\n")
            f.write("| Width | Mean Val Loss | Std | Min | Count |\n")
            f.write("|-------|--------------|-----|-----|-------|\n")
            for w, stats in sorted(analysis.get("width_analysis", {}).items()):
                f.write(
                    f"| {w} | {stats['mean_val_loss']:.4e} | "
                    f"{stats['std_val_loss']:.4e} | "
                    f"{stats['min_val_loss']:.4e} | {stats['count']} |\n"
                )

            f.write("\n### Activation Function Influence\n\n")
            f.write("| Activation | Mean Val Loss | Std | Min | Count |\n")
            f.write("|------------|--------------|-----|-----|-------|\n")
            for a, stats in sorted(analysis.get("activation_analysis", {}).items()):
                f.write(
                    f"| {a} | {stats['mean_val_loss']:.4e} | "
                    f"{stats['std_val_loss']:.4e} | "
                    f"{stats['min_val_loss']:.4e} | {stats['count']} |\n"
                )

            f.write("\n### Recommended Parameter Combination\n\n")
            best = analysis.get("best_by_parameter", {})
            f.write("- **Best learning rate:** " + str(best.get("learning_rate", "N/A")) + "\n")
            f.write("- **Best hidden width:** " + str(best.get("hidden_width", "N/A")) + "\n")
            f.write("- **Best activation:** " + str(best.get("activation", "N/A")) + "\n")

        f.write("\n---\n")
        f.write("*Automatically generated by PINN hyperparameter search loop*\n")

    print(f"[AGG] Ranking written to: {path}")


def main():
    # Determine experiment directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    experiment_dir = os.path.dirname(script_dir)

    outputs_dir = os.path.join(experiment_dir, "outputs")

    # Collect and analyze
    results = collect_results(experiment_dir)

    if not results:
        print("[AGG] No results found in outputs/")
        sys.exit(1)

    print(f"[AGG] Found {len(results)} config results")

    # Write CSV
    csv_path = os.path.join(outputs_dir, "sweep_results.csv")
    write_csv(results, csv_path)

    # Parameter influence analysis
    analysis = analyze_parameter_influence(results)

    # Write ranking markdown
    ranking_path = os.path.join(outputs_dir, "sweep_ranking.md")
    write_ranking_md(results, analysis, ranking_path)

    # Print summary
    done_count = sum(1 for r in results if r["status"] == "DONE")
    failed_count = sum(1 for r in results if r["status"] != "DONE")
    print(f"[AGG] Summary: {done_count} DONE, {failed_count} FAILED, "
          f"{len(results)} total")
    print(f"[AGG] Results CSV: {csv_path}")
    print(f"[AGG] Ranking report: {ranking_path}")


if __name__ == "__main__":
    main()
