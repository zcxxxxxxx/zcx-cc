"""Wrap .tex files to sentence-per-line with 80-char hard limit."""
import re
import os
import sys

ABBREVIATIONS = {
    "e.g.", "i.e.", "et al.", "Fig.", "Eq.", "Ref.", "Sec.", "Ch.",
    "vs.", "ca.", "approx.", "dept.", "est.", "vol.", "no.",
    "Inc.", "Ltd.", "Co.", "Corp.",
    "Jan.", "Feb.", "Mar.", "Apr.", "Jun.", "Jul.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec.",
    "St.", "Mt.", "Dr.", "Mr.", "Ms.", "Mrs.", "Prof.", "Sr.", "Jr.",
    "cf.", "resp.",
}

ONE_LINE_COMMANDS = {
    r'\documentclass', r'\usepackage', r'\graphicspath', r'\setmainfont',
    r'\setCJK', r'\begin{document}', r'\end{document}',
    r'\section', r'\subsection', r'\subsubsection', r'\chapter', r'\paragraph',
    r'\title', r'\author', r'\affiliation', r'\shorttitle', r'\shortauthors',
    r'\cormark', r'\cortext', r'\ead', r'\maketitle',
    r'\input{', r'\bibliography', r'\bibliographystyle', r'\appendix',
    r'\label{', r'\bigskip', r'\medskip', r'\smallskip',
    r'\begin{', r'\end{',
}

PROTECTED_BLOCKS = {
    'figure', 'figure*', 'table', 'table*', 'tabular', 'tabulary',
    'verbatim', 'lstlisting', 'itemize', 'enumerate',
    'thebibliography', 'tikzpicture',
    'equation', 'equation*', 'eqnarray', 'eqnarray*',
    'align', 'align*', 'aligned', 'gather', 'gather*', 'multline', 'multline*',
}

MATH_BLOCKS = {'equation', 'equation*', 'eqnarray', 'eqnarray*',
               'align', 'align*', 'aligned', 'gather', 'gather*', 'multline', 'multline*'}

MAX_LINE = 80

PLACEHOLDER_PATTERNS = [
    (r'(\$[^\$]+\$)', 'MATH'),
    (r'(\\\[.*?\\\])', 'DISPMATH'),
    (r'(\\(?:ref|cite|label|eqref|autoref|pageref)\{(?:[^{}]*(?:\{[^{}]*\}[^{}]*)*)\})', 'REF'),
]


def protect_all(text, pmap):
    for pattern, ptype in PLACEHOLDER_PATTERNS:
        def make_protector(pt=ptype):
            c = [0]
            def _protect(m, pt=pt, c=c):
                key = f'@@{pt}{c[0]}@@'
                c[0] += 1
                pmap[key] = m.group(1)
                return key
            return _protect
        text = re.sub(pattern, make_protector(), text)
    return text


def restore_all(text, pmap):
    for key, val in pmap.items():
        text = text.replace(key, val)
    return text


