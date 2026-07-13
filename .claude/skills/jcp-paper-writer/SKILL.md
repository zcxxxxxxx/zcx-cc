---
name: jcp-paper-writer
description: >
  Guides writing of JCP (Journal of Computational Physics) papers in the PINN/PDE
  domain based on systematic analysis of 16 JCP 2026 papers. Covers macro structure
  (5-section IMRaD variant), Introduction 8-paragraph formula, Method description
  strategies (递进/分解/定理-证明/通用→具体), Experiment validation patterns
  (1D→2D→3D progression, ablation design), Conclusion/Limitations conventions,
  and bilingual (中文+English) writing patterns. Trigger when: user says "写JCP论文",
  "写论文", "JCP结构", "论文写作", "章节安排", or when reviewing/revising a JCP
  manuscript draft. Also trigger when user asks about JCP paper structure, section
  organization, or writing conventions for computational physics papers. Integrates
  with paper-workflow skill for post-writing audit (overclaim, defensive language,
  padding, self-triggering checks) — invoke paper-workflow at the end of each
  writing phase.
---

# JCP Paper Writer

基于 16 篇 JCP 2026 PINN 论文的系统分析，指导 PINN/PDE 领域的 JCP 论文写作。

## 核心原则

1. **JCP 不缺模板化** — 审稿人期望看到熟悉的 IMRaD 结构。创新在内容，不在形式。
2. **每句话必须有信息量** — 没有"软"开头。JCP 审稿人是做计算物理的，敏感于空洞陈述。
3. **实验为王** — 实验部分应占全文 35-45%。一个公正的基线对比胜过三个花哨的图。
4. **诚实是最好的策略** — JCP 认可诚实的局限陈述（不辩护的局限），反感过度承诺。

## Workflow

### Phase 1: 结构规划

在动笔前，先确定整篇论文的 skeleton。默认采用 JCP 标准 5 节 IMRaD 变体：

```
§1 Introduction      (12-15% 篇幅) — 8 段式标准结构
§2 Methodology       (25-35% 篇幅) — 选一种描述策略
§3 Experiments       (35-45% 篇幅) — 1D→2D→3D 递增
§4 Discussion        (可选，~5%) — 或并入 Conclusion
§5 Conclusion        (2-5%) — 总结+局限+未来工作
```

**输出要求**：生成一个 `paper-skeleton.md` 文件，列出每节核心内容、公式数量目标、图/表位置。用户批准后再进入 Phase 2。

### Phase 2: 逐节撰写

按 §1 → §2 → §3 → §5 的顺序撰写。每个 section 完成后，用 `paper-workflow` skill 做内容审计（overclaim check、defensive language check、padding audit）。

#### §1 Introduction — 8 段式标准结构

16 篇中有 14 篇用此结构。严格遵循：

| 段 | 功能 | 核心内容 | 时长 |
|----|------|----------|------|
| 1 | **域设定** | "XX has emerged as..." + 引用簇 [1-5] | 3-5 句 |
| 2 | **问题定义** | PDE 公式化表述 + 传统方法局限性 | 3-5 句 |
| 3 | **PINN 引入** | Raissi 2019 + PINN 应用领域 | 2-4 句 |
| 4 | **现有方法** | 分类综述（按主题分类，非时间顺序） | 5-8 句 |
| 5 | **Gap 识别** | "However..." + 特定未解决问题 | 2-3 句 |
| 6 | **本文方案** | "To address this, we propose..." | 3-4 句 |
| 7 | **贡献列表** | 3-5 项，编号或 bullet | 3-6 句 |
| 8 | **Roadmap** | "The remainder of this paper is organized as follows..." | 1 句 |

**Gap 策略选择**：
- **交集空白**（推荐）: A 已解决，B 已解决，但 A+B 未解决
- **拆解局限**: 现有方法三个局限逐一列明
- **Trade-off**: 存在根本性权衡未被解决

