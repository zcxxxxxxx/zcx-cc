# JCP (Journal of Computational Physics) — 投稿规范

JCP 为 Elsevier 旗下期刊，专注于计算物理方法与应用。对数值方法和计算结果的严谨性有较高要求。

## 论文结构

| 元素 | 要求 |
|------|------|
| 类型 | Full Article（推荐 25–35 页）、Short Note（≤4 页）、Review |
| 篇章结构 | 编号章节 (1, 2, 2.1)，IMRaD 兼容 |
| 摘要 | 单段自包含：目的、主要结果、主要结论。无引用，定义非标准缩写 |
| 关键词 | 需要（文中列出） |
| 公式 | 顺序编号 (1), (2), (2a,b) |
| 字体 | Times New Roman 12pt，1.5 倍行距 |
| LaTeX | `elsarticle.cls` + `jcomp.sty` |

### 必备声明

- **竞争利益声明**（即使为 None）
- **作者贡献声明**（每位作者角色）
- **代码/数据可用性声明**（强烈鼓励，GitHub/Zenodo 链接）
- **资助来源**

## 方法章节要求

### 数值算法描述
- 控制方程 + 边界条件完整
- 数值格式（时间推进、空间离散、求解器）清晰描述
- 网格分辨率及收敛性研究
- CFL 数、时间步长等关键参数
- 与已发布 benchmark 的验证对比

### 可复现性标准
JCP 近年来对可复现性审查强度增加约 15%。要求：
- 代码可用性声明（GitHub + DOI）
- 所有超参数完整报告
- 随机种子数及统计显著性
- 多种子多次运行的统计量（mean ± std）

## 图表规范

| 元素 | 要求 |
|------|------|
| 图标题 | **在下方** |
| 表标题 | **在上方** |
| 分辨率 | ≥300 dpi |
| 格式 | TIFF 或 EPS |
| 大小 | 建议不超过半页 |
| 单位 | SI 单位优先 |
| 图/表 | 按首次引用顺序编号，每个图/表必须在正文中被引用至少一次 |

## 参考文献格式

**Elsevier Vancouver 风格**——方括号顺序编号。

规范格式（来自 JCP 模板）：
```
[1] R.A. Street, Unraveling charge transport in conjugated polymers, Science 341 (2013) 1072–1073.
[2] J. Bass, J.S. Takahashi, Circadian integration of metabolism and energetics, Science 330 (2010) 1349–1354.
[3] W. Herbst, C.M. Hamilton, K. LeDuc, et al., Reflected light from sand grains, Nature 452 (2008) 194–197.
```

- 文中引用：`[1]`、`[1,2]`、`[1–3]`
- 建议参考文献数 ≤60 篇
- 优先近 3 年 JCR Q1 区文献

## 公式与符号

- 顺序编号 (1), (2), (2a,b)
- 方程作为句子的一部分加标点
- SI 单位优先
- Matlab/Python 风格符号在最终版本中需转为标准数学符号
- 所有变量首次出现时定义

## 投稿事项

| 项目 | 说明 |
|------|------|
| 首轮提交 | 单个 Word 或 PDF，无需特殊格式 ("Your Paper Your Way") |
| 修订阶段 | 需按期刊格式重新排版 |
| 主编 | Frederic G. Gibou (UCSB) & Dongbin Xiu (Ohio State) |
| 审稿人建议 | 投稿时要求提供 |
| 首次决定 | 平均 ~32 天 |
| 接收至上线 | ~4 天 |

## 审稿常见结构性问题

- Methods 中关键数值参数不完整（CFL、网格分辨率、收敛判据）
- 缺少网格无关性验证或验证不充分
- 代码/数据可用性声明缺失
- 结果节中混合了本应放在 Discussion 的解释性内容
- 声称强度超出实际证据范围（参见 Overclaim Check）
- 与已有文献的对比验证不充分

## 计算数据规范

### 数值算法的四项核心要求
JCP Guide for Authors 明确要求每篇论文必须涵盖：

| 要求 | 说明 |
|------|------|
| **Efficacy（有效性）** | 证明方法在目标问题上有效 |
| **Robustness（鲁棒性）** | 展示方法在不同条件下的稳定性和可靠性 |
| **Computational complexity（计算复杂度）** | 提供时间/内存缩放分析，如 $O(N)$ 标度 |
| **Reproducibility（可复现性）** | 提供代码/数据以支持结果验证 |

当论文解决的问题已有其他方法覆盖时，**必须提供与已有方法的定量对比**。

### 代码验证标准 (Code Verification)
- **Method of Manufactured Solutions (MMS)** 是 JCP 文献中公认的 code verification 金标准（Roy 2005, JCP 205(1), 131–156）
- 观察到的收敛阶（observed order of accuracy）应与格式理论精度阶一致
- 参考 Roache (1998) 的 V&V 框架和 Roy (2005) 的 JCP 综述

