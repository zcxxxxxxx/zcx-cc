# JCP Section Templates

各章节的逐句写作模板和 LaTeX 代码片段。

---

## §2 Methodology 模板

### 2.1 PDE Formulation

```latex
\subsection{Problem formulation}
Consider the following initial-boundary value problem:
\begin{equation}
\begin{aligned}
\mathcal{D}[u](\bm{x},t) &= f(\bm{x},t), \quad (\bm{x},t) \in \Omega \times (0,T], \\
\mathcal{B}[u](\bm{x},t) &= g(\bm{x},t), \quad (\bm{x},t) \in \partial\Omega \times [0,T], \\
\mathcal{I}[u](\bm{x},0) &= h(\bm{x}), \quad \bm{x} \in \Omega,
\end{aligned}
\label{eq:ibvp}
\end{equation}
where $\Omega \subset \mathbb{R}^d$ is an open bounded domain with boundary $\partial\Omega$, $u$ is the unknown solution, $\mathcal{D}$ denotes a differential operator, $f$ is the source term, $\mathcal{B}$ is the boundary operator, and $\mathcal{I}$ is the initial condition operator.
```

### 2.2 PINN Background

```latex
\subsection{Preliminaries of PINNs}
Following the standard PINN approach~\cite{raissi2019}, we approximate the solution $u(\bm{x},t)$ by a neural network $u_{\theta}(\bm{x},t)$ with parameters $\theta$. The network is trained by minimizing a composite loss function:
\begin{equation}
\mathcal{L}(\theta) = \lambda_{\text{pde}} \mathcal{L}_{\text{pde}}(\theta) + \lambda_{\text{ic}} \mathcal{L}_{\text{ic}}(\theta) + \lambda_{\text{bc}} \mathcal{L}_{\text{bc}}(\theta),
\label{eq:loss}
\end{equation}
where the individual loss terms are:
\begin{equation}
\mathcal{L}_{\text{pde}}(\theta) = \frac{1}{N_f}\sum_{i=1}^{N_f} \left| \mathcal{D}[u_{\theta}](\bm{x}_f^i,t_f^i) - f(\bm{x}_f^i,t_f^i) \right|^2,
\label{eq:loss_pde}
\end{equation}
\begin{equation}
\mathcal{L}_{\text{ic}}(\theta) = \frac{1}{N_i}\sum_{i=1}^{N_i} \left| u_{\theta}(\bm{x}_i,0) - h(\bm{x}_i) \right|^2,
\label{eq:loss_ic}
\end{equation}
\begin{equation}
\mathcal{L}_{\text{bc}}(\theta) = \frac{1}{N_b}\sum_{i=1}^{N_b} \left| \mathcal{B}[u_{\theta}](\bm{x}_b^i,t_b^i) - g(\bm{x}_b^i,t_b^i) \right|^2.
\label{eq:loss_bc}
\end{equation}
```

### 2.3 方法描述段落模板

**组件结构**（每引入一个新组件）：

```
Paragraph 1: [Motivation] "A key challenge in [problem] is [specific issue]."
             "To address this, we introduce [component name]."
Paragraph 2: [Technical definition]
             "[Component name] is defined as / operates as follows: [equation/algorithm]"
Paragraph 3: [Justification / intuition]
             "The rationale behind [component] is that [mechanism explanation]."
             "This design allows [benefit] by [mechanism]."
```

### 2.4 公式编号惯例

- 编号公式 20-35 个（PINN 类论文）
- 使用 `\label{eq:xxx}` 格式（`eq:` 前缀）
- 跨 section 连续编号（不用 2.1, 2.2 节前缀）
- 定理用 `\begin{theorem}...\end{theorem}`

---

## §3 Experiments 模板

### 3.1 实验总览段落

```latex
\section{Numerical experiments}
In this section, we evaluate the performance of [method name] on [number] benchmark problems. We compare against [baselines] using [metrics]. The experimental setup is summarized in Table~\ref{tab:setup}. The implementation details are provided in the appendix.
```

