---
name: paper-structure-coach
description: |
  Guide academic paper section planning based on IMRaD structure and SCI publication
  standards. Activate when: drafting a new paper, reviewing manuscript structure,
  expanding a specific section, or organizing experimental data into results sections.
  Do NOT use for: reference formatting, image resolution adjustment, or grammar proofreading.
allowed-tools: Read, Grep, Glob, Write
---

## Activation

Use when:
- Drafting a new paper, need to plan chapter layout and logical flow
- Reviewing existing draft structure: section completeness, argument chain, SCI fitness
- Expanding/restructuring a specific section
- Organizing experimental data into publication-ready results

**Skip** if: only modifying reference format, adjusting figure resolution, or proofreading grammar.

## Workflow

| Scenario | Output |
|----------|--------|
| Drafting from scratch | Complete IMRaD outline with core arguments and expected evidence per section |
| Reviewing existing draft | Section-by-section diagnostic: structural defects, logic breaks, SCI deviations |
| Expanding a single section | Academic writing template with sub-structure conventions |
| Final review of first draft | Delegate to `/paper-review-checklist` for item-by-item review |

## Overclaim Check — 适用于全文

评审稿件时必须检查每处措辞是否超出实际证据的支持范围。

**核心原则**：每一句声称与支持这一声称的数据点数量之间必须比例匹配。

| 仅有 | 最激进的可接受措辞 |
|------|-------------------|
| 1 个数据点 | "初步提示"、"有待验证" |
| 2–3 个数据点 | "提示"、"与...定性一致" |
| 多个独立重复 | "表明"、"呈现出" |
| 严格理论推导 | "证明了"、"确定了" |

**需标记的高危措辞**（逐词扫描）：

| 类别 | 高危措辞 | 减级替换 |
|------|---------|---------|
| **绝对化** | "决定了"、"本质上"、"必然" | → "很大程度上影响"、"在...条件下" |
| **数学过度声称** | "严格的证明"、"数学本质"、"数学严格" | → "理论依据"、"关键机制"、"理论分析" |
| **宏观断言** | "奠定理论基石"、"开创性"、"突破"、"范式转变" | → "提供理论支撑"、"重要进展"、"有益探索" |
| **动机拔高** | "具有重大意义"、"至关重要"、"亟待解决" | → "具有工程价值"、"值得关注"、"尚未充分刻画" |
| **戏剧化** | "击穿"、"摧毁"、"跃迁"（非物理量跃迁） | → "超出限制"、"受限"、"转化为" |
| **情感化** | "令人惊讶"、"反直觉"、"值得玩味的是" | → 直接陈述事实 |

**禁用词**（出现即判过稿）："novel"、"groundbreaking"、"first-ever"、"unprecedented"、"revolutionary"。

### Check: 夸大检测清单

对稿件每个段落，问三个问题：
- [ ] 这一句的声称强度是否与数据点数量相当？
- [ ] 是否使用了"表明"、"证明"、"揭示了"等超出实际证据强度的措辞？
- [ ] 同一语义是否用不同词语重复了两遍（如"容量裕度压缩 + 信息容量不足"）？

### Check: 展望与结论边界
- [ ] 未来展望从§5.2末尾"若假说成立"开始做了限定，还是直接断言了必定成立？
- [ ] 高维外推是否标注为推测（"将...跃迁为"→"可望...获得"）？

## IMRaD Section Conventions

### Abstract

Follow Background–Gap–Method–Results–Significance flow. Each sentence serves one role. Abstract must be a **single paragraph** (no line breaks, no sectioning). No citations, no undefined abbreviations, no emotional modifiers.

| ❌ Avoid | ✅ Instead write |
|---------|----------------|
| "novel approach" | "approach" |
| "groundbreaking results" | "the results indicate that..." |

### Background (Move 1 of Introduction)

Background 只解释核心定义和必要上下文，不要展开方程推导或算法细节。需推导的内容放到 Methods 节。

| ❌ Avoid | ✅ Instead write |
|---------|----------------|
| 大段方程推导 | "PINNs embed PDE residual constraints into the training objective [6]" |
| 详细解释某方法的数学原理 | "Operator learning directly learns mappings between function spaces [7]" |

### Introduction (Move 1–3)

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

### Methods

Core principle: **reproducibility**.
1. Problem formalization (governing equations, BCs, ICs, loss function)
2. Method description (mathematical framework, design choices justified with citations)
3. Experimental configuration (data, hyperparameters, metrics, software/hardware)

Constraints: cite rather than rewrite published method descriptions; keep symbols consistent; no result statements.

### Results

Present **what was found**, not what it means (that goes in Discussion).
1. Baseline verification (compare with reference/ground truth)
2. Method comparison (accuracy, convergence, resource cost)
3. Ablation/sensitivity (optional, with multi-seed statistics)

Active voice preferred: "We calculated…" not "Calculations were performed…".
Remove hollow lead-ins: "It is worth noting that…" → (direct statement).
Grammar: "Fig. 2 shows…" (present), "The model achieved…" (past).

### Discussion

Answer "So what?" — place results in broader context.
1. Restate and interpret core findings (mechanism explanation)
2. Compare with existing work (consistent and divergent points)
3. Limitations (integrate naturally, not "Several limitations" subheading)
4. Conclusions and outlook

Constraints: no new results; no speculation beyond boundaries; citations for comparative claims.

**Overclaim checks (Discussion 专有)**:
- [ ] 机制解释中的"表明"是否被数据强度支持？2 个种子不能"表明"，只能说"提示"。
- [ ] 外推/展望是否标注为推测语气（"可望"、"有待"、"需进一步验证"）？
- [ ] "机理"不写作"机制"？"机制 (mechanism)"需要有因果链证据，"机理 (phenomenology)"仅描述现象。

### Conclusion

Distill "what scientific question this answers" — not a data summary.
1. Research contributions (present simple)
2. Experimental conclusions (past simple / present perfect)
3. Future directions (present simple, with modals)

## Boundaries

- This skill does **structure planning and content review**, not grammar proofreading, reference formatting, or figure/table creation
- For the full 27-item final review checklist, use `/paper-review-checklist`
