# JCP Introduction 8 段式详细写作指南

基于 16 篇 JCP 2026 PINN 论文的系统分析。

## 全段模板

### Step 1: 域设定（3-5 句）

**功能**：确立论文所属的领域，吸引 JCP 读者群。

**模板**：
```text
[Problem class] has emerged as a [descriptor] in [domain], playing a [role] in [application area]. In particular, [specific subproblem] is [importance statement]. For example, [concrete example of importance].
```

**关键词池**：
- "has emerged as a powerful tool/paradigm/framework"
- "plays a critical/paramount/fundamental role in"
- "remains a key challenge/limitation/barrier"

**引用模式**：引用簇 3-5 篇 [1-5]

**中文对应**（用于初稿）：
```
[问题类别] 已成为 [领域] 中的 [地位描述]，在 [应用场景] 中发挥 [作用]。特别是，[子问题] [重要性描述]。
```

### Step 2: 问题定义（3-5 句）

**功能**：给出 PDE 公式 + 传统方法的背景和局限。

**模板**：
```text
The governing equations take the form
\[ \mathcal{D}[u](x,t) = f(x,t), \ldots \]
where u denotes [unknown], D is [operator], and f is [source term].
Traditional numerical methods such as [FDM/FEM/FVM] [strengths], but [limitations] when [specific condition].
```

**关键**：这是第 1 次出现 PDE 公式的位置。JCP 读者需要在这里看到明确的数学对象。

**中文对应**：
```
控制方程为 [PDE]，其中 u 是 [未知量]，D 为 [算子]，f 为 [源项]。
传统数值方法如 [FDM/FEM] 在 [优点]，但在 [局限条件] 下 [具体局限]。
```

### Step 3: PINN 引入（2-4 句）

**功能**：引入 PINN 作为替代方案。

**模板**：
```text
Physics-informed neural networks (PINNs) [Raissi et al., 2019] offer a [advantage] by [mechanism]. PINNs have been successfully applied to [application list], demonstrating [capability]. However, [specific PINN limitation relevant to your problem].
```

**注意**：这里的 "However" 是过渡性的，不是最终的 gap。真正的 gap 在 Step 5。

**引用**：Raissi 2019 是必须引用的（15/16 论文引用）

### Step 4: 现有方法（5-8 句，最重要的段落）

**功能**：分类综述现有 PINN 改进方法，建立你的差异化基础。

**常见分类方式**（三选一）：

**方式 A — 架构分类**（推荐用于方法论文）：
```text
Existing efforts to address [problem] in PINNs can be broadly classified into three categories:
(i) Architecture modifications — [list: attention, Fourier features, KAN...];
(ii) Loss and training modifications — [list: adaptive weighting, causal training, domain decomposition...];
(iii) Physical modifications — [list: artificial viscosity, change of variables, weak-form...].
```

**方式 B — 时间线/代际分类**：
```text
Early approaches focused on [early approach]. More recent work has explored [recent approach]. A parallel line of research investigates [parallel direction].
```

**方式 C — 连续域 vs 分段**：
```text
Continuous-domain methods address [problem] by [mechanism], but [limitation]. Segment-based methods, in contrast, [approach], yet [different limitation].
```

**注意事项**：
- 不要只是列举论文，要分类+批评
- 每类方法的局限要具体（不只是"不够好"）
- 引用密度高，但每个引用要有目的

### Step 5: Gap 识别（2-3 句，全文最关键）

**功能**：在现有工作丛林中标出你论文的精确位置。

**三种策略**：

| 策略 | 模板 | 适用场景 |
|------|------|----------|
| **交集空白** | "Despite progress in [A] and [B], the problem of [A+B] remains unexplored." | 你的方法填补两个方向的交叉点 |
| **拆解局限** | "However, these methods share three limitations: First..., Second..., Finally..." | 你的方案系统性优于现有方法 |
| **Trade-off** | "These methods inherently involve a trade-off between [X] and [Y]." | 你的方法声称打破了权衡 |

### Step 6: 本文方案（3-4 句）

**功能**：一句话说清你做了什么。

**模板**（三选一）：
```text
To address this challenge, we propose [method name], which [core mechanism].
```
```text
In this work, we introduce [method name], a [descriptor] framework that [key innovation].
```
```text
Here, we present [method name], which leverages [mechanism] to [achieve goal].
```

### Step 7: 贡献列表（3-5 项）

**功能**：审稿人首先看到的部分，必须清晰、具体、可验证。

**格式**（推荐编号，7/16 论文用此格式）：
```text
The main contributions of this work are three-fold:
1. [Conceptual/theoretical contribution]: We [discover/propose/identify]...
2. [Methodological contribution]: We develop [method name] that achieves [what] via [how]...
3. [Empirical contribution]: We demonstrate [result] through comprehensive experiments on [benchmarks]...
4. [Optional additional contribution]
```

**每个贡献的应包含**：
- 一个动作动词（propose, develop, identify, demonstrate）
- 一个具体对象（method name / framework / phenomenon）
- 一个可验证的结果（精度、效率、通用性）

### Step 8: Roadmap（1 句）

**模板**：
```text
The remainder of this paper is organized as follows. Section 2 describes [topic]. Section 3 presents [topic]. Section 4 reports [topic]. Section 5 concludes the paper.
```

**Note**: 不需要加 "finally" 在最后一项之前，保持简洁。

## 常见检验

写完后问自己：
1. 每段是否只有 1 个功能？（不要合并 gap 和方案）
2. Gap 是否具体到足以让审稿人知道你的确切位置？
3. 贡献列表的每一项是否都可以在后面的章节中找到对应证据？
4. 所有引用是否有目的？（不只是填充引用密度）
5. 去掉 Step 7（贡献列表）后，读者是否还能从 Step 1-6 理解你的贡献？