### 3.2 每个 Benchmark 的标准结构

```latex
\subsection{[Benchmark name]}
We first consider the [PDE type] equation...
\begin{equation}
... \label{eq:benchmark1}
\end{equation}
with boundary/initial conditions...
%
Figure~\ref{fig:benchmark1_results} shows the predicted solution and point-wise error.
%
Table~\ref{tab:benchmark1} compares the accuracy of [method] against [baselines].
%
[Method name] achieves a relative $\ell_2$ error of [X], compared to [Y] for baseline [B], representing an improvement of [Zx].
```

### 3.3 量化对比句式模板

| 比较类型 | 模板 |
|----------|------|
| **绝对对比** | "reduces the relative $\ell_2$ error from $X$ to $Y$" |
| **倍数提升** | "an improvement of over $Z\times$ compared to baseline" |
| **最优声明** | "achieves the best performance among all tested methods" |
| **普遍性** | "consistently outperforms [baselines] across all test cases" |
| **稳健性** | "maintains accuracy within [range] under [variation]" |
| **半定量** | "reduces error by up to [percentage]\%" |

### 3.4 消融研究模板

```latex
\subsection{Ablation study}
To investigate the contribution of each component in [method], we conduct ablation experiments by removing or replacing individual components:
\begin{itemize}
    \item \textbf{[Component A]}: replacing [A] with [alternative] reduces accuracy from [X] to [Y].
    \item \textbf{[Component B]}: removing [B] leads to [consequence].
    \item \textbf{Full model}: the complete [method] achieves [best result].
\end{itemize}
These results confirm that each component contributes to the overall performance.
```

### 3.5 表格模板

```latex
\begin{table}[t]
\centering
\caption{Relative $\ell_2$ error comparison across methods.}
\label{tab:main_results}
\begin{tabular}{lcccc}
\toprule
Benchmark & PINN & Baseline A & Baseline B & Ours \\
\midrule
Bench 1 & $X_1$ & $X_2$ & $X_3$ & $\mathbf{X_4}$ \\
Bench 2 & $Y_1$ & $Y_2$ & $Y_3$ & $\mathbf{Y_4}$ \\
\bottomrule
\end{tabular}
\end{table}
```

**注意**：
- 最佳结果用 `\mathbf{}` 加粗，次优用 `\underline{}`
- 表格上方有 caption，下方有注释（如果需要）
- 比较必须是在相同条件下的（相同 metrics、相同数据集）

---

## §5 Conclusion 模板

```latex
\section{Conclusion}
In this paper, we proposed [method name], a [descriptor] framework for [problem]. [Method name] achieves [key result] through [core mechanism], demonstrating [advantage].

Experimental results on [benchmark list] show that [method name] [quantitative result] compared to [baselines]. [Specific strong result] highlights the potential of our approach for [application].

[Acknowledge limitation naturally]: We have not addressed [limitation]; this is left for future work. Future directions include [direction 1] and [direction 2].
```

**长度控制**：2-5% 全文篇幅。具体来说：
- 1 段总结（2-3 句）
- 1 段实验结果回顾（1-2 句）
- 1 段局限 + 未来工作（1-2 句）
- 总共 4-7 句

---

## 附录策略

根据 16 篇论文分析，附录存在两极化现象。选择一种：

**策略 A — 无附录**（6/16 论文）：
- 所有内容在正文中
- 要求正文完整自包含
- 适合方法简单或老派的 JCP 论文

**策略 B — 重量附录**（5/16 论文）：
- Appendix A: 超参数配置
- Appendix B: 理论证明 / 推导
- Appendix C: 额外实验结果
- Appendix D+: 基准数据生成 / 算法伪代码

附录的优点：主文保持简洁，审稿人看 main text 即可理解核心，细节在附录供深度阅读。
