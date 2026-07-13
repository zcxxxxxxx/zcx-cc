# Introduction Convention Check

## Introduction Quantitative Check (引言定量检查)

Flag introductions that contain overly detailed quantitative results (mean ± std, per-configuration error listings, raw accuracy/error numbers across multiple settings) that belong in tables in the body.

**Why it matters:** An introduction communicates the problem, gap, and qualitative nature of the contribution — not the precise error numbers. Detailed ± listings force readers to parse precision they cannot evaluate at the overview stage. In JCP papers, the introduction frames the contribution qualitatively; quantitative evidence goes in Results with table references. Dense numbers in the introduction also make the text harder to read — the reader must switch between narrative and data-parsing modes repeatedly, a cognitive burden that erodes the rhetorical flow of the contribution argument.

**Patterns to flag:**

| Pattern | Example | Fix |
|---------|---------|-----|
| mean ± std in introduction | `圆柱绕流中 LoRA r16 在 $Re=40$ 下误差 $0.065\pm0.006$，全参数微调为 $0.103\pm0.046$` | Replace with qualitative comparison + table reference: `圆柱绕流中 LoRA r16 在两档雷诺数偏移下误差均约为全参数微调的一半（表~\ref{tab:master}）` |
| Multi-config value listing | Listing error for every Re target, two methods × two shifts | Pick the most representative comparison; mention the rest as "consistent across all shift magnitudes" |
| Raw numbers as lead finding | "LoRA achieves 0.065 vs 0.103" | Lead with the insight and direction: "LoRA systematically outperforms full fine-tuning" |
| Pure data dump | Error for every PDE, method, and shift combination | Summarize into 1–2 comparative claims that convey the *pattern*, not the digits |

**Rule of thumb:** If a number can be moved to a table in §Results without changing the introduction's message, it should be. The introduction should tell the reader *what* you found and *why it matters* — the exact numbers are evidence for later.

**Detection test:** Read the introduction and ask: "If I removed every ± and every per-configuration number, would the contribution still be clear?" If yes, those numbers are too detailed for the introduction.
