#!/usr/bin/env python3
"""
PINN training script — primary entry point for hyperparameter search.

Trains a Physics-Informed Neural Network on the 1D Burgers equation
using PyTorch autograd (primary) or NumPy (fallback).

Usage:
    # Quick test (100 steps):
    python pinn/train.py --lr 1e-3 --width 32 --activation tanh \\
        --steps 100 --output-dir outputs/test

    # Full 50k step training:
    python pinn/train.py --lr 1e-3 --width 64 --activation tanh \\
        --steps 50000 --output-dir outputs/pinn_lr1e-3_w64_act_tanh

    # With GPU:
    python pinn/train.py --lr 1e-3 --width 64 --activation tanh \\
        --steps 50000 --output-dir outputs/run --device cuda

Exit code:
    0 = DONE
    1 = FAILED (NaN or other error)
"""

import argparse
import json
import os
import sys
import time
import numpy as np

# Ensure pinn package is importable
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pinn.model import create_model, HAS_TORCH
from pinn.utils import (
    generate_collocation_points,
    to_torch,
    compute_loss_torch,
    compute_loss_numpy,
    LossLogger,
    check_nan_in_losses,
)


def train_torch(config, output_dir, device="cpu"):
    """Train PINN using PyTorch with autograd.

    Args:
        config: dict with learning_rate, hidden_width, activation, steps, etc.
        output_dir: path to save outputs
        device: 'cpu' or 'cuda'

    Returns:
        dict with training results
    """
    import torch
    import torch.optim as optim

    os.makedirs(output_dir, exist_ok=True)

    # Extract hyperparameters
    lr = float(config["learning_rate"])
    width = int(config["hidden_width"])
    activation = config["activation"]
    num_hidden = int(config.get("num_hidden", 4))
    seed = int(config.get("seed", 42))
    n_steps = int(config.get("steps", 50000))
    log_every = int(config.get("log_every", 100))
    val_every = int(config.get("validation_every", 500))
    patience = config.get("early_stop_patience", None)
    nu = float(config.get("pde", {}).get("nu", 0.01))

    # Save config
    with open(os.path.join(output_dir, "config.json"), "w") as f:
        json.dump(config, f, indent=2)

    # Set seed
    torch.manual_seed(seed)
    np.random.seed(seed)

    # Create model
    model = create_model(
        hidden_width=width, num_hidden=num_hidden,
        activation=activation, backend="torch",
    ).to(device)

    print(f"[PINN] Torch model: {sum(p.numel() for p in model.parameters())} params")
    print(f"[PINN] Device: {device}")
    print(f"[PINN] lr={lr}, width={width}, activation={activation}, steps={n_steps}")

    # Generate data
    points_np = generate_collocation_points(seed=seed)
    points = to_torch(points_np, device=device)

    print(f"[PINN] Data: {points_np['collocation'][0].shape[0]} collocation, "
          f"{points_np['validation'][0].shape[0]} validation pts")

    # Optimizer
    optimizer = optim.Adam(model.parameters(), lr=lr)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=n_steps)

    # Logger
    logger = LossLogger(output_dir)
    start_time = time.time()

    # Training loop
    best_val_loss = float("inf")
    nan_streak = 0
    MAX_NAN_STREAK = 10
    steps_since_improvement = 0

    for step in range(1, n_steps + 1):
        model.train()
        optimizer.zero_grad()

        # Compute loss (autograd handles gradients)
        losses = compute_loss_torch(model, points, nu=nu, device=device)
        loss_total = losses["total"]

        # NaN check
        has_nan, nan_key = check_nan_in_losses(losses)
        if has_nan:
            nan_streak += 1
            print(f"[PINN] WARNING: NaN in {nan_key} at step {step} "
                  f"(streak={nan_streak})")
            if nan_streak >= MAX_NAN_STREAK:
                print(f"[PINN] FATAL: {MAX_NAN_STREAK} consecutive NaN. Aborting.")
                logger.log(step, {k: float("nan") for k in losses}, time.time() - start_time)
                logger.save_metrics(
                    {"total": float("nan"), "val": float("nan")},
                    time.time() - start_time, config, status="FAILED_NAN",
                    steps_completed=step,
                )
                return {
                    "status": "FAILED_NAN", "config": config,
                    "error": f"{MAX_NAN_STREAK} consecutive NaN",
                    "steps_completed": step,
                    "wall_time_sec": time.time() - start_time,
                }
            # Skip this step's update but keep going
            continue
        else:
            nan_streak = 0

        # Backward + optimize
        loss_total.backward()

        # Gradient clipping (prevents explosion)
        torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=10.0)

        optimizer.step()
        scheduler.step()

        # Track best val loss
        current_val = losses["val"].item()
        if current_val < best_val_loss:
            best_val_loss = current_val
            steps_since_improvement = 0
        else:
            steps_since_improvement += 1

        # Early stopping
        if patience and steps_since_improvement > patience:
            if step > 1000:  # Don't stop too early
                print(f"[PINN] Early stopping at step {step} (no improvement "
                      f"for {patience} steps)")
                break

        # Logging
        if step % log_every == 0 or step == 1 or step == n_steps:
            elapsed = time.time() - start_time
            current_lr = scheduler.get_last_lr()[0]
            logger.log(step, losses, elapsed)
            print(f"[PINN] Step {step:6d}/{n_steps} | "
                  f"loss={loss_total.item():.6e} | "
                  f"val={current_val:.6e} | "
                  f"lr={current_lr:.2e} | "
                  f"time={elapsed:.1f}s")

    # Training complete
    total_time = time.time() - start_time
    model.eval()

    # Final loss evaluation (PDE residual needs autograd, even at eval)
    final_losses = compute_loss_torch(model, points, nu=nu, device=device)

    logger.log(n_steps, final_losses, total_time)
    metrics = logger.save_metrics(final_losses, total_time, config, status="DONE",
                                  steps_completed=step)

    # Save model weights (convert to numpy for portability)
    model_path = os.path.join(output_dir, "model_state.npz")
    state_dict = {k: v.cpu().numpy() for k, v in model.state_dict().items()}
    np.savez_compressed(model_path, **state_dict)

    print(f"\n[PINN] Training complete! Time: {total_time:.1f}s")
    print(f"[PINN] Final val loss: {final_losses['val'].item():.6e}")
    print(f"[PINN] Best val loss: {best_val_loss:.6e}")
    print(f"[PINN] Outputs saved to: {output_dir}")

    return {
        "status": "DONE",
        "config": config,
        "final_losses": {k: v.item() for k, v in final_losses.items()},
        "best_val_loss": float(best_val_loss),
        "steps_completed": step,
        "wall_time_sec": total_time,
    }