**语言要点**：
- "To address this/these..." / "In this work..." / "To this end..." 三选一引入本文
- "novel" ≤ 2 次 — JCP 审稿人对该词敏感
- "To the best of our knowledge" 用 1 次，仅用于核心创新点
- 贡献列表必须有，15/16 的 JCP 论文都有

#### §2 Methodology — 方法描述

**通用 PDE 形式**（必选，放在 §2 开头）：

```latex
\mathcal{D}[u](x,t) = f(x,t), \quad (x,t) \in \Omega \times (0,T],
\mathcal{B}[u](x,t) = g(x,t), \quad (x,t) \in \partial\Omega \times [0,T],
\mathcal{I}[u](x,0) = h(x), \quad x \in \Omega.
```

**损失函数**（标准三件套，100% JCP 论文使用）：

```latex
\mathcal{L}(\theta) = \lambda_{\text{pde}} \mathcal{L}_{\text{pde}} + \lambda_{\text{ic}} \mathcal{L}_{\text{ic}} + \lambda_{\text{bc}} \mathcal{L}_{\text{bc}}
```

**方法描述策略**（四选一）：

| 策略 | 适用场景 | 结构 |
|------|----------|------|
| **递进式** | 你的方法有 >2 个逐步改进 | Baseline → enhancement1 → enhancement2 → proposed |
| **分解式** | 方法由多个独立组件组成 | Component 1 → Component 2 → Component 3 → Integration |
| **定理-证明** | 有严格的数学理论支撑 | Theorem → Proof → Implementation |
| **通用→具体** | 先提通用框架再具体化 | General framework → Specific PDE → Specific architecture |

**公式数量目标**：20-35 编号公式（PINN 方法类论文）

**必含信息**：
- 网络架构（层数 + 宽度）
- 学习率 + 优化器
- 损失函数的具体定义
- 训练流程（epochs, batch size）

#### §3 Experiments — 实验验证

**实验递增顺序**（100% JCP 论文遵循）：

```
1D benchmark    →    2D simple domain    →    2D complex domain    →    3D / real-world
（验证方法）         （规则域验证）           （不规则/挑战域）           （高维/工程）
```

**每个 benchmark 的标准段落模板**：

1. PDE 定义 + 参数值
2. 数据生成/配置说明
3. 训练配置
4. 精度指标（推荐：相对 L2 误差 + L∞）
5. 与基线的量化对比（"从 X 降低到 Y，提升 Z 倍"）
6. 图/表引导

**基线对比要求**：
- 标准 PINN (Raissi 2019) — 最低标准基线
- 1-3 个具体命名的 SOTA 方法 — 使用他们的公开代码或已发表结果
- 消融变体 — 至少移除每个核心组件

**消融研究**：至少包含 2 种类型
- 组件有无对比（必须做，9/16 论文有）
- 以下至少选一个：超参数灵敏度 / 网络宽度深度 / 随机种子稳健性

**误差指标**：相对 L2 误差是绝对主流（14/16），建议再选一个（L∞ 或 RMSE）

**表类型**：至少 2 种表格
- 误差对比表（与基线）— 必须
- 以下选至少一个：超参数设置 / 消融结果 / 计算时间

**图类型**：至少 4 种
- 架构示意图（必须）
- 解场预测图（必须）
- 误差对比图（推荐）
- 收敛曲线图（推荐）

**可选标准 Benchmark（从你的实验中选择）**：
- Burgers 方程（8/16 JCP 论文使用）
- Poisson 方程（7/16）
- Helmholtz 方程（6/16）
- Allen-Cahn 方程（5/16）
- Navier-Stokes（5/16）

**公式数量目标（可选）**：如果能提供 PDE 本身的公式定义，计入 §3

#### §4 Discussion（可选）

如果你有独立的 Discussion，结构如下：
- 主要发现总结（1 段）
- 方法局限（1 段，自然地陈述，不与"局限"标题一起使用）
- 与已有工作的关系（0-1 段）

**局限陈述规则**（基于 16 篇论文分析）：
- JCP 不接受"Limitations"独立章节标题
- 局限用自然段落嵌入 Conclusion 或 Discussion 末段
- 诚实的局限陈述（不跟"但不影响结论"辩护）是最好的策略
- 不要把局限包装成"future work"— 直接承认

