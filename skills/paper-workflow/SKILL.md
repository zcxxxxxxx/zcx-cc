---
name: paper-workflow
description: |
  Full academic paper lifecycle: IMRaD structure coaching + 27-item final review
  checklist. Activate when: drafting a new paper, reviewing manuscript structure,
  expanding a specific section, organizing experimental data, OR doing a final
  review of a first draft. Also use whenever ARS academic-research-skills paper
  writing or review skills (ars-full, ars-revision, ars-plan, ars-outline,
  ars-lit-review, sci-paper-reviewer) are invoked.
  Make sure to use this skill whenever the user mentions paper structure, IMRaD,
  manuscript review, SCI submission, "终审", "检查清单", organizing a draft,
  or wants a review checklist — even if they don't explicitly ask for a
  "structure review" or "checklist."
  Do NOT use for: reference formatting, image resolution adjustment, or grammar
  proofreading outside of a final review context.
allowed-tools: Read, Grep, Glob, Write, Edit
---

# Paper Workflow

## Phase Detection

Determine which phase the user is in:

| Phase | Trigger phrases | Action |
|-------|----------------|--------|
| **Structure coaching** | "规划结构", "IMRaD", "章节怎么安排", "帮我展开方法部分", drafting, outlining, reviewing structure | Read `references/structure-coach.md` and apply its guidance |
| **Final review** | "终审", "帮我检查一遍", "checklist", "review checklist", "论文检查清单", "final review", "最后检查" | Read `references/review-checklist.md` and apply its 27-item checklist. **READ-ONLY mode** — do NOT edit the paper files, only produce a review report |
| **Full workflow** | User has a rough draft and wants the entire pipeline | Start with `references/structure-coach.md` for structural diagnosis, then once structural issues are resolved, load `references/review-checklist.md` for final check |

When unsure, ask: "你是在规划论文结构阶段，还是已经写完初稿需要终审检查？"

## Common Checks (apply in all phases)

These checks are loaded automatically — apply them regardless of phase.

### Overclaim Check

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

### Defensive Language Check

Every sentence should start with substantive content, not a safety buffer.

**Types to flag:**
- Empty lead-ins: "值得注意的是", "It is worth noting that…" → delete
- Self-evident: "众所周知", "As is well known…" → delete unless citation needed
- Hedging filler: "某种程度上", "It seems that…" → quantify or delete
- Meta-commentary: "需要强调的是", "This section discusses…" → delete
- Over-apologizing: "据我们所知", "To the best of our knowledge…" → once per paper max

**Rule of thumb:** Delete the first 5-10 words — if the sentence still makes sense, those words were defensive padding.

## Reference Files

- `references/structure-coach.md` — Load when doing structure planning/review
- `references/review-checklist.md` — Load when doing final review checklist
- Section-specific conventions (abstract, introduction, methods, etc.) — loaded on demand from `references/`
- Grammar guides (abbreviation, active/passive, etc.) — loaded on demand from `references/`

## Boundaries

- Structure coaching: structural planning and content review (not grammar proofreading)
- Final review: read-only checklist output (do not edit paper files)
- For paper revision after checklist concerns are identified, use the relevant ARS skill
