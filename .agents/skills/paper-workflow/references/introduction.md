# Introduction

Composed of two sub-parts: **Background** (Move 1) and **Introduction proper** (Moves 2–3).

## Background (Move 1)

Background 只解释核心定义和必要上下文，不要展开方程推导或算法细节。需推导的内容放到 Methods 节。

| ❌ Avoid | ✅ Instead write |
|---------|----------------|
| 大段方程推导 | "PINNs embed PDE residual constraints into the training objective [6]" |
| 详细解释某方法的数学原理 | "Operator learning directly learns mappings between function spaces [7]" |

## Introduction (Move 1–3)

```
Move 1: Establishing a territory (Background)
  Step A: Claim centrality — why this field matters (1–2句, 不引文献)
  Step B: Review prior contributions — 每篇前人工作独立写出贡献

Move 2: Establishing a niche
  Step A: Indicate a gap — focus on "a concrete solvable problem"
  Step B: Raise a question / continue a tradition

Move 3: Occupying the niche
  Step A: Outline purpose — "This paper proposes…"
  Step B: Announce principal findings
  Step C: State structure — paper organization (optional)
```

**Key rule — 每篇前人工作必须独立写出具体贡献**：

只要出现对前人工作的引用，就必须使用 "**Author** → **verb** → **what they contributed**" 格式。**禁止将多篇文献捆绑为一个引用组**，如 "第一类路径关注 PINN transfer learning [8, 15, 18–21, 32]"。

| ❌ Avoid | ✅ Instead write |
|---------|----------------|
| "物理信息神经网络（PINNs）[6]" | "Raissi et al. (2019) 提出了物理信息神经网络（PINNs），将 PDE 残差约束嵌入网络训练目标" |
| "算子学习 [7,8]" | "Lu et al. (2021) 提出了 DeepONet，直接从数据学习函数空间之间的映射。Li et al. (2020) 提出了 Fourier Neural Operator (FNO)，在傅里叶域参数化积分核实现 PDE 解算子的学习" |
| "第一类路径关注 PINN transfer learning [8, 15, 18–21, 32]" | "Goswami et al. (2020) 通过全参数微调将预训练 PINN 迁移至相场断裂问题；Chen et al. (2021) 在气动 PDE 上验证了全参数微调的有效性；Xu et al. (2023) 提出了面向工程结构的 PINN 迁移学习方法" |

**Common issues**: 引用组未拆分、Background 混入推导细节、Gap 分析仅停留在现象层、Move 1→Move 2 缺过渡、Move 3 未回应 gap。
