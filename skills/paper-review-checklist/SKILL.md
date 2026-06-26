---
name: paper-review-checklist
description: |
  Comprehensive SCI manuscript final review checklist. 27 items across 6 groups,
  ordered by reviewer priority. Use when: final review of first draft is needed,
  paper-structure-coach delegates to this skill for the checklist portion.
  Do NOT use for: initial drafting, section expansion, or brainstorming.
  Triggers on "final review", "checklist", "review checklist", "paper checklist".
allowed-tools: Read, Grep, Glob, Write
---

# Paper Review Checklist

Items ordered by reviewer priority (descending). Each item flagged requires a concrete fix recommendation.

## Logic & Argumentation

- [ ] Complete闭环 from introduction gap → method countermeasure → result support → discussion interpretation
- [ ] Each paragraph has a clear topic sentence (first sentence summarizes paragraph主旨)
- [ ] Logical transitions between paragraphs, not abrupt jumps
- [ ] Conclusions correspond one-to-one with results; no exaggeration or unsubstantiated claims
- [ ] [Introduction Background only] When citing others' contributions, use "Author(s) → verb → specific contribution" format (e.g., "Raissi proposed PINNs", not just "PINNs [6]")

## Language & Expression

- [ ] Correct tense usage (established knowledge → present simple; this work → past simple; discussion implications → present simple / modal verbs)
- [ ] No emotional modifiers (novel / first / excellent / groundbreaking, etc.)
- [ ] Appropriate hedging (suggest / indicate / may / likely, not prove / demonstrate)
- [ ] No inappropriate anthropomorphism: avoid verbs of conscious intention (think / believe / want / hope / try / consider) with inanimate subjects. Accepted conventions: "Fig. 2 shows", "results indicate", "this paper proposes"
- [ ] No meta-discourse filler ("In this paper, we will study…" should be replaced with specific statements)
- [ ] Abstract uses descriptive magnitude (drastically / significantly / substantially) rather than precise numerical thresholds for claims

## Citations & Academic Standards

- [ ] Every non-common-knowledge statement supported by a citation
- [ ] No citation of unpublished sources (arXiv preprints subject to journal policy)
- [ ] Citations placed accurately — support the claim in the current sentence, not loosely at paragraph end

## Figures & Tables

- [ ] All figures/tables cited in text, consecutive numbering
- [ ] Captions are self-contained paragraphs (standalone — reader understands the figure without reading the main text)
- [ ] Data in figures/tables has corresponding interpretation in text (not流水账 "Fig. 1 shows A, Fig. 2 shows B")
- [ ] No verbatim duplication of table data in the narrative (summarize insight, not numbers)
- [ ] Axes labeled with variable names and units; decimal points aligned
- [ ] Keep ≤5 main tables+figures; move excess to supplementary materials
- [ ] Colorblind-safe palette preferred

## Grammar & Mechanics (flag for author revision, not auto-fix)

- [ ] Allow to / Enable to — always takes a direct object: "allows **us** to", "enables **researchers** to" (see `references/allow_enable_guide.md`)
- [ ] Respectively — two lists of equal length, one-to-one mapping only (see `references/respectively_guide.md`)
- [ ] UK/US spelling consistent throughout (see `references/uk_us_spelling.md`)
- [ ] Abbreviations defined at first use in both abstract AND main text; ≤5 non-standard abbreviations (see `references/abbreviation_guide.md`)
- [ ] No colloquial expressions, no rhetorical questions, no exclamation marks

## Pre-Submission Final Check

- [ ] SOCO (single take-home message) identifiable from title + abstract + Discussion opening
- [ ] Title concise, informative, not overpromising (no "comprehensive," "first," "novel" in title)
- [ ] Spell check run
- [ ] Let draft rest 1–2 days, re-read with fresh eyes
- [ ] Confirm journal-specific formatting requirements met

## Output Format

For each flagged item, follow this pattern:

```
❌ [Checklist item]
   → **Problem**: One-sentence specific observation
   → **Fix**: Concrete change to make (with example)
```

## Supporting References

Reference files in `references/` are loaded on-demand:
- `references/active_vs_passive.md` — Active vs. passive voice guide
- `references/redundant_phrases.md` — Redundant word pairs, nominalization table
- `references/respectively_guide.md` — Respectively correct usage
- `references/allow_enable_guide.md` — Allow/Enable object rule
- `references/abbreviation_guide.md` — Abbreviation management
- `references/article_usage.md` — a/an/the rules
- `references/countable_uncountable.md` — Countable/uncountable noun errors
- `references/uk_us_spelling.md` — UK vs US spelling table

## Review Output Examples

### Introduction CARS Review

```
✅ Move 1 (Establishing territory): Good centrality claims with adequate citations.
⚠️ Move 2 (Establishing niche): Stays at phenomenon level ("not accurate enough"),
   not mechanism (gradient vanishing? expressivity limit?).
❌ Move 2 → Move 3: Missing bridging sentence. Add "To address these limitations, …"

Priorities: 1) Mechanism-level gap analysis  2) Transition sentence
```

### Language Review

```
❌ "It is worth noting that the model converges faster."
   → Remove lead-in: "The model converges faster than the baseline."

❌ "This paper demonstrates that LoRA outperforms full fine-tuning."
   → Hedge: "Our results indicate that LoRA achieves competitive accuracy…"

❌ "We conducted an analysis of the convergence behavior."
   → Active verb: "We analyzed the convergence behavior."
```

### Logic Chain Check

```
Gap: "PEFT in PINNs lacks systematic evidence for physics parameter transfer"
  → Method: Controlled protocol for Burgers AND Advection
  → Results: Multi-seed evidence for LoRA/Adapter under two PDE types
  → Discussion: Rank requirement connected to ΔRe/Re_s scaling hypothesis
✅ Complete闭环.
⚠️ "Several limitations" as subheading → integrate naturally.
```