def split_line(text):
    """Split text into sentences, each on its own line."""
    if not text.strip():
        return [text]

    pmap = {}
    text = protect_all(text, pmap)

    result = []

    # Step 1: split at Chinese sentence endings
    parts = re.split(r'(?<=[。！？])', text)
    for part in parts:
        part = part.strip()
        if not part:
            continue
        # Step 2: split at English sentence endings
        subparts = re.split(
            r'(?<=[.!?])\s+(?=[A-Z"\'`(\[]|\\S|\\P|\\ref|\\cite|\\label|\\begin|\\item|@@)',
            part,
        )
        for sp in subparts:
            sp = sp.strip()
            if not sp:
                continue
            if len(sp) > MAX_LINE:
                result.extend(_split_long(sp))
            else:
                result.append(sp)

    result = [restore_all(r, pmap) for r in result]

    # Post-process: iteratively split until all lines are within limit.
    # Restored lines can exceed MAX_LINE because placeholders (7-8 chars)
    # expand back to full \cite{...} (20-70+ chars) or inline math
    # $...$ (often much longer).  Re-protect and use a tighter split
    # target proportional to the placeholder compression ratio.
    final = []
    work = list(result)
    while work:
        r = work.pop(0)
        if len(r) <= MAX_LINE:
            final.append(r)
            continue
        pmap2 = {}
        protected = protect_all(r, pmap2)
        # Estimate the split budget so that after restoration each piece fits.
        # len(protected) <= len(r), so compression_ratio < 1.
        compression_ratio = len(protected) / max(len(r), 1)
        target = max(int(MAX_LINE * compression_ratio), MAX_LINE // 2)
        sub = _split_long_aggressive_at(protected, target)
        if len(sub) < 2:
            sub = _split_hard_max(protected, target)
        if len(sub) >= 2:
            restored = [restore_all(s, pmap2) for s in sub]
            work[:0] = restored
        else:
            # Brute-force: try progressively tighter limits
            sub = None
            for t in range(MAX_LINE, 30, -5):
                s = _split_hard_max(protected, t)
                if len(s) >= 2:
                    restored = [restore_all(seg, pmap2) for seg in s]
                    if all(len(seg) <= MAX_LINE for seg in restored):
                        sub = restored
                        break
            if sub:
                work[:0] = sub
            else:
                final.append(r)


    return final


def _find_rightmost(text, limit, chars):
    """Return the rightmost index of any char in `chars` within [:limit]."""
    best = -1
    for ch in chars:
        idx = text.rfind(ch, 0, limit)
        if idx > best:
            best = idx
    return best


def _split_long(text):
    """Split at the rightmost phrase boundary before MAX_LINE."""
    if len(text) <= MAX_LINE:
        return [text]
    # Prefer phrase breaks (colon, semicolon), then comma, then closing brackets,
    # then ASCII comma, then space / CJK-safe hard split
    idx = _find_rightmost(text, MAX_LINE, '；：;:')
    if idx <= MAX_LINE // 3:
        idx = _find_rightmost(text, MAX_LINE, '，、')
    if idx <= MAX_LINE // 3:
        idx = _find_rightmost(text, MAX_LINE, ')）】』〕》」')
    if idx <= MAX_LINE // 3:
        idx = _find_rightmost(text, MAX_LINE, ',')
    if idx > MAX_LINE // 3:
        return [text[:idx + 1].strip(), text[idx + 1:].strip()]
    return _split_hard(text)


def _split_at_commas(text):
    """Split at the rightmost comma before MAX_LINE (backup for _split_long)."""
    if len(text) <= MAX_LINE:
        return [text]
    idx = _find_rightmost(text, MAX_LINE, '，,、')
    if idx > MAX_LINE // 3:
        return [text[:idx + 1].strip(), text[idx + 1:].strip()]
    return _split_hard(text)


def _is_cjk(ch):
    """Check if a character is a CJK ideograph."""
    cp = ord(ch)
    return (0x4E00 <= cp <= 0x9FFF or 0x3400 <= cp <= 0x4DBF)


def _split_hard(text):
    """Force split at MAX_LINE boundary, preferring word breaks.

    Avoids splitting in the middle of CJK text by searching backward for
    a non-CJK boundary when the character-level fallback lands mid-word.
    """
    if len(text) <= MAX_LINE:
        return [text]
    space = text.rfind(' ', 0, MAX_LINE)
    if space > MAX_LINE // 2:
        return [text[:space].strip(), text[space:].strip()]
    # Avoid splitting in the middle of a CJK word
    if (MAX_LINE > 0 and MAX_LINE < len(text)
            and _is_cjk(text[MAX_LINE - 1]) and _is_cjk(text[MAX_LINE])):
        for i in range(MAX_LINE - 1, MAX_LINE // 2, -1):
            if not (_is_cjk(text[i - 1]) and _is_cjk(text[i])):
                return [text[:i].strip(), text[i:].strip()]
    # Avoid splitting through @@...@@ placeholders
    start = text.rfind('@@', 0, MAX_LINE)
    if start >= 0:
        end = text.find('@@', start + 2)
        if end > 0 and start < MAX_LINE < end + 2:
            return [text[:start].strip(), text[start:].strip()]
    return [text[:MAX_LINE].strip(), text[MAX_LINE:].strip()]


def _split_hard_max(text, max_chars):
    """Like _split_hard but with explicit max (for prefix-adjusted wrapping)."""
    if len(text) <= max_chars:
        return [text]
    space = text.rfind(' ', 0, max_chars)
    if space > max_chars // 2:
        return [text[:space].strip(), text[space:].strip()]
    if (max_chars > 0 and max_chars < len(text)
            and _is_cjk(text[max_chars - 1]) and _is_cjk(text[max_chars])):
        for i in range(max_chars - 1, max_chars // 2, -1):
            if not (_is_cjk(text[i - 1]) and _is_cjk(text[i])):
                return [text[:i].strip(), text[i:].strip()]
    # Avoid splitting through @@...@@ placeholders
    idx = max_chars
    if idx <= len(text):
        start = text.rfind('@@', 0, idx)
        if start >= 0:
            end = text.find('@@', start + 2)
            if end > 0 and start < idx < end + 2:
                idx = start
    return [text[:idx].strip(), text[idx:].strip()]


def _split_long_aggressive(text):
    """Post-processing: try phrase boundaries, then comma, then hard split."""
    if len(text) <= MAX_LINE:
        return [text]
    idx = _find_rightmost(text, MAX_LINE, '；：;:')
    if idx <= MAX_LINE // 3:
        idx = _find_rightmost(text, MAX_LINE, '，、')
    if idx <= MAX_LINE // 3:
        idx = _find_rightmost(text, MAX_LINE, ')）】』〕》」')
    if idx <= MAX_LINE // 3:
        idx = _find_rightmost(text, MAX_LINE, ',')
    if idx > MAX_LINE // 3:
        return [text[:idx + 1].strip(), text[idx + 1:].strip()]
    return _split_hard(text)


def _split_long_aggressive_at(text, max_chars):
    """Like _split_long_aggressive but with explicit max_chars limit."""
    if len(text) <= max_chars:
        return [text]
    idx = _find_rightmost(text, max_chars, '；：;:')
    if idx <= max_chars // 3:
        idx = _find_rightmost(text, max_chars, '，、')
    if idx <= max_chars // 3:
        idx = _find_rightmost(text, max_chars, ')）】』〕》」')
    if idx <= max_chars // 3:
        idx = _find_rightmost(text, max_chars, ',')
    if idx > max_chars // 3:
        return [text[:idx + 1].strip(), text[idx + 1:].strip()]
    return _split_hard_max(text, max_chars)


def is_abbreviation(text, pos):
    """Check if a period at pos ends an abbreviation."""
    before = text[:pos].rstrip()
    space_pos = max(before.rfind(' '), before.rfind('\n'))
    if space_pos >= 0:
        word = before[space_pos + 1:] + '.'
    else:
        word = before + '.'
    return word in ABBREVIATIONS


def _emit_caption_line(line, output):
    """Wrap text inside \caption{...}."""
    stripped = line.strip()
    brace_start = stripped.index('{')
    depth = 0
    brace_end = -1
    for j, ch in enumerate(stripped[brace_start:], brace_start):
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                brace_end = j
                break
    if brace_end is None or brace_end <= brace_start:
        output.append(line)
        return
    prefix = stripped[:brace_start + 1]
    caption_text = stripped[brace_start + 1:brace_end]
    suffix = stripped[brace_end:]
    if caption_text:
        wrapped = split_line(caption_text)
        orig_indent = line[:len(line) - len(stripped)]
        output.append(orig_indent + prefix + wrapped[0] + suffix)
        for w in wrapped[1:]:
            output.append(orig_indent + '    ' + w)
    else:
        output.append(line)


def _emit_item_line(line, output):
    """Wrap text after \item, accounting for the \item prefix in line length."""
    stripped = line.strip()
    idx = stripped.index(r'\item')
    after_item = stripped[idx + len(r'\item'):].strip()
    if after_item:
        wrapped = split_line(after_item)
        indent = '    '
        prefix = line[:len(line) - len(stripped)] + r'\item '
        first_line = prefix + wrapped[0]
        # If \item prefix pushes the first line over MAX_LINE, re-split
        if len(first_line) > MAX_LINE and len(wrapped[0]) > 20:
            effective = MAX_LINE - len(prefix)
            sub = _split_hard_max(wrapped[0], effective)
            output.append(prefix + sub[0])
            for s in sub[1:]:
                output.append(indent + s)
            for w in wrapped[1:]:
                output.append(indent + w)
        else:
            output.append(first_line)
            for w in wrapped[1:]:
                output.append(indent + w)
    else:
        output.append(line)


def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.split('\n')
    output = []
    paragraph_lines = []
    env_stack = []

    def flush():
        nonlocal paragraph_lines
        if paragraph_lines:
            # Reconstruct continuous paragraph by joining lines with a space.
            # content.split('\n') strips newlines, so '' + replace('\n', ' ') is a
            # no-op that would concatenate words (physical + phenomena → physicalphenomena).
            text = ' '.join(paragraph_lines)
            text = re.sub(r' +', ' ', text)
            if text:
                split_lines = split_line(text)
                output.extend(split_lines)
            paragraph_lines = []

    for line in lines:
        stripped = line.strip()

        if stripped.startswith('%'):
            flush()
            output.append(line)
            continue

        begin_m = re.search(r'\\begin\{(\w+)\}', stripped)
        end_m = re.search(r'\\end\{(\w+)\}', stripped)
        if begin_m:
            env_stack.append(begin_m.group(1))
        if end_m and env_stack:
            env_stack.pop()

        current_env = env_stack[-1] if env_stack else None

        if current_env in MATH_BLOCKS:
            flush()
            output.append(line)
            continue

        if current_env in PROTECTED_BLOCKS:
            flush()
            if current_env in ('itemize', 'enumerate') and r'\item' in stripped:
                _emit_item_line(line, output)
            elif r'\caption' in stripped:
                _emit_caption_line(line, output)
            else:
                output.append(line)
            continue

        if current_env in ('abstract', 'highlights', 'keywords'):
            if stripped:
                paragraph_lines.append(line)
            else:
                flush()
                output.append('')
            continue

        if stripped == '':
            flush()
            output.append('')
        elif any(stripped.startswith(cmd) for cmd in ONE_LINE_COMMANDS):
            flush()
            output.append(line)
        else:
            paragraph_lines.append(line)

    flush()

    result = '\n'.join(output)
    result = '\n'.join(l.rstrip() for l in result.split('\n'))
    result = re.sub(r'\n{3,}', '\n\n', result)
    result = result.strip() + '\n'

    if result != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(result)
        return True
    return False


if __name__ == '__main__':
    files = sys.argv[1:]
    changed = []
    for filepath in files:
        if os.path.exists(filepath):
            try:
                if process_file(filepath):
                    changed.append(filepath)
                    print(f"CHANGED: {filepath}")
                else:
                    print(f"UNCHANGED: {filepath}")
            except Exception as e:
                import traceback
                print(f"ERROR: {filepath}: {e}")
                traceback.print_exc()
        else:
            print(f"SKIP (not found): {filepath}")
    print(f"\n{len(changed)} files modified.")