def train_numpy(config, output_dir):
    """Train PINN using NumPy (slow, finite-difference gradients).

    This is a fallback for when PyTorch is not available.
    For production use, prefer PyTorch/TF/JAX.
    """
    from pinn.model import PINNumPy

    os.makedirs(output_dir, exist_ok=True)

    lr = float(config["learning_rate"])
    width = int(config["hidden_width"])
    activation = config["activation"]
    num_hidden = int(config.get("num_hidden", 4))
    n_steps = int(config.get("steps", 50000))
    log_every = int(config.get("log_every", 100)) or max(1, n_steps // 20)
    seed = int(config.get("seed", 42))

    with open(os.path.join(output_dir, "config.json"), "w") as f:
        json.dump(config, f, indent=2)

    print(f"[PINN] NumPy model: {width}x{num_hidden} MLP")
    print(f"[PINN] NOTE: NumPy training uses finite-difference gradients.")
    print(f"[PINN] This is ~1000x slower than PyTorch autograd.")
    print(f"[PINN] For production: pip install torch")

    model = PINNumPy(hidden_width=width, num_hidden=num_hidden, activation=activation, seed=seed)
    points = generate_collocation_points(seed=seed)
    print(f"[PINN] Params: {model.param_count()}")

    logger = LossLogger(output_dir)
    start_time = time.time()

    # Simple SGD with momentum
    params = model.get_params()
    velocities = [np.zeros_like(p) for p in params]
    momentum = 0.9

    def get_lr(step):
        lr_scheduled = lr * 0.5 * (1.0 + np.cos(np.pi * step / n_steps))
        return lr_scheduled

    nan_streak = 0
    MAX_NAN_STREAK = 10

    for step in range(1, n_steps + 1):
        current_lr = get_lr(step)

        # Compute loss
        losses = compute_loss_numpy(model, points)
        has_nan, nan_key = check_nan_in_losses(losses)

        if has_nan:
            nan_streak += 1
            print(f"[PINN] WARNING: NaN in {nan_key} at step {step} (streak={nan_streak})")
            if nan_streak >= MAX_NAN_STREAK:
                print(f"[PINN] FATAL: {MAX_NAN_STREAK} consecutive NaN.")
                logger.save_metrics(
                    {"total": float("nan"), "val": float("nan")},
                    time.time() - start_time, config, status="FAILED_NAN",
                )
                return {
                    "status": "FAILED_NAN", "config": config,
                    "error": "consecutive NaN",
                    "steps_completed": step,
                    "wall_time_sec": time.time() - start_time,
                }
            continue
        else:
            nan_streak = 0

        # Simplified gradient estimation (coarse, for demonstration only)
        eps = 1e-4
        for i in range(len(params)):
            flat = params[i].ravel()
            grad_flat = np.zeros_like(flat)
            # Sample-based estimation (not exact, but faster than full perturbation)
            n_samples = min(20, flat.size)
            idxs = np.random.choice(flat.size, n_samples, replace=False)
            for idx in idxs:
                orig = flat[idx].copy()
                flat[idx] = orig + eps
                params[i] = flat.reshape(params[i].shape)
                model.set_params(params)
                loss_p = compute_loss_numpy(model, points)["total"]
                flat[idx] = orig - eps
                params[i] = flat.reshape(params[i].shape)
                model.set_params(params)
                loss_m = compute_loss_numpy(model, points)["total"]
                grad_flat[idx] = (loss_p - loss_m) / (2 * eps)
                flat[idx] = orig
            params[i] = flat.reshape(params[i].shape)
            model.set_params(params)
            grad = grad_flat.reshape(params[i].shape)

            velocities[i] = momentum * velocities[i] - current_lr * grad
            params[i] = params[i] + velocities[i]

        model.set_params(params)

        # Logging
        if step % log_every == 0 or step == 1:
            elapsed = time.time() - start_time
            logger.log(step, losses, elapsed)
            print(f"[PINN] Step {step:6d}/{n_steps} | "
                  f"loss={losses['total']:.6e} | "
                  f"val={losses['val']:.6e} | "
                  f"time={elapsed:.1f}s")

    total_time = time.time() - start_time
    final_losses = compute_loss_numpy(model, points)
    logger.log(n_steps, final_losses, total_time)
    logger.save_metrics(final_losses, total_time, config, status="DONE",
                        steps_completed=n_steps)

    model.save(os.path.join(output_dir, "model_state.npz"))

    print(f"\n[PINN] Training complete! Time: {total_time:.1f}s")
    print(f"[PINN] Final val loss: {final_losses.get('val', 'N/A'):.6e}")

    return {
        "status": "DONE",
        "config": config,
        "final_losses": final_losses,
        "steps_completed": n_steps,
        "wall_time_sec": total_time,
    }


def main():
    parser = argparse.ArgumentParser(description="Train a PINN for Burgers equation")
    parser.add_argument("--lr", type=float, default=1e-3, help="Learning rate")
    parser.add_argument("--width", type=int, default=64, help="Hidden layer width")
    parser.add_argument("--activation", type=str, default="tanh",
                        choices=["tanh", "silu"], help="Activation function")
    parser.add_argument("--num-hidden", type=int, default=4,
                        help="Number of hidden layers")
    parser.add_argument("--steps", type=int, default=50000,
                        help="Number of training steps")
    parser.add_argument("--seed", type=int, default=42, help="Random seed")
    parser.add_argument("--output-dir", type=str, required=True,
                        help="Output directory")
    parser.add_argument("--device", type=str, default="auto",
                        choices=["auto", "cpu", "cuda"],
                        help="Device (auto = cuda if available)")
    parser.add_argument("--backend", type=str, default="auto",
                        choices=["auto", "torch", "numpy"],
                        help="Training backend")

    args = parser.parse_args()

    # Resolve device
    if args.device == "auto":
        if HAS_TORCH:
            import torch
            device = "cuda" if torch.cuda.is_available() else "cpu"
        else:
            device = "cpu"
    else:
        device = args.device

    # Resolve backend
    backend = args.backend
    if backend == "auto":
        backend = "torch" if HAS_TORCH else "numpy"

    config = {
        "learning_rate": args.lr,
        "hidden_width": args.width,
        "activation": args.activation,
        "num_hidden": args.num_hidden,
        "steps": args.steps,
        "seed": args.seed,
        "log_every": 100,
        "validation_every": 500,
    }

    print(f"[PINN] Backend: {backend.upper()}, Device: {device}")
    print(f"[PINN] Config: lr={args.lr}, width={args.width}, "
          f"act={args.activation}, steps={args.steps}")

    if backend == "torch" and not HAS_TORCH:
        print("[ERROR] PyTorch backend selected but torch is not installed.")
        print("  Install: pip install torch")
        print("  Or use --backend numpy for slow but dependency-free training")
        sys.exit(1)

    if backend == "torch":
        result = train_torch(config, args.output_dir, device=device)
    else:
        result = train_numpy(config, args.output_dir)

    print(f"\nResult: {result['status']}")
    sys.exit(0 if result["status"] == "DONE" else 1)


if __name__ == "__main__":
    main()
