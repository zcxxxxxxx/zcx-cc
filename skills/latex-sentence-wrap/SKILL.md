---
name: latex-sentence-wrap
description: >-
  Enforce "one sentence per line" with ~80 char limit on .tex files.
  Handles Chinese/English mixed text, CJK punctuation boundaries, math mode
  protection ($$...$$, \[...\]), citation protection (\cite{},\ref{},\label{}),
  and LaTeX environment detection (figure, table, equation, align, etc.).
  Use this skill whenever the user mentions LaTeX formatting, sentence-per-line
  line wrapping, fixing awkward line breaks in Chinese/English LaTeX, 80-char
  limits on .tex files, "每句换行", or pre-commit LaTeX formatting.
  Activate even for casual phrasing like "format my .tex files" or "fix the
  line breaks" — this is the dedicated tool for imposing consistent
  line-breaking on LaTeX source.
---

# LaTeX Sentence Wrap

Enforce "one sentence per line" with an ~80 character limit on `.tex` files.
Handles Chinese/English mixed documents, LaTeX commands, math mode, and
protected environments. Idempotent — safe to re-run on already-wrapped files.

## When to Use

- User mentions formatting `.tex` files with sentence-per-line
- User wants 80-char line limit on LaTeX source
- User says "每句换行" or "换行" in context of LaTeX
- User reports awkward line breaks in Chinese/English LaTeX
- User wants to check or audit .tex file formatting
- Pre-commit hook or CI for LaTeX source formatting

## Bundled Scripts

Two scripts live in the skill's `scripts/` directory. Reference them via
`$CLAUDE_SKILL_DIR` so they work regardless of which project you're in.

### `scripts/wrap_tex.py` — Main wrapping script

Processes `.tex` files **in-place**. Accepts multiple file paths.

```bash
python "$CLAUDE_SKILL_DIR/scripts/wrap_tex.py" file1.tex file2.tex ...
```

**How the algorithm works:**

1. **Paragraph reconstruction** — joins paragraph lines into continuous text
   (strips internal newlines from previous wrapping so position counts are
   accurate).

2. **Placeholder protection** — replaces `$...$`, `\[...\]`, `\cite{...}`,
   `\ref{...}`, `\label{...}` and `\eqref{...}` with short tokens so they
   aren't split mid-command.

3. **Sentence splitting** — splits at Chinese sentence endings (`。！？`) and
   English sentence endings (`.!?` followed by a capital letter or LaTeX
   command). Detects abbreviations (`et al.`, `Fig.`, `Dr.`, months, etc.) to
   avoid false splits.

4. **Phrase-level splitting** — for lines still > 80 chars, finds the
   rightmost break point before 80, in this priority order:
   - `；：;:` (semicolons and colons)
   - `，、` (Chinese comma and enumeration comma)
   - `)）】』〕》」` (closing brackets)
   - `,` (ASCII comma)
   - Space-based or CJK-safe character split (fallback)

5. **Post-processing loop** — after restoring placeholders, any line that
   grew beyond 80 chars (e.g. a restored `\cite{...}` adds length) gets
   re-split iteratively until all lines comply.

**Edge cases handled:**
- Em-dashes (`——`) are NOT split points (they connect thoughts)
- Chinese words are never split mid-character (CJK-safe fallback)
- Environments detected and preserved: figure, table, equation, align,
  itemize, enumerate, verbatim, thebibliography, tikzpicture, etc.
- `\item` content: wraps text while accounting for the `\item` prefix width
- `\caption` content: wraps only the caption text, preserving braces

### `scripts/check_lines.py` — Audit script

Reports lines exceeding 80 chars with line numbers, lengths, and available
break characters. Silent (OK) exit for clean files.

```bash
python "$CLAUDE_SKILL_DIR/scripts/check_lines.py" file1.tex file2.tex ...
```

## Workflow

```bash
# 1. (Optional) Check current state
python "$CLAUDE_SKILL_DIR/scripts/check_lines.py" paper/*.tex

# 2. Apply wrapping
python "$CLAUDE_SKILL_DIR/scripts/wrap_tex.py" paper/*.tex

# 3. Verify results
python "$CLAUDE_SKILL_DIR/scripts/check_lines.py" paper/*.tex

# 4. Verify compilation (tool-specific)
# pdflatex manuscript.tex && bibtex manuscript && pdflatex manuscript.tex
```

## Known Limitations

- **Math-heavy lines**: Long inline math (e.g. `\gamma(\mathbf{x}) =
  \begin{bmatrix}...`) cannot be split without breaking LaTeX. These remain
  as-is.
- **Single long citations**: Lines with a `\cite{...}` containing many
  references may exceed 80 chars. Acceptable — citations are not readable
  text.
- **`\texttt{...}` and `\textit{...}`**: Text inside these commands is NOT
  protected. If they span lines, wrapping may interact unexpectedly.
- **Comment-only lines**: Lines starting with `%` are preserved verbatim.

## Communication with User

When the user requests LaTeX formatting:
1. **Confirm scope** — which files to process
2. **Audit first** — run `check_lines.py` to show the current state
3. **Wrap** — run `wrap_tex.py` on the target files
4. **Verify** — run `check_lines.py` again to confirm the result
5. **Note math lines** — if some math-heavy lines remain > 80 chars, explain why
6. **Suggest compile check** — recommend verifying LaTeX still compiles

When the user reports specific break-point problems (e.g. "这个逗号这里换行不对"):
1. Read the problematic section of the file
2. Determine if it's a CJK punctuation boundary, em-dash, or mid-word issue
3. If it's a known limitation, explain why
4. If it's a genuine bug, note it and adjust the algorithm
