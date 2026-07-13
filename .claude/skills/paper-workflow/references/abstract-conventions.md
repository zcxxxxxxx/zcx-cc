# Abstract Convention Check (摘要惯例检查)

Evaluate abstract structure against JCP journal conventions. An abstract is the most-read part of a paper — structural missteps here erode reader confidence before the body is even reached.

**Why it matters:** JCP abstracts have consistent conventions that reviewers expect. Violations (structural markers, limitation admissions) signal inexperience and reduce the chance that a skimming reader absorbs the contribution.

## Structural Rules

| # | Rule | Why | Example violation |
|---|------|-----|-------------------|
| 1 | **Continuous prose — no structural markers** | JCP abstracts use no section headers, no "Key finding:" / "核心发现：" / "Main result:" labels. The narrative flows naturally from context to finding. | `\textbf{核心发现}：在 2D NS 中...` → Remove the bold marker; integrate into prose. |
| 2 | **No limitation or negative results** | Abstracts sell the contribution. Limitations, counterfactuals ("in 1D the advantage disappeared"), and negative results belong in the Discussion and Conclusions, not the abstract. | `在 1D 中...但大幅偏移下优势缩小或反转；参数压缩未转化为挂钟加速` → Delete from abstract; move to Conclusions. |
| 3 | **No "本文" / "In this paper" lead-in to the contribution** | JCP abstracts do not use "本文提出..." to announce the paper's existence. The first finding sentence should state the discovery, not the document. | `本文提出一种基于 LoRA 的 PINN 方法` → "基于 LoRA 的 PINN 方法" (omit "本文") |
| 4 | **No standalone prior-work review sentence** | JCP abstracts do not devote separate sentences to literature review. The gap should be implicit in the problem statement — a standalone "已有工作聚焦..." sentence consumes 10-15% of the abstract space without stating a contribution. Compress prior work into a dependent clause within the problem statement. | `已有工作聚焦外部约束变化（边界条件、几何构型），或依赖元学习预训练（如 HyperLoRA）。` → "但当 PDE 物理参数偏移时，已训练 PINN 须从头重训练——已有方法限于外部约束变化或元学习——因此本文在..." |

**Detection heuristic for rule 1:** If the abstract uses bold, bullet points, section numbers, or explicit labels ("Key finding:", "结果："), it violates JCP convention.

**Detection heuristic for rule 2:** Scan for sentences that describe when/where the method *doesn't* work, or caveats about limitations. If such a sentence can be deleted and the abstract still communicates the core contribution, delete it.

**Detection heuristic for rule 3:** "本文" at sentence start is almost always deletable padding. If removing "本文" left the sentence grammatical, remove it.

**Edge case — "本文" in contextualization:** "本文" is acceptable when contrasting with prior work within the same sentence (e.g., "已有工作聚焦...本文在...设定下"), because it serves a structural navigation purpose. Flag only when it's a pure lead-in to the method/finding statement.

**Detection heuristic for rule 4:** If a sentence can be deleted and the abstract's contribution statement remains fully intact, that sentence is not carrying its weight. Prior-work sentences should be compressed into a dependent clause within the problem statement (e.g., "——已有方法限于外部约束——因此本文..."). The test: does the abstract start with a sentence whose primary job is to summarize what others did? If so, that sentence belongs in the Introduction, not the abstract.

---

## Abstract Quantitative Check (摘要定量检查)

Flag abstracts that contain overly detailed quantitative results (mean ± std, per-configuration error listings) that belong in tables in the body.

**Why it matters:** An abstract communicates *what* you found, not the exact numbers — that's what tables and figures are for. Mean ± std notation and multi-configuration error listings make the abstract dense,浪费字数, and force readers to parse precision they can't evaluate at the skim stage. Journal of Computational Physics abstracts几乎不使用 mean ± std；半定量或定性对比是惯例。

**Patterns to flag:**

| Pattern | Example | Fix |
|---------|---------|-----|
| mean ± std | `$0.065\pm0.006$` | Replace with comparative semi-quantitative claim, e.g. "reducing error by up to 45%" |
| Multi-config value listing | Listing error for every Re target | Pick the most representative benchmark; mention the rest qualitatively ("consistent across all shift magnitudes") |
| Raw numbers as lead finding | "LoRA achieves 0.065 vs 0.103" | Lead with insight ("LoRA systematically outperforms full fine-tuning"), not the digits |
| **Pure data dump — missing insight** | "从头训练误差2.31×10⁻³，全微调1.07×10⁻³，LoRA为1.12×10⁻³" | Add interpretive framing: which method is better, by how much, and what's the takeaway |

**Detection test for Pure data dump:** Delete every number from the abstract. If the remaining text cannot convey what was found (no thesis, no comparison direction, no takeaway), the abstract is a pure data dump. Numbers in abstracts must illustrate a claim, not substitute for one.

**Rule of thumb:** If moving a number from the abstract into a body table would not change the abstract's message, that number is too detailed for the abstract.

**Acceptable abstract content:**
- Single representative metric with context: "up to 45% error reduction", "two orders of magnitude improvement"
- Scope-defining counts: "23–25% trainable parameters", "9–48 effective modes"
- Comparative claims: "systematically outperforms", "markedly lower variance", "接近减半的误差"
