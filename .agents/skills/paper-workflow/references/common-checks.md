# Common Checks

Load these for **content audit** and **final review** phases. Each check is described below with detection heuristics and fixes.

---

## Overclaim Check

Review every claim against the evidence supporting it.

| Only have | Most aggressive acceptable wording |
|-----------|-----------------------------------|
| 1 data point | "preliminary indication", "requires validation" |
| 2-3 data points | "indicates", "qualitatively consistent with" |
| Multiple independent replicates | "suggests", "exhibits" |
| Rigorous theoretical derivation | "proves", "establishes" |

**High-risk phrases to flag:**

| Category | Examples |
|----------|----------|
| Absolute | "决定了", "本质上", "必然" → "很大程度上影响", "在...条件下" |
| Overclaimed math | "严格的证明", "数学本质" → "理论依据", "关键机制" |
| Grand assertions | "奠定理论基石", "开创性" → "提供理论支撑", "重要进展" |
| Emotional | "令人惊讶", "反直觉" → direct statement |

**Banned words** (automatic fail): "novel", "groundbreaking", "first-ever", "unprecedented", "revolutionary".

---

## Defensive Language Check

Every sentence should start with substantive content, not a safety buffer.

**Types to flag:**
- Empty lead-ins: "值得注意的是", "It is worth noting that…" → delete
- Self-evident: "众所周知", "As is well known…" → delete unless citation needed
- Hedging filler: "某种程度上", "It seems that…" → quantify or delete
- Meta-commentary: "需要强调的是", "This section discusses…" → delete
- Over-apologizing: "据我们所知", "To the best of our knowledge…" → once per paper max

**Rule of thumb:** Delete the first 5-10 words — if the sentence still makes sense, those words were defensive padding.

---

## Subjective Qualifier Check (主观修饰语检测)

JCP values factual, neutral register. Subjective qualifiers express the author's opinion rather than providing information, and dilute the objectivity of scientific writing. Unlike the Overclaim Check (which flags exaggerated claims about results), this check targets empty modifiers on neutral statements — words that tell the reader "this is important/big/significant" without evidence.

**Detection patterns (grep targets):**

| Word | Problem | Fix guidance |
|------|---------|-------------|
| 可观的 | subjective size/cost judgment | delete or replace with factual description (e.g., "额外开销" not "可观开销") |
| 实质性 | empty substance claim | delete unless quantified ("实质性收益" → "可降低...") |
| 较为 | hedging qualifier | delete (use the bare adjective: "有限" not "较为有限") |
| 一定程度 / 一定程度的 | vague quantification | delete or replace with actual numbers |
| 重要的 | subjective importance (when unsupported) | delete unless backed by citation or evidence |
| 显著的 / 明显的 | subjective magnitude (no ±/p-value) | delete unless statistical test is reported |
| 非常 + adjective | empty intensifier | delete; let the adjective stand alone |
| 极其 + adjective | empty intensifier | same as above |
| 很大的 / 极大的 | vague size claim | replace with measured value or delete |
| 严重的 | subjective severity | replace with factual description or delete |

