---
name: paper-workflow
description: |
  Full academic paper lifecycle: IMRaD structure coaching + content audit
  (dead-weight removal + fabricated-claim detection) + 27-item final review
  checklist. Activate when: drafting a new paper, reviewing manuscript structure,
  expanding a specific section, organizing experimental data, doing a content
  audit for padding or unsubstantiated claims, OR doing a final review of a first
  draft. Also use whenever ARS academic-research-skills paper writing or review
  skills (ars-full, ars-revision, ars-plan, ars-outline, ars-lit-review,
  sci-paper-reviewer) are invoked.
  Make sure to use this skill whenever the user mentions paper structure, IMRaD,
  manuscript review, SCI submission, "终审", "检查清单", "审计内容", "死重",
  "padding", "虚假声明", "不产生收益", "未经实验但写实验说明", organizing a
  draft, or wants a review/audit checklist — even if they don't explicitly ask
  for a "structure review" or "checklist."
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
| **Content audit** | "审计内容", "死重", "padding", "虚假声明", "不产生收益", "未经实验但写实验说明", "占篇幅" | Load `references/common-checks.md` per the Reference Loading Guide below. **READ-ONLY mode** — produce audit report, do NOT edit files |
| **Final review** | "终审", "帮我检查一遍", "checklist", "review checklist", "论文检查清单", "final review", "最后检查" | Load ALL references per the Reference Loading Guide below (common-checks + all section conventions + review-checklist). **READ-ONLY mode** — do NOT edit the paper files, only produce a review report |
| **Full workflow** | User has a rough draft and wants the entire pipeline | Start with `references/structure-coach.md` for structural diagnosis, then once structural issues are resolved, apply Content audit, then load `references/review-checklist.md` for final check |

When unsure, ask: "你是在规划论文结构阶段，还是已经写完初稿需要终审检查？"

## Reference Loading Guide

This skill modularizes its checks into per-section reference files. Load only what you need based on the phase and specific section being reviewed.

### Phase-based loading

| Phase | Load these references |
|-------|----------------------|
| **Content audit** | `references/common-checks.md` — Overclaim, Defensive Language, Padding, Self-Triggering, Fabricated Experiment |
| **Final review** | ALL: `common-checks.md` + `abstract-conventions.md` + `introduction-conventions.md` + `punctuation-conventions.md` + `review-checklist.md` + per-section punctuation files as triggered by issues |
| **Structure coaching** | `references/structure-coach.md` only |
| **Punctuation audit** (any section) | `references/punctuation-conventions.md` (global) + the relevant section-specific punctuation file below |

### Section-specific loading

| Target section | Structural conventions | Punctuation conventions |
|----------------|----------------------|------------------------|
| Abstract | `references/abstract-conventions.md` | `references/abstract-punctuation.md` |
| Introduction | `references/introduction-conventions.md` | `references/introduction-punctuation.md` |
| Methods | — | `references/methods-punctuation.md` |
| Results | — | `references/results-punctuation.md` |
| Discussion | — | `references/discussion-punctuation.md` |
| Conclusions | — | `references/conclusions-punctuation.md` |

### Quick reference — what each file covers

- `references/common-checks.md` — 6 checks: overclaim, defensive language, subjective qualifier, padding, self-triggering defense, fabricated experiment
- `references/abstract-conventions.md` — 4 structural rules (continuous prose, no limitations, no "本文", no standalone prior-work) + quantitative check
- `references/introduction-conventions.md` — quantitative check (no mean±std or per-configuration listings)
- `references/punctuation-conventions.md` — **global**: detection heuristic, core principle (no direct swap!), CN+EN function→connective mapping, edge cases
- `references/abstract-punctuation.md` — abstract-specific em-dash: zero tolerance, CN+EN fix patterns
- `references/introduction-punctuation.md` — introduction-specific em-dash: elaboration/cause/definition/enumeration patterns
- `references/methods-punctuation.md` — methods-specific em-dash: enumeration/parenthetical patterns
- `references/results-punctuation.md` — results-specific em-dash: result/contrast patterns
- `references/discussion-punctuation.md` — discussion-specific em-dash: conclusion/alternative patterns
- `references/conclusions-punctuation.md` — conclusions-specific em-dash: minimal, same as discussion
- `references/review-checklist.md` — 27-item final review checklist

## Reference Files (writing conventions — section-specific)

- `references/structure-coach.md` — Load when doing structure planning/review
- `references/review-checklist.md` — Load when doing final review checklist
- Section-specific conventions (abstract, introduction, methods, etc.) — loaded on demand from `references/`
- Grammar guides (abbreviation, active/passive, etc.) — loaded on demand from `references/`

## Boundaries

- Structure coaching: structural planning and content review (not grammar proofreading)
- Content audit: read-only audit report (do not edit paper files)
- Final review: read-only checklist output (do not edit paper files)
- For paper revision after audit/checklist concerns are identified, use the relevant ARS skill
