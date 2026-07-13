# Methods Em-Dash Convention

Methods sections use em-dashes primarily for enumeration and parenthetical inserts. The formal register of a methods section makes em-dashes particularly noticeable — a single em-dash in a 300-line methods section is one too many.

## Chinese patterns

| —— function | Fix | Before | After |
|-------------|-----|--------|-------|
| Enumeration | `，涉及` / `，包括` | `损失包括三项——PDE、IC、BC` | `损失包括三项，涉及PDE、IC、BC` |
| Elaboration | `。具体而言` / `：` | `AD图深度由M决定——前向需遍历所有层` | `AD图深度由M决定，前向需遍历所有层` |

## English patterns

| — function | Fix | Before | After |
|------------|-----|--------|-------|
| Parenthetical | commas | "the operator — denoted D — acts on u" | "the operator, denoted D, acts on u" |
| Elaboration | colon | "three loss terms — PDE residual, IC, BC" | "three loss terms: PDE residual, IC, and BC" |
| Result | "therefore" / "hence" | "M=2 for Burgers — AD graph has depth 4C" | "M=2 for Burgers; hence the AD graph has depth 4C" |
