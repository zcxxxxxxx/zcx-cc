---
name: paper-structure-coach
description: |
  Guide academic paper section planning based on IMRaD structure and SCI publication
  standards. Activate when: drafting a new paper, reviewing manuscript structure,
  expanding a specific section, or organizing experimental data into results sections.
  Also use this skill whenever ARS academic-research-skills paper writing or review
  skills (ars-full, ars-revision, ars-plan, ars-outline, ars-lit-review,
  sci-paper-reviewer) are invoked — this skill provides the structural coaching
  foundation they rely on. Make sure to use this skill whenever the user mentions
  paper structure, IMRaD, manuscript review, SCI submission, or is organizing a draft,
  even if they don't explicitly ask for a "structure review."
  Do NOT use for: reference formatting, image resolution adjustment, or grammar proofreading.
allowed-tools: Read, Grep, Glob, Write, Edit
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
| Expanding a single section | Read the relevant reference file, then apply its conventions to the section |
| Final review of first draft | Delegate to `/paper-review-checklist` for item-by-item review |

## Section Routing

When reviewing or drafting a specific section, read the corresponding reference file for detailed conventions:

| Section | Reference file | When to load |
|---------|---------------|-------------|
| Abstract | `references/abstract.md` | Reviewing or drafting abstract |
| Introduction (incl. Background) | `references/introduction.md` | Reviewing Move 1–3 structure, citation style, gap analysis |
| Methods | `references/methods.md` | Checking reproducibility, verifying section completeness |
| Results | `references/results.md` | Reviewing results presentation, figure references, writing style |
| Discussion | `references/discussion.md` | Interpreting findings, comparative analysis, overclaim check |
| Figures & Tables | `references/figures-tables.md` | Placement conventions, caption format, data presentation rules |
| Conclusion | `references/conclusion.md` | Distilling scientific contributions |
| JFM conventions | `references/jfm-conventions.md` | Targeting JFM: British English, notation macros (`\Rey`, `\Pran`), sentence case headings, author-year citations |
| JCP conventions | `references/jcp-conventions.md` | Targeting JCP: numbered sections, Vancouver refs `[1]`, code/data availability, required declarations |
| Fluid mech. common | `references/fluid-mech-common.md` | General fluid mechanics: grid convergence/V&V, dimensionless parameters, flow visualization, symbol consistency |

> Load the reference file **only** when working on that section. The general rules below (Overclaim Check, Defensive Language Check) apply to all sections automatically.

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
- [ ] 未来展望是否以"若假说成立"等条件限定语开头，还是直接断言了必定成立？
- [ ] 高维外推是否标注为推测（"将...跃迁为"→"可望...获得"）？

## Defensive Language Check — 防御性语句检测

防御性语句指不携带信息量、仅作为"安全缓冲"前置在句首的废话。核心原则：**每句话应从实质内容开始**，而非从防御性前缀开始。

### 常见防御性语句分类

| 类别 | 防御性前缀 | 直接改写 |
|------|-----------|---------|
| **空洞引导** | "值得注意的是…"、"需要指出的是…"、"值得一提的是…" | → 直接陈述事实 |
| | "It is worth noting that…"、"It should be noted that…"、"It is important to mention that…" | → (direct statement) |
| | "It is interesting to note that…"、"It should be emphasized that…" | → (direct statement) |
| **不言自明** | "众所周知…"、"As is well known…"、"It is obvious that…"、"Of course…" | → 如果真的人尽皆知就不写；如果需要写，直接给出引用 |
| | "不难发现…"、"显而易见…"、"Naturally…" | → 直接陈述观察结果 |
| **弱化填充** | "It seems that…"、"It appears that…"、"It could be argued that…" | → 有证据用"表明"，无证据不写 |
| | "某种程度上…"、"在一定程度上…" | → 改为具体量化（"在 XX 条件下"） |
| **元评论** | "需要强调的是…"、"值得强调的是…" | → 直接写重点 |
| | "值得一提的是…" | → 直接写事实 |
| | "This section discusses…"、"As mentioned above…" | → 除非必要导航，否则删除 |
| **过度自谦** | "据我们所知…"、"To the best of our knowledge…" | → 首次提出新结果时用一次足矣，不必每段开头都用 |
| | "据我们所查…"、"As far as we know…" | → 同上一行 |

### 全文规则

1. **Abstract 零容忍**：摘要不允许出现任何防御性前缀，每句必须以实质内容开头
2. **Results 节全删**：结果部分不应有任何引导语，"Fig. X shows that…" 之外的 lead-in 一律删除
3. **Discussion 节区分**：Discussion 中需要区分**真正的谨慎限定**（如"这些结果提示但尚未证明"）和**防御性废话**（"It is important to note that our results suggest…"）。前者保留，后者删除
4. **全文检索**：对稿件执行一次全文搜索，定位所有以"It is…"、"It should…"、"It can…"、"It is important to…"、"It is interesting to…"、"It may…"、"It might…"、"It must be…"、"需要指出"、"值得注意"、"不难发现"、"需要强调"、"需要说明"开头的句子，逐一判断是否为防御性语句

### 判断标准

一段文字的开头是否属于防御性语句，问两个问题：
- [ ] 去掉前 5–10 个词后，剩余句子的信息是否完整？
- [ ] 这 5–10 个词是否仅表达了"我要说话"而没有增加语义？

如果两问都答"是"，删除这些词。

## Boundaries

- This skill does **structure planning and content review**, not grammar proofreading, reference formatting, or figure/table creation
- For the full 27-item final review checklist, use `/paper-review-checklist`
- Section-specific reference files are loaded on demand — read the relevant file when you need it