### 网格/配点收敛性
- 至少 3 套网格或配点集（粗/中/细）
- 关键积分量随网格变化的趋势
- 如使用 Richardson 外推，报告收敛阶和 GCI（Grid Convergence Index）
- 对于无网格方法（如 PINN），需进行配点收敛性研究

### 计算性能报告（并行算法）

JCP 虽无专门的并行计算报告模板，但发在该刊的并行算法论文通常遵循以下规范（Hoefler et al. SC'15）：

| 要素 | 要求 |
|------|------|
| **加速比基准** | 明确基例是单进程还是最优串行；**必须同时报告绝对执行时间** |
| **强缩放 vs. 弱缩放** | 必须指明；弱缩放需说明缩放函数 |
| **时间测量** | 使用 wall-clock time；计时器开销应 <5% 测量区间 |
| **统计严谨性** | 多次运行报告均值和变异性（标准差/置信区间），避免仅报告最佳结果 |
| **硬件环境** | 完整报告：CPU/GPU 型号、核心数、内存、编译器及版本 |
| **理想加速比参考线** | 图中需包含理想线性加速比作为参考线 |

### 统计与不确定度报告
- 多种子多次运行报告 mean ± std
- 随机种子数需声明
- 误差棒必须标注 ±SD 或 ±SEM
- JCP 无形式化 UQ 报告标准，建议按子学科惯例

## 文章类型判定指南

| 类型 | 判定标准 |
|------|---------|
| **Full Article** | 提出新方法/框架 + 完整理论分析 + 系统性数值实验 + 机理解释 → 推荐 25–35 页 |
| **Short Note** | ≤4 页（含图、表、参考文献），无摘要。用于简短通讯或新程序/数据可用性通告 |
| **Review** | 综述特定领域，JCP 特别鼓励 |

**判定 Checklist：**
- [ ] 是否包含完整的 IMRaD 结构？（Introduction → Methods → Results → Discussion → Conclusion）
- [ ] 是否提出了新的计算方法或框架？
- [ ] 是否有系统性数值验证（多种测试问题、多基线对比）？
- [ ] 是否包含理论分析或机理层面的解释？
- [ ] 是否提供了代码/数据可用性声明？

→ 如果上述回答均为"是"，则为 **Full Article**。

## LaTeX 模板说明

| 阶段 | 推荐模板 | 说明 |
|------|---------|------|
| **开发/工作稿** | 任意格式 | 自用格式 |
| **首轮提交** | 任意格式（Word 或 LaTeX，包括 `cas-sc.cls`） | "Your Paper Your Way" 政策 |
| **修订阶段** | `elsarticle.cls` + `jcomp.sty` | 需按期刊格式重新排版 |

- `cas-sc.cls` 是 Elsevier CAS（Complex Article Service）单栏模板，初始提交完全可接受
- 修订阶段必须切换至 `elsarticle.cls` + `jcomp.sty`（JCP 专用样式文件）
- 参考文献格式需从 author-year 改为 Elsevier Vancouver `[1]` 编号制

## AI/ML 与 PINN 类论文的附加要求

JCP 近年接收大量 PINN 及相关 AI for PDEs 论文。审稿人对这类论文的额外关注点：

### 方法复现性
- **代码必须可用**：GitHub + Zenodo DOI，含运行脚本、依赖说明、README
- **超参数完整报告**：优化器类型、学习率（固定/衰减、初值）、激活函数、权重初始化、batch size
- **硬件环境**：GPU 型号、CUDA 版本、深度学习框架及版本
- **随机种子**：声明使用的种子值，论证结果的统计稳定性

### 验证充分性
- 必须与**经典数值方法**（有限差分、有限元等）或**其他 AI 方法**（DeepONet、FNO、其他 PINN 变体）进行定量比较
- 需讨论配点/网格数量的收敛性
- 超参数敏感性分析（如 LoRA 秩的扫描）

### 声称强度
- **避免过度声称**：仅基于少数测试问题得出的结论应标注为"初步验证"或"假说"
- 跨维外推（如 1D → 3D）需标注推测性质
- 严格区分"观察到的现象"与"证明的结论"

### 常见审稿意见示例
- "Why only compare with Wang et al. (2025)? How does the method perform against FNO/DeepONet on the same benchmarks?"
- "Have you performed collocation point convergence study?"
- "The hyperparameter choice (e.g., LoRA rank r=16) is unclear — was a sweep performed?"
- "The claim of 'cross-dimensional universality' is not supported by 1D + 2D steady-state evidence alone."