**Real before/after examples (from this paper's own revision):**

| Before | Issue | After |
|--------|-------|-------|
| 构成**可观**开销 | subjective judgment of cost | 均需额外开销 |
| 提供**实质性**收益 | empty substance claim | 可降低训练的内存占用 |
| **重要**规律 | subjective importance | 规律 |
| **较为**有限 | hedging qualifier | 有限 |

**Rule of thumb:** A subjective qualifier can be removed if answering "compared to what?" or "by what measure?" yields no specific answer from the paper. If the sentence still makes sense without the qualifier, delete it.

**Edge cases — DO NOT flag:**
- "重要" when backed by specific evidence (e.g., "重要任务之一" with citation cluster, "重要进展" referenced from prior work)
- Factual descriptions with data support: "高度吻合" with error bars, "高度相关" with correlation coefficient, "高度集中" with quantified distribution — these are factual, not subjective
- "关键" as a technical term: "关键路径", "关键帧", "关键参数" (when it has a technical definition)
- "显著" in formal statistical reporting: "显著高于对照组 (p<0.05)" — requires p-value or effect size
- "重要" in "不重要" / negation — the negation is the information, not the qualifier

---

## Padding Audit (死重大扫除)

Flag content that takes up space without adding information value. Read each section looking for:

1. **Redundant restatement** — the same point made twice or more (e.g., the same literature gap stated at lines 31-38 and again at 94-96). Merge or delete.

2. **Over-explained standard technique** — full derivation of well-known methods that can be covered by a citation + one sentence. E.g., writing 30 lines of Fourier feature theory (NTK eigenvalue decay, Bochner theorem) when the citation `tancik2020fourier` suffices. For a methods paper this wastes space a reader will skip.

3. **Orphaned argument** — a paragraph that starts a two-point structure ("第一...") but the second point never arrives, leaving a dead fragment.

4. **Caption-only results** — paragraphs that describe what tables/figures already show without adding interpretation. The data speaks for itself; if the paragraph doesn't add "why" or "so what", delete or merge.

5. **Expansible-to-minimize paragraphs** — content that takes 3+ sentences saying what 1 sentence covers (e.g., a statistical caution paragraph that repeats what the preceding sentence implies). Collapse.

6. **Repeated mechanism storytelling** — the same mechanistic metaphor (e.g., "错误的扰动方向", "低秩门控") appearing in results AND discussion. Say it once, not twice.

**Rule of thumb after each section:** "If I deleted this paragraph, would a reader miss a necessary piece of information?" If no, cut it.

---

## Self-Triggering Defense Check (自我引爆检测)

Flag patterns where the paper proactively raises a weakness about its OWN methodology or experimental choices (trigger), then defends against it.

**Why it's harmful:** A reviewer reads to evaluate your claims, not to find flaws in your design. When you say "our X is too high" you're doing the reviewer's job — and they may not accept your subsequent defense. State parameters neutrally and let the work speak for itself.

**Pattern signature in Chinese:**

| Component | Markers |
|-----------|---------|
| **Trigger** — value judgment about own choice | "偏高/偏低/不足/局限/有待改进" |
| **Trigger** — raises a problem frame | "由此产生一个XX问题" |
| **Defense** — "but" justification | "但/然而/由于...不影响/不改变" |
| **Defense** — redirect to fairness | "重点在于..." |

**Detection heuristic:** A paragraph that: (1) states a fact about own setup, (2) adds a value judgment, (3) explains why it's OK — is suspicious. If removing step (2) leaves the paragraph coherent, delete step (2).

**Critical gate:** If the paragraph has NO step (3) — no "但/然而/尽管如此/不影响/不改变结论" defense — then it is NOT self-triggering, regardless of whether steps (1) and (2) are present. A limitation statement without a defense is just an honest limitation. Do NOT flag it.

**Real before/after examples (from this paper's own revision):**

| Before | After |
|--------|-------|
| 阻塞比 D/H=20\%，\*\*该阻塞比在CFD基准中偏高\*\*。...\*\*但\*\*阻塞效应不影响跨基准一致性 | 阻塞比 D/H=20\%，阻塞效应使尾迹回流区缩短...且受控比较独立进行，不影响结论 |
| \*\*由此产生一个方法学问题：\*\*LoRA的有效性是否依赖于源参数？\*\*本文虽未开展系统扫描，但\*\*以下三点构成间接证据 | 以下三点间接证据支持结论对该源参数选择的稳健性 |
| \*\*各2D实验采用与1D实验不同的\*\*网络架构，\*\*因为\*\*...\*\*重点在于\*\*同一实验共享backbone | 1D实验采用X配置，2D实验采用Y配置。各实验内方法共享backbone |

**Edge cases — NOT self-triggering:**
- Honest limitation without defense (陈述局限后直接接未来工作，没有"但不影响"类的辩护)
- "虽然...但" comparing to *others' work* (e.g., "F-Adapter 虽基于 FNO，但本文 PINN 结构不同")
- Standard literature gap statements in introduction

**Root diagnostic test for hard cases:** Ask two questions in order:
1. Is there a **defense structure** — a "但/然而/尽管如此/不影响/不改变结论" clause that explicitly neutralizes a weakness? If NO → not self-triggering (it's just a limitation or observation).
2. Does the "future work" / "有待" sentence replace a missing "但不影响" defense? If YES → not self-triggering. "可作为未来工作" is not a defense; it's an honest scope statement.

**Explicit counterexamples (NOT self-triggering):**
| Incorrect trigger reading | Why it's NOT self-triggering | Correct classification |
|---|---|---|
| "本实验仅在 Re=20 单一源参数上进行了预训练。在更多源参数上的系统性扫描可作为未来工作" | "仅在"是事实性限定而非价值判断；"可作为未来工作"是未来方向，不是"但不影响"类辩护 | PASS — 诚实的局限陈述 |
| "本文在 Advection 和 Burgers 两个一维问题上验证了方法的有效性，在更多 PDE 类型上的验证有待后续研究" | 同模式：事实陈述 + 未来方向，无辩护结构 | PASS — 诚实的局限陈述 |

---

## Fabricated Experiment Audit (虚假实验声明)

Flag claims that sound like experimental findings but are actually speculation. This is the single most dangerous class of error — it survived the Overclaim Check (which only checks word strength) and was the exact pattern we discovered in the deleted gradient checkpointing paragraph.

Read every quantitative or mechanistic claim and ask: "Did we actually measure this?"

**High-risk patterns:**

| Pattern | Looks like | But actually | Flagged example |
|---------|-----------|--------------|-----------------|
| "实验上" + numbers | Experimental data | No experiment was run | "实验上...显存占用降至约60%" — deleted |
| Mechanism story | Causal explanation | Post-hoc speculation | "优化景观更加崎岖...部分种子陷入较差局部极小" — no landscape measured |
| Theory → conclusion | Derived result | Unvalidated for this setting | "3D NS 中 backbone 参数量达 10^6-10^7 时..." — paper has no 3D experiment |
| "显著" without ± | Quantitative claim | No measurement | "Hessian 病态传播显著升高梯度流条件数" — no condition number measured |
| "因为" mechanism | Causal finding | Observational correlation | "LoRA 的低秩门控截断了有害扰动路径" — no weight trajectory analysis |
| "实验发现" | Experimental result | Actually citing others | "纯 PINN 在该问题中发散" — not our experiment, just citing reference |

**Rule of thumb:** For every quantified claim, trace to its source data. If you can't point to a specific table cell, figure panel, or measurement script, the claim is unsupported.
