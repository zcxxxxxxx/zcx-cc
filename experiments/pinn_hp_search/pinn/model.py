"""
PINN model definitions — PyTorch implementation with NumPy fallback for inspection.

Primary implementation uses PyTorch for automatic differentiation.
NumPy implementation is provided for lightweight inspection/verification.

Architecture: 2-input (x, t) -> [hidden layers] -> 1-output (u)
Supports configurable width, depth, and activation functions.
"""

import numpy as np

try:
    import torch
    import torch.nn as nn

    HAS_TORCH = True
except ImportError:
    HAS_TORCH = False


# ============================================================================
# PyTorch Implementation (Primary — for training)
# ============================================================================

if HAS_TORCH:

    class PINNModule(nn.Module):
        """PyTorch PINN with configurable architecture.

        2 inputs (x, t) -> [hidden_layers] -> 1 output (u).
        Uses automatic differentiation for PDE residual computation.
        """

        def __init__(self, input_dim=2, hidden_width=64, num_hidden=4,
                     output_dim=1, activation="tanh"):
            super().__init__()
            self.input_dim = input_dim
            self.hidden_width = hidden_width
            self.num_hidden = num_hidden
            self.output_dim = output_dim
            self.activation_name = activation

            # Select activation
            if activation == "tanh":
                self.act = nn.Tanh()
            elif activation == "silu":
                self.act = nn.SiLU()
            else:
                raise ValueError(f"Unknown activation: {activation}")

            # Build layers
            layers = []
            layers.append(nn.Linear(input_dim, hidden_width))
            for _ in range(num_hidden - 1):
                layers.append(nn.Linear(hidden_width, hidden_width))
            layers.append(nn.Linear(hidden_width, output_dim))
            self.layers = nn.ModuleList(layers)

            # Initialize weights (Xavier)
            for layer in self.layers:
                if hasattr(layer, "weight") and layer.weight is not None:
                    nn.init.xavier_normal_(layer.weight, gain=0.5)
                if hasattr(layer, "bias") and layer.bias is not None:
                    nn.init.zeros_(layer.bias)

        def forward(self, x, t):
            """Forward pass. x, t: (batch, 1). Returns u: (batch, 1)."""
            h = torch.cat([x, t], dim=1)
            for i in range(len(self.layers) - 1):
                h = self.layers[i](h)
                h = self.act(h)
            h = self.layers[-1](h)  # Linear output
            return h

        def compute_pde_residual(self, x, t, nu=0.01):
            """Compute Burgers PDE residual using autograd.

            du/dt + u * du/dx - nu * d2u/dx2 = 0
            """
            x.requires_grad_(True)
            t.requires_grad_(True)

            u = self.forward(x, t)

            # du/dt
            du_dt = torch.autograd.grad(
                u, t, grad_outputs=torch.ones_like(u),
                create_graph=True, retain_graph=True
            )[0]

            # du/dx
            du_dx = torch.autograd.grad(
                u, x, grad_outputs=torch.ones_like(u),
                create_graph=True, retain_graph=True
            )[0]

            # d2u/dx2
            d2u_dx2 = torch.autograd.grad(
                du_dx, x, grad_outputs=torch.ones_like(du_dx),
                create_graph=True, retain_graph=True
            )[0]

            # Burgers residual
            residual = du_dt + u * du_dx - nu * d2u_dx2
            return residual

        def param_count(self):
            return sum(p.numel() for p in self.parameters())


# ============================================================================
# NumPy Implementation (for lightweight verification / inspection)
# ============================================================================

def get_activation(name: str):
    """Get activation function by name. Returns (fn, fn_derivative)."""
    if name == "tanh":

        def act(x):
            return np.tanh(x)

        return act

    elif name == "silu":

        def act(x):
            sig = 1.0 / (1.0 + np.exp(-np.clip(x, -50, 50)))
            return x * sig

        return act

    else:
        raise ValueError(f"Unknown activation: {name}")


