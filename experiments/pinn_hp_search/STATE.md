# Loop State — PINN Hyperparameter Search

**Status:** 0/18 pending — 0 done, 0 failed

**Cycle info:**
- Started: 2026-06-28T00:00:00Z (initial — will update on first run)
- Last run: N/A (initial)
- Iterations: 0
- Wall clock elapsed: 0 minutes

**Progress:**
- [ ] pinn_lr1e-4_w32_act_tanh: pending
- [ ] pinn_lr1e-4_w32_act_silu: pending
- [ ] pinn_lr1e-4_w64_act_tanh: pending
- [ ] pinn_lr1e-4_w64_act_silu: pending
- [ ] pinn_lr1e-4_w128_act_tanh: pending
- [ ] pinn_lr1e-4_w128_act_silu: pending
- [ ] pinn_lr5e-4_w32_act_tanh: pending
- [ ] pinn_lr5e-4_w32_act_silu: pending
- [ ] pinn_lr5e-4_w64_act_tanh: pending
- [ ] pinn_lr5e-4_w64_act_silu: pending
- [ ] pinn_lr5e-4_w128_act_tanh: pending
- [ ] pinn_lr5e-4_w128_act_silu: pending
- [ ] pinn_lr1e-3_w32_act_tanh: pending
- [ ] pinn_lr1e-3_w32_act_silu: pending
- [ ] pinn_lr1e-3_w64_act_tanh: pending
- [ ] pinn_lr1e-3_w64_act_silu: pending
- [ ] pinn_lr1e-3_w128_act_tanh: pending
- [ ] pinn_lr1e-3_w128_act_silu: pending

**Failures (last cycle):**
- N/A — no cycles run yet

**Next step:**
Run config generator and start the sweep:
```
cd F:/Git_repo/zcx-cc/experiments/pinn_hp_search
python configs/generate_configs.py
bash scripts/run_sweep_parent.sh --loop
```

**Limits:**
- Max iterations: 25
- Wall clock limit: 12 hours
- Consecutive NaN limit: 3
- Current iteration: 0
- Current wall elapsed: 0 min

**Escalation level:** Level 0 — nominal
