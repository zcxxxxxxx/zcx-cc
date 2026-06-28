#!/usr/bin/env python3
"""
Generate all PINN hyperparameter combination configs.

Produces 3 × 3 × 2 = 18 config JSON files and a master manifest.
"""

import json
import os
import sys

# Add parent to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


CONFIG_DIR = os.path.dirname(os.path.abspath(__file__))


def generate_sweep():
    """Generate all config combinations and return list of config dicts."""
    # Load sweep config
    sweep_path = os.path.join(os.path.dirname(CONFIG_DIR), "sweep_config.json")
    with open(sweep_path) as f:
        sweep = json.load(f)

    lrs = sweep["hyperparameters"]["learning_rates"]
    widths = sweep["hyperparameters"]["hidden_widths"]
    activations = sweep["hyperparameters"]["activations"]

    configs = []
    for lr in lrs:
        for width in widths:
            for activation in activations:
                config = {
                    "learning_rate": lr,
                    "hidden_width": width,
                    "activation": activation,
                    "num_hidden": 4,
                    "steps": 50000,
                    "seed": 42,
                    "pde": sweep["pde"],
                    "training": {
                        "batch_size": sweep["training"]["batch_size"],
                        "lr_scheduler": sweep["training"]["lr_scheduler"],
                        "log_every": sweep["training"]["log_every"],
                        "validation_every": sweep["training"]["validation_every"],
                        "save_every": sweep["training"]["save_every"],
                        "early_stop_patience": sweep["training"]["early_stop_patience"],
                    },
                }
                configs.append(config)
    return configs


def config_name(cfg):
    """Generate human-readable config name."""
    lr = cfg["learning_rate"]
    width = cfg["hidden_width"]
    act = cfg["activation"]
    # Format lr: 0.0001 -> 1e-4
    lr_str = f"{lr:.0e}".replace("0", "").replace("e-0", "e-")
    return f"pinn_lr{lr_str}_w{width}_act_{act}"


def write_configs(configs):
    """Write individual config JSON files and master manifest."""
    manifest = []

    for cfg in configs:
        name = config_name(cfg)
        cfg_path = os.path.join(CONFIG_DIR, f"{name}.json")
        with open(cfg_path, "w") as f:
            json.dump(cfg, f, indent=2)
        manifest.append({
            "name": name,
            "file": f"{name}.json",
            "learning_rate": cfg["learning_rate"],
            "hidden_width": cfg["hidden_width"],
            "activation": cfg["activation"],
        })

    # Write manifest
    manifest_path = os.path.join(CONFIG_DIR, "manifest.json")
    with open(manifest_path, "w") as f:
        json.dump({
            "total_configs": len(manifest),
            "configs": manifest,
        }, f, indent=2)

    print(f"Generated {len(manifest)} config files in {CONFIG_DIR}")
    return manifest


def main():
    configs = generate_sweep()
    manifest = write_configs(configs)

    print("\nConfig manifest:")
    for entry in manifest:
        print(f"  {entry['name']}: lr={entry['learning_rate']}, "
              f"width={entry['hidden_width']}, act={entry['activation']}")
    print(f"\nTotal: {len(manifest)} configurations")


if __name__ == "__main__":
    main()