#### §5 Conclusion

**标准三段式**：
1. 工作总结（2-3 句，回顾主要贡献）
2. 量化成就（1-2 句，最好有具体的性能数据）
3. 未来工作（1-2 句，自然的延伸方向）

**长度**：全文的 2-5%。12-16 篇论文中结论是最短的章节。

### Phase 3: 全文审计

用 `paper-workflow` skill 对全文逐一运行：
1. **Overclaim Check** — 每个声称是否有实验支持？
2. **Defensive Language Check** — 去掉前 5-10 个字的防御性填充
3. **Padding Audit** — 删掉冗余复述、过度解释的标准技术、无附加值的段落
4. **Self-Triggering Defense Check** — 不要主动引爆自己的弱点然后辩护
5. **Abstract Convention Check** — 连续散文、无负面结果、无"本文"引导
6. **Abstract Quantitative Check** — 摘要中的数字是否过度详细？

### Phase 4: 终审（Final Review）

使用 `paper-workflow` 的 final review 模式运行 27 项检查清单。

## 写作风格指南

### 主动语态 vs 被动语态

12/16 JCP 论文使用主动主导。推荐：
- 方法描述：主动（"we propose", "we introduce"）
- 实验说明：被动也可（"experiments were conducted"）
- 结果描述：主动（"Fig. 3 shows", "we observe"）

### 定量对比句式模板

```text
"reduces the relative L2 error from X to Y"
"an improvement of over Zx compared to baseline"
"consistently outperforms all tested methods"
"achieves the best performance among all compared approaches"
```

### 过渡短语模板

| 功能 | 推荐短语 |
|------|----------|
| 引入 gap | "However, existing methods..." / "Despite these advances..." |
| 提出方案 | "To address this challenge, we propose..." |
| 定位差异 | "In contrast to..., our method..." |
| 解释改善 | "This improvement can be attributed to..." |
| 承认局限 | "We do not pursue X here; this is left for future work." |

### 绝对要避免的表达

- `novel` > 2 次（JCP 审稿人敏感词）
- `groundbreaking`, `first-ever`, `unprecedented`, `revolutionary`（自动拒稿级）
- "值得注意的是" / "It is worth noting that"（无信息量的填充）
- "众所周知" / "As is well known"（除非需要引用）
- "需要强调的是" / "This section discusses"（元评论）

## 参考与集成

### 上游

- 实验结果的 raw metrics 来自 `harness-engineering` 的实验记录

### 下游

- `paper-workflow` skill — 每节写完后运行内容审计
- `paper-workflow` references/jcp-conventions.md — JCP 具体格式规范
- `paper-workflow` references/review-checklist.md — 终审检查清单

### Reference 文件说明

本 skill 的 `references/` 目录包含各章节的详细写作模板，需要时用 Read 工具加载：

| 文件 | 内容 | 何时读 |
|------|------|--------|
| `jcp-section-templates.md` | 各章节的逐句模板 + LaTeX 代码片段 | 开始写对应章节时 |
| `jcp-introduction-8step.md` | Introduction 8 段式的详细写作指南 | 写 §1 时 |
| `jcp-experiment-patterns.md` | 实验 section 的详细模板 + 常用对比句式 | 写 §3 时 |

## 典型工作流程

```dot
User: "帮我写 JCP 论文"
  → Phase 1: 生成 skeleton，用户确认
  → Phase 2 §1: 写 Introduction → paper-workflow 审计 → 迭代
  → Phase 2 §2: 写 Methodology → paper-workflow 审计 → 迭代
  → Phase 2 §3: 写 Experiments → paper-workflow 审计 → 迭代
  → Phase 2 §5: 写 Conclusion → paper-workflow 审计 → 迭代
  → Phase 3: 全文审计（6 项检查）
  → Phase 4: 终审（27 项检查清单）
  → 完成
```

用户也可以从任意阶段介入（如已有初稿，跳到 Phase 3 审计）。
