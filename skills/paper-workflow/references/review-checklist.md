# Paper Review Checklist — 27 项终审清单

Items ordered by reviewer priority (descending). Each item flagged requires a concrete fix recommendation.
Produces a read-only review report — do NOT edit the paper files directly.

## Logic & Argumentation

- [ ] Complete loop from introduction gap → method countermeasure → result support → discussion interpretation
- [ ] Each paragraph has a clear topic sentence (first sentence summarizes paragraph gist)
- [ ] Logical transitions between paragraphs, not abrupt jumps
- [ ] Conclusions correspond one-to-one with results; no exaggeration or unsubstantiated claims
- [ ] [Introduction Background only] When citing others' contributions, use "Author(s) → verb → specific contribution" format

## Language & Expression

- [ ] Correct tense usage (established knowledge → present simple; this work → past simple; implications → present simple / modal verbs)
- [ ] No emotional modifiers (novel / first / excellent / groundbreaking, etc.)
- [ ] Appropriate hedging (suggest / indicate / may / likely, not prove / demonstrate)
- [ ] No inappropriate anthropomorphism
- [ ] No meta-discourse filler ("In this paper, we will study…" → specific statement)
- [ ] Abstract uses descriptive magnitude rather than precise numerical thresholds for claims

## Citations & Academic Standards

- [ ] Every non-common-knowledge statement supported by a citation
- [ ] No citation of unpublished sources (arXiv preprints subject to journal policy)
- [ ] Citations placed accurately — support the claim in the current sentence

## Figures & Tables

- [ ] All figures/tables cited in text, consecutive numbering
- [ ] Captions are self-contained paragraphs
- [ ] Data in figures/tables has corresponding interpretation in text (not mere listing)
- [ ] No verbatim duplication of table data in narrative
- [ ] Axes labeled with variable names and units; decimal points aligned
- [ ] Keep ≤5 main tables+figures; move excess to supplementary materials
- [ ] Colorblind-safe palette preferred

## Grammar & Mechanics (flag for author revision, not auto-fix)

- [ ] Allow to / Enable to — takes a direct object (see `references/allow_enable_guide.md`)
- [ ] Respectively — two lists, one-to-one mapping only (see `references/respectively_guide.md`)
- [ ] UK/US spelling consistent (see `references/uk_us_spelling.md`)
- [ ] Abbreviations defined at first use in abstract AND main text; ≤5 non-standard (see `references/abbreviation_guide.md`)
- [ ] No colloquial expressions, no rhetorical questions, no exclamation marks

## Pre-Submission Final Check

- [ ] SOCO (single take-home message) identifiable from title + abstract + Discussion opening
- [ ] Title concise, informative, not overpromising
- [ ] Spell check run
- [ ] Let draft rest 1-2 days, re-read with fresh eyes
- [ ] Confirm journal-specific formatting requirements met

## Output Format

For each flagged item:

```
❌ [Checklist item]
   → **Problem**: One-sentence specific observation
   → **Fix**: Concrete change to make (with example)
```

## Grammar Reference Files (load on demand)

- `references/active_vs_passive.md` — Active vs. passive voice guide
- `references/redundant_phrases.md` — Redundant word pairs, nominalization table
- `references/respectively_guide.md` — Respectively correct usage
- `references/allow_enable_guide.md` — Allow/Enable object rule
- `references/abbreviation_guide.md` — Abbreviation management
- `references/article_usage.md` — a/an/the rules
- `references/countable_uncountable.md` — Countable/uncountable noun errors
- `references/uk_us_spelling.md` — UK vs US spelling table
