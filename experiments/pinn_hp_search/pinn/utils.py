"""
PINN utilities: data generation, loss computation, CSV logging.

Works with both PyTorch (primary) and NumPy (fallback) models.
"""

import csv
import json
import os
import time
import numpy as np

try:
    import torch
    import torch.nn.functional as F

    HAS_TORCH = True
except ImportError:
    HAS_TORCH = False


# ============================================================================
# Exact solution for 1D Burgers equation
# ============================================================================

def burgers_exact(x, t, nu=0.01):
    """Approximate reference solution for 1D Burgers equation."""
    return -np.tanh(x / (2 * nu * (t + 0.5)))


# ============================================================================
# Data generation
# ============================================================================

def generate_collocation_points(n_coll=10000, n_boundary=200, n_initial=200,
                                 x_range=(-1, 1), t_range=(0, 1), seed=42):
    """Generate collocation, boundary, initial condition, and validation points.

    Returns dict of numpy arrays. Convert to torch tensors inside train loop.
    """
    rng = np.random.RandomState(seed)

    # Interior collocation points
    x_coll = rng.uniform(x_range[0], x_range[1], (n_coll, 1)).astype(np.float32)
    t_coll = rng.uniform(t_range[0], t_range[1], (n_coll, 1)).astype(np.float32)

    # Boundary points (x = -1 and x = 1, u = 0 for Burgers)
    x_b_left = np.full((n_boundary // 2, 1), x_range[0], dtype=np.float32)
    t_b_left = rng.uniform(t_range[0], t_range[1], (n_boundary // 2, 1)).astype(np.float32)
    x_b_right = np.full((n_boundary // 2, 1), x_range[1], dtype=np.float32)
    t_b_right = rng.uniform(t_range[0], t_range[1], (n_boundary // 2, 1)).astype(np.float32)
    x_boundary = np.vstack([x_b_left, x_b_right])
    t_boundary = np.vstack([t_b_left, t_b_right])

    # Initial condition points (t = 0)
    x_initial = rng.uniform(x_range[0], x_range[1], (n_initial, 1)).astype(np.float32)
    t_initial = np.zeros((n_initial, 1), dtype=np.float32)

    # Validation points (uniform grid at final time)
    n_val = 200
    x_val = np.linspace(x_range[0], x_range[1], n_val).reshape(-1, 1).astype(np.float32)
    t_val = np.full((n_val, 1), t_range[1], dtype=np.float32)
    u_val = burgers_exact(x_val, t_val).astype(np.float32)

    return {
        "collocation": (x_coll, t_coll),
        "boundary": (x_boundary, t_boundary),
        "initial": (x_initial, t_initial),
        "validation": (x_val, t_val, u_val),
    }


def to_torch(points, device="cpu"):
    """Convert numpy points dict to torch tensors."""
    torch_points = {}
    for key, val in points.items():
        if key == "validation":
            x, t, u = val
            torch_points[key] = (
                torch.tensor(x, device=device),
                torch.tensor(t, device=device),
                torch.tensor(u, device=device),
            )
        else:
            x, t = val
            torch_points[key] = (
                torch.tensor(x, device=device),
                torch.tensor(t, device=device),
            )
    return torch_points


# ============================================================================
# Loss computation (PyTorch)
# ============================================================================

def compute_loss_torch(model, points, nu=0.01, device="cpu"):
    """Compute composite PINN loss using PyTorch autograd.

    Loss = w_pde * loss_pde + w_bc * loss_bc + w_ic * loss_ic

    Returns dict with individual loss components.
    """
    x_coll, t_coll = points["collocation"]
    x_bnd, t_bnd = points["boundary"]
    x_init, t_init = points["initial"]
    x_val, t_val, u_val = points["validation"]

    # Move to device
    x_coll = x_coll.to(device)
    t_coll = t_coll.to(device)
    x_bnd = x_bnd.to(device)
    t_bnd = t_bnd.to(device)
    x_init = x_init.to(device)
    t_init = t_init.to(device)
    x_val = x_val.to(device)
    t_val = t_val.to(device)
    u_val = u_val.to(device)

    # PDE residual loss (uses autograd, requires gradients)
    residual = model.compute_pde_residual(x_coll, t_coll, nu=nu)
    loss_pde = torch.mean(residual ** 2)

    # Boundary condition loss: u = 0 at x = -1, 1
    u_bnd = model.forward(x_bnd, t_bnd)
    loss_bc = torch.mean(u_bnd ** 2)

    # Initial condition loss: u(x, 0) = -tanh(x / (2*nu*0.5))
    u_init_pred = model.forward(x_init, t_init)
    u_init_exact = -torch.tanh(x_init / (2 * nu * 0.5))
    loss_ic = torch.mean((u_init_pred - u_init_exact) ** 2)

    # Validation loss (no grad needed)
    with torch.no_grad():
        u_val_pred = model.forward(x_val, t_val)
        loss_val = torch.mean((u_val_pred - u_val) ** 2)

    # Total loss
    loss_total = loss_pde + 10.0 * loss_bc + 10.0 * loss_ic

    return {
        "total": loss_total,
        "pde": loss_pde,
        "bc": loss_bc,
        "ic": loss_ic,
        "val": loss_val,
    }


# ============================================================================
# Loss computation (NumPy fallback)
# ============================================================================

def compute_loss_numpy(model, points, nu=0.01):
    """Compute composite PINN loss using NumPy (finite-difference PDE residual).

    For use when PyTorch is not available. The PDE residual uses
    finite differences and is less accurate than autograd.
    """
    from pinn.model import PINNumPy

    x_coll, t_coll = points["collocation"]
    x_bnd, t_bnd = points["boundary"]
    x_init, t_init = points["initial"]
    x_val, t_val, u_val = points["validation"]

    eps = 1e-6

    # PDE residual via finite differences
    try:
        u = model.forward(x_coll, t_coll)
        # du/dt
        u_t_plus = model.forward(x_coll, t_coll + eps)
        du_dt = (u_t_plus - u) / eps
        # du/dx
        u_x_plus = model.forward(x_coll + eps, t_coll)
        u_x_minus = model.forward(x_coll - eps, t_coll)
        du_dx = (u_x_plus - u_x_minus) / (2 * eps)
        # d2u/dx2
        d2u_dx2 = (u_x_plus - 2 * u + u_x_minus) / (eps ** 2)
        residual = du_dt + u * du_dx - nu * d2u_dx2
        loss_pde = float(np.mean(residual ** 2))
    except Exception:
        loss_pde = float("inf")

    # Boundary loss
    try:
        u_bnd = model.forward(x_bnd, t_bnd)
        loss_bc = float(np.mean(u_bnd ** 2))
    except Exception:
        loss_bc = float("inf")

    # Initial condition loss
    try:
        u_init_pred = model.forward(x_init, t_init)
        u_init_exact = -np.tanh(x_init / (2 * nu * 0.5))
        loss_ic = float(np.mean((u_init_pred - u_init_exact) ** 2))
    except Exception:
        loss_ic = float("inf")

    # Validation loss
    try:
        u_val_pred = model.forward(x_val, t_val)
        loss_val = float(np.mean((u_val_pred - u_val) ** 2))
    except Exception:
        loss_val = float("inf")

    loss_total = loss_pde + 10.0 * loss_bc + 10.0 * loss_ic

    return {
        "total": loss_total,
        "pde": loss_pde,
        "bc": loss_bc,
        "ic": loss_ic,
        "val": loss_val,
    }


# ============================================================================
# CSV Logging
# ============================================================================

class LossLogger:
    """Logs loss values to CSV during training."""

    def __init__(self, output_dir):
        self.output_dir = output_dir
        self.csv_path = os.path.join(output_dir, "loss_curve.csv")
        self.rows = []
        os.makedirs(output_dir, exist_ok=True)

        with open(self.csv_path, "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow([
                "step", "loss_total", "loss_pde", "loss_bc",
                "loss_ic", "loss_val", "wall_time_sec",
            ])

    def log(self, step, losses, wall_time):
        """Log a single step's losses."""
        def to_float(v):
            if isinstance(v, (torch.Tensor,)):
                return v.item()
            return float(v)

        row = [
            step,
            f"{to_float(losses['total']):.6e}",
            f"{to_float(losses['pde']):.6e}",
            f"{to_float(losses['bc']):.6e}",
            f"{to_float(losses['ic']):.6e}",
            f"{to_float(losses['val']):.6e}",
            f"{wall_time:.2f}",
        ]
        self.rows.append(row)

        with open(self.csv_path, "a", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(row)

    def save_metrics(self, final_losses, wall_time, config, status="DONE",
                     steps_completed=None):
        """Save final metrics to JSON.

        Args:
            steps_completed: actual step count. If None, uses len(self.rows).
        """
        def to_float(v):
            if isinstance(v, (torch.Tensor,)):
                return v.item()
            return float(v)

        if steps_completed is None:
            steps_completed = len(self.rows) if self.rows else 0

        metrics = {
            "status": status,
            "config": config,
            "final_losses": {k: to_float(v) for k, v in final_losses.items()},
            "wall_time_sec": wall_time,
            "steps_completed": steps_completed,
            "activation": config.get("activation", "unknown"),
            "hidden_width": config.get("hidden_width", -1),
            "learning_rate": config.get("learning_rate", -1),
        }
        metrics_path = os.path.join(self.output_dir, "metrics.json")
        with open(metrics_path, "w") as f:
            json.dump(metrics, f, indent=2)
        return metrics


# ============================================================================
# NaN detection utilities
# ============================================================================

def check_nan_in_losses(loss_dict):
    """Check if any loss value is NaN or Inf."""
    for key, val in loss_dict.items():
        if val is None:
            return True, key
        if isinstance(val, (torch.Tensor,)):
            if torch.isnan(val).any() or torch.isinf(val).any():
                return True, key
        else:
            try:
                v = float(val)
                if np.isnan(v) or np.isinf(v):
                    return True, key
            except (ValueError, TypeError):
                return True, key
    return False, None


def has_torch():
    return HAS_TORCH
