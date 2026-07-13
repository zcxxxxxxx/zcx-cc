# JCP Experiment Section 详细模式

## 实验设计的核心原则

1. **可复现性** — 所有实验配置可复现。包括种子、数据生成过程、训练协议。
2. **公平比较** — 基线和你的方法必须在同一条件下运行。
3. **递增难度** — 从简单到复杂，让审稿人逐步信服。
4. **完整性** — 消融实验隔离每个组件的贡献。

## Benchmark 选择指南

### 标准 JCP PINN Benchmark 类型

| 类型 | 难度 | 验证目标 | 使用比率 |
|------|------|----------|----------|
| Burgers 方程 | 低 | 基础方法验证 | 8/16 |
| Poisson 方程 | 低 | 椭圆型求解 | 7/16 |
| Helmholtz 方程 | 中 | 高频/振荡 | 6/16 |
| Allen-Cahn 方程 | 中 | 相场/尖界面 | 5/16 |
| Navier-Stokes | 高 | 流体/工程 | 5/16 |
| Darcy 方程 | 中 | 多孔介质/变参数 | 3/16 |

**推荐选择**：选 3-4 个 benchmark，覆盖至少 2 个难度等级。

### 对比基线选择

| 层次 | 基线 | 目的 |
|------|------|------|
| **L0** | 标准 PINN (Raissi 2019) | 最低基线，必须超过 |
| **L1** | 你的方法去掉组件的消融变体 | 证明每个组件的必要性 |
| **L2** | 1-3 个 SOTA 方法 | 证明相对于最新工作的优势 |
| **L3** | 传统数值方法（可选） | 证明相对于成熟方法的实用性 |

## 每个 Benchmark 的段落模板

### 标准 6 句式模板

```text
[1. PDE statement] "To evaluate [capability], we consider the [PDE type] equation: [equation]"
[2. Domain & setup] "The computational domain is [domain], with [BC/IC conditions]"
[3. Data] "Training data consists of [N_f/N_b] collocation/boundary points"
[4. Baseline results] "For comparison, [baseline] achieves [metric value]"
[5. Our result] "[Method] achieves [metric value], reducing error by [factor]"
[6. Interpretation] "This improvement can be attributed to [your mechanism]"
```

### 可视化描述模板

```text
"Fig. [N] presents the predicted [quantity] and point-wise error distribution.
[Method] accurately captures [feature], while [baseline] fails to resolve [specific difficulty].
The maximum point-wise error of [method] is [value], compared to [baseline's value]."
```

## 实验 section 常见错误

### 1. 缺乏消融研究

9/16 论文有消融研究。这是区分一般论文和好论文的关键指标。

**必须做的消融**：
- 每个核心组件移除 → 精度变化

**推荐做的消融**：
- 超参数灵敏度
- 网络宽度/深度
- 随机种子稳健性

### 2. 不公平的基线对比

**禁止的做法**：
- 基线和你的方法使用不同的训练时长/epoch
- 基线没有调优超参数
- 选择弱基线来衬托自己

**推荐的公平对比声明**：
```text
"For fair comparison, all methods are trained using the same optimizer and learning rate schedule. The hyperparameters of each baseline are tuned according to their original papers or using grid search where applicable."
```

### 3. 仅报告最优结果

**禁止**：只报告 3 次运行中最好的一次

**推荐**：报告 `mean ± std` （6/16 论文做，但这是好实践）

```text
"Results are reported as mean ± std over 5 independent runs with different random seeds."
```

### 4. 不报告计算成本

**推荐**（8/16 论文包含）：
- 参数数量比较
- 训练时间（GPU 型号 + 小时数）
- 推理时间（可选）

```text
"Table [N] reports the computational cost. [Method] requires [X] parameters and [Y] hours of training on a single [GPU model], compared to [baseline parameters/hours] for baseline."
```

## 常见图类型

| 图类型 | 位置 | 说明 |
|--------|------|------|
| 架构图 | §2 或 §3 开头 | 方法框架 |
| 解场预测 | 各 benchmark | 预测 vs 真值 |
| 误差分布 | 各 benchmark | 点态误差 |
| 收敛曲线 | 各 benchmark | Loss/error vs iterations |
| 消融对比 | 专门子节 | 柱状图或表 |
| 灵敏度分析 | 消融后 | 参数变化的影响 |

## 常见表类型

| 表类型 | 栏目 | 说明 |
|--------|------|------|
| Main results | Benchmark × Method | 相对 L2 误差 |
| 消融 | Component × Config | 各组件的贡献 |
| 超参数 | Parameter × Value | 所有配置参数 |
| 计算成本 | Method × (Params / Time) | 效率对比 |

## LaTeX 实用代码片段

### 相对 L2 误差定义

```latex
\begin{equation}
\text{Rel. }\ell_2 = \frac{\|u_{\theta} - u_{\text{ref}}\|_2}{\|u_{\text{ref}}\|_2},
\label{eq:rel_l2}
\end{equation}
```

### 带误差条的表格（mean ± std）

```latex
\begin{tabular}{lccc}
\toprule
Method & Burgers & Helmholtz & Navier-Stokes \\
\midrule
PINN       & $1.23\times10^{-2}$ & $4.56\times10^{-2}$ & $7.89\times10^{-2}$ \\
Baseline A & $8.10\times10^{-3}$ & $3.21\times10^{-2}$ & $5.43\times10^{-2}$ \\
Ours       & $\mathbf{4.32\times10^{-3}_{\pm 2.1e-4}}$ & $\mathbf{1.09\times10^{-2}_{\pm 1.5e-3}}$ & $\mathbf{2.76\times10^{-2}_{\pm 3.2e-3}}$ \\
\bottomrule
\end{tabular}
```
