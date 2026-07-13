# Punctuation Convention Check (标点惯例检查)

Flag non-standard punctuation throughout the paper — particularly em-dashes (—) used as a connective device, which are rare in JCP.

## Why it matters

JCP papers use conservative punctuation. A survey of 4 2024 JCP PINN papers found zero em-dashes in any abstract, and em-dashes are infrequent in body text. Commas, semicolons, parentheses, and clause restructuring are the expected devices for connecting ideas. Em-dashes read as informal or journalistic, drawing attention to the punctuation rather than the content.

## Core principle: do NOT just swap the punctuation mark

Em-dashes carry semantic load — they signal elaboration, causation, result, definition, or enumeration. Removing the dash without adding a connective word leaves the sentence disjointed. Each fix must restructure the sentence with an appropriate connective that rebuilds the logical relationship the em-dash was carrying.

### Chinese function → connective mapping

| Function | —— pattern | Fix | Connective |
|----------|-----------|-----|------------|
| Elaboration | `A——B` (B explains A) | `A。具体而言，B` | 具体而言 / ；即 / 冒号(仅短同位) |
| Cause | `A——B` (B is reason) | `A，因为B` | 因为 |
| Result | `A——B` (B is consequence) | `A，因此B` | 因此 / 这意味着 |
| Definition | `A型变化——B不变` | `A型变化。此时B不变` | 此时 / ，即 |
| Enumeration | `重启——A、B、C` | `重启，涉及A、B、C` | 涉及 / 包括 |

### English function → connective mapping

| Function | — pattern | Fix | Connective |
|----------|-----------|-----|------------|
| Parenthetical insert | `A — unlike B — C` | `A, unlike B, C` | commas (not dashes) |
| Elaboration | `A — B` (B specifies A) | `A: B` / `A, specifically B` | colon / specifically / namely |
| Cause | `A — B` (B is reason) | `A, because B` / `A; B` | because / since |
| Result | `A — B` (B is consequence) | `A; therefore B` / `A, meaning B` | therefore / meaning / which implies |
| Contrast | `A — B` (B contrasts A) | `A, whereas B` / `A, while B` | whereas / while / although |
| Emphasis | `A is — surprisingly — B` | `A is B, which is surprising` | trailing clause (not dash pair) |

### Real before/after (from actual revision)

```
BEFORE (direct punctuation swap — reads poorly):
  求解过程通常需要重新启动：重新划分网格、组装矩阵、迭代求解
  → 冒号使列举悬空，读感停滞

AFTER (connective word bridges the semantic gap):
  求解过程通常需要重新启动，涉及重新划分网格、组装矩阵、迭代求解
  → "涉及"补上列举与"重新启动"之间的语义关联
```

```
BEFORE:
  具有特别的意义：继承源权重可大幅缩短目标优化路径

AFTER:
  具有特别的意义，因为继承源权重可大幅缩短目标优化路径
  → "因为"显式标注因果链
```

```
BEFORE:
  涉及高阶导数路径：低秩修正不仅影响u_θ，还会…进而…

AFTER:
  涉及高阶导数路径。具体而言，低秩修正不仅影响u_θ，还会…进而…
  → 断为两句，"具体而言"标记展开
```

```
BEFORE (commas-only):
  目标迁移需调整K个模式，至少需秩K

AFTER:
  目标迁移需调整K个模式，因此至少需秩K
  → "因此"补上推论关系
```

## Detection heuristic

Search for `---` (LaTeX triple hyphen → em-dash) or `——` (Chinese double em-dash) in .tex files.

For each instance:
1. Identify the **function** of the em-dash (elaboration? cause? result? definition? enumeration? aside? emphasis?)
2. Choose the appropriate **connective word** from the mapping table above
3. Restructure the sentence with the connective word
4. Do NOT simply swap `——` for `：` or `——` for `,` — that produces ungrammatical flow

## Edge cases

- **En-dashes** (`--` in LaTeX) for numerical ranges ("23--25%", "9--48 effective modes") — standard JCP convention. Do NOT flag.
- **Hyphens** in compound words ("physics-informed", "high-dimensional") — standard. Do NOT flag.
- **Direct quotations** that contain em-dashes — leave unchanged.

## Per-section details

For section-specific patterns, examples, and detection rules, load the corresponding file:

| Section | File |
|---------|------|
| Abstract | `references/abstract-punctuation.md` |
| Introduction | `references/introduction-punctuation.md` |
| Methods | `references/methods-punctuation.md` |
| Results | `references/results-punctuation.md` |
| Discussion | `references/discussion-punctuation.md` |
| Conclusions | `references/conclusions-punctuation.md` |