class PINNumPy:
    """NumPy MLP for PINN — used for verification and lightweight tasks.

    2 inputs (x, t) -> [hidden_layers] -> 1 output (u).
    """

    def __init__(self, input_dim=2, hidden_width=64, num_hidden=4,
                 output_dim=1, activation="tanh", seed=42):
        self.input_dim = input_dim
        self.hidden_width = hidden_width
        self.num_hidden = num_hidden
        self.output_dim = output_dim
        self.activation_name = activation
        self.act_fn = get_activation(activation)

        self.rng = np.random.RandomState(seed)

        # Build layers: [input->hidden, hidden->hidden...xN, hidden->output]
        self.weights = []
        self.biases = []

        # Input -> first hidden
        self.weights.append(
            self.rng.randn(input_dim, hidden_width) * np.sqrt(2.0 / input_dim)
        )
        self.biases.append(np.zeros((1, hidden_width)))

        # Hidden -> hidden
        for _ in range(num_hidden - 1):
            self.weights.append(
                self.rng.randn(hidden_width, hidden_width) * np.sqrt(2.0 / hidden_width)
            )
            self.biases.append(np.zeros((1, hidden_width)))

        # Last hidden -> output
        self.weights.append(
            self.rng.randn(hidden_width, output_dim) * np.sqrt(2.0 / hidden_width)
        )
        self.biases.append(np.zeros((1, output_dim)))

    def forward(self, x, t):
        """Forward pass. x, t: (N,) or (N,1). Returns u: (N,1)."""
        x = np.asarray(x, dtype=np.float64).reshape(-1, 1)
        t = np.asarray(t, dtype=np.float64).reshape(-1, 1)
        h = np.concatenate([x, t], axis=1)

        for i in range(len(self.weights) - 1):
            h = np.dot(h, self.weights[i]) + self.biases[i]
            h = self.act_fn(h)

        h = np.dot(h, self.weights[-1]) + self.biases[-1]
        return h

    def param_count(self):
        return sum(w.size for w in self.weights) + sum(b.size for b in self.biases)

    def save(self, path):
        state = {}
        for i, (w, b) in enumerate(zip(self.weights, self.biases)):
            state[f"w{i}"] = w
            state[f"b{i}"] = b
        state["activation"] = self.activation_name
        state["hidden_width"] = self.hidden_width
        state["seed"] = 42
        np.savez_compressed(path, **state)

    @classmethod
    def load(cls, path):
        state = np.load(path, allow_pickle=True)
        hidden_width = int(state["hidden_width"])
        activation = str(state["activation"])
        num_hidden = len([k for k in state.keys() if k.startswith("w")])
        model = cls(hidden_width=hidden_width, num_hidden=num_hidden,
                    activation=activation)
        for i in range(num_hidden):
            model.weights[i] = state[f"w{i}"]
            model.biases[i] = state[f"b{i}"]
        return model


# ============================================================================
# Factory — returns appropriate model based on available backends
# ============================================================================

def create_model(hidden_width=64, num_hidden=4, activation="tanh",
                 backend="auto"):
    """Create a PINN model using the best available backend.

    Args:
        hidden_width: neurons per hidden layer
        num_hidden: number of hidden layers
        activation: 'tanh' or 'silu'
        backend: 'auto' (prefer torch), 'numpy', or 'torch'

    Returns:
        PINNModule (if torch available) or PINNumPy instance
    """
    if backend == "auto" and HAS_TORCH:
        backend = "torch"
    elif backend == "auto":
        backend = "numpy"

    if backend == "torch":
        if not HAS_TORCH:
            raise ImportError("PyTorch not available. Install with: pip install torch")
        return PINNModule(
            input_dim=2, hidden_width=hidden_width,
            num_hidden=num_hidden, output_dim=1, activation=activation,
        )
    else:
        return PINNumPy(
            input_dim=2, hidden_width=hidden_width,
            num_hidden=num_hidden, output_dim=1, activation=activation,
            seed=42,
        )


# ============================================================================
# Quick test
# ============================================================================
if __name__ == "__main__":
    # Test NumPy model
    model_np = PINNumPy(hidden_width=32, activation="tanh")
    print(f"[NumPy] 2 -> 32x4 -> 1: {model_np.param_count()} params")

    x_test = np.linspace(-1, 1, 10).reshape(-1, 1)
    t_test = np.zeros((10, 1))
    u = model_np.forward(x_test, t_test)
    print(f"[NumPy] Output shape: {u.shape}, sample: {u.flatten()[:3]}")

    # Test SiLU
    model_np2 = PINNumPy(hidden_width=32, activation="silu")
    u2 = model_np2.forward(x_test, t_test)
    print(f"[NumPy] SiLU output: {u2.flatten()[:3]}")

    if HAS_TORCH:
        model_th = PINNModule(hidden_width=32, activation="tanh")
        x_th = torch.tensor(x_test, dtype=torch.float32)
        t_th = torch.tensor(t_test, dtype=torch.float32)
        u_th = model_th(x_th, t_th)
        print(f"[Torch] Output shape: {u_th.shape}, sample: {u_th.detach().numpy().flatten()[:3]}")
        print(f"[Torch] Params: {model_th.param_count()}")

    print("All model tests pass.")
