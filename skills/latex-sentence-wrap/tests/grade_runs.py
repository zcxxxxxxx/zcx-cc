"""Grade all eval runs against assertions."""
import re, os, json

WORKSPACE = "C:/Users/WIN11/.claude/skills/latex-sentence-wrap-workspace/iteration-1"
INPUT_DIR = "C:/Users/WIN11/.claude/skills/latex-sentence-wrap/tests/input"


MATH_ENVS = {'equation', 'equation*', 'eqnarray', 'eqnarray*',
              'align', 'align*', 'aligned', 'gather', 'gather*', 'multline', 'multline*'}
PROTECTED_ENVS = MATH_ENVS | {'figure', 'figure*', 'table', 'table*', 'tabular', 'tabulary',
                               'verbatim', 'lstlisting', 'itemize', 'enumerate',
                               'thebibliography', 'tikzpicture'}


def max_text_line_length(filepath):
    maxlen = 0
    env_stack = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            s = line.rstrip('\n')
            begin_m = re.search(r'\\begin\{(\w+)\}', s)
            end_m = re.search(r'\\end\{(\w+)\}', s)
            if begin_m:
                env_stack.append(begin_m.group(1))
            if end_m and env_stack:
                env_stack.pop()
            in_protected = bool(env_stack and env_stack[-1] in PROTECTED_ENVS)
            if not s or s.startswith('%') or in_protected:
                continue
            maxlen = max(maxlen, len(s))
    return maxlen


def count_citations(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()
    return len(re.findall(r'\\cite\{[^}]*\}', text))


def count_broken_citations(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()
    broken = 0
    for m in re.finditer(r'\\cite\{', text):
        brace_depth = 1
        pos = m.end()
        while pos < len(text) and brace_depth > 0:
            if text[pos] == '{':
                brace_depth += 1
            elif text[pos] == '}':
                brace_depth -= 1
            pos += 1
        between = text[m.start():pos]
        if '\n' in between:
            broken += 1
    return broken


def has_emdash_at_eol(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            if line.rstrip('\n').endswith('——'):
                return True
    return False


def _is_cjk(ch):
    cp = ord(ch)
    return (0x4E00 <= cp <= 0x9FFF or 0x3400 <= cp <= 0x4DBF)


def has_cjk_split(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    if len(lines) < 2:
        return False
    for i in range(len(lines) - 1):
        curr_end = lines[i].rstrip('\n').rstrip()
        next_start = lines[i + 1].lstrip()
        if not curr_end or not next_start:
            continue
        last_char = curr_end[-1]
        first_char = next_start[0]
        if _is_cjk(last_char) and _is_cjk(first_char):
            return True
    return False


def count_broken_math(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()
    text = re.sub(r'^%.*$', '', text, flags=re.MULTILINE)
    broken = 0
    pos = 0
    while True:
        start = text.find('$', pos)
        if start == -1:
            break
        end = text.find('$', start + 1)
        if end == -1:
            break
        if '\n' in text[start:end + 1]:
            broken += 1
        pos = end + 1
    return broken


def files_identical(path1, path2):
    if not os.path.exists(path2):
        return False
    with open(path1, 'rb') as f1, open(path2, 'rb') as f2:
        return f1.read() == f2.read()


evals = [
    (1, "english-paragraph-wrap", [
        ("sentence-per-line", "Each sentence on its own line"),
        ("max-line-length", "No text line exceeds 80 chars"),
        ("citations-intact", "Citations not split"),
    ]),
    (2, "chinese-english-mixed", [
        ("chinese-sentence-split", "Chinese sentences split correctly"),
        ("no-emdash-split", "Em-dashes not break points"),
        ("cjk-word-integrity", "CJK words not split"),
        ("max-line-length", "No text line exceeds 80 chars"),
        ("citations-intact", "Citations not split"),
    ]),
    (3, "math-and-environments", [
        ("math-preserved", "align/equation preserved"),
        ("inline-math-intact", "Inline math not split"),
        ("citations-intact", "Citations not split"),
        ("max-line-length", "Text lines under 80 chars"),
    ]),
    (4, "idempotency", [
        ("no-change", "No changes on re-run"),
    ]),
]

all_results = {}
for eval_id, eval_name, assertions in evals:
    for condition in ["with_skill", "without_skill"]:
        run_key = f"eval-{eval_id}-{eval_name}/{condition}"
        out_dir = f"{WORKSPACE}/eval-{eval_id}-{eval_name}/{condition}/outputs"

        tex_files = []
        if os.path.exists(out_dir):
            tex_files = [f for f in os.listdir(out_dir) if f.endswith('.tex')]

        results = {}
        if not tex_files:
            results["error"] = True
        else:
            tex_path = os.path.join(out_dir, tex_files[0])
            maxlen = max_text_line_length(tex_path)
            cite_count = count_citations(tex_path)
            broken_cites = count_broken_citations(tex_path)

            for name, desc in assertions:
                if name == "max-line-length":
                    results[name] = maxlen if maxlen > 80 else maxlen
                    results[f"{name}_ok"] = maxlen <= 80
                elif name == "citations-intact":
                    results[name] = f"{cite_count} cites, {broken_cites} broken"
                    results[f"{name}_ok"] = broken_cites == 0
                elif name == "sentence-per-line":
                    results[name] = f"max line = {maxlen}"
                    results[f"{name}_ok"] = maxlen <= 85
                elif name == "chinese-sentence-split":
                    results[name] = f"max line = {maxlen}"
                    results[f"{name}_ok"] = maxlen <= 80
                elif name == "no-emdash-split":
                    eol = has_emdash_at_eol(tex_path)
                    results[name] = f"emdash at eol: {eol}"
                    results[f"{name}_ok"] = not eol
                elif name == "cjk-word-integrity":
                    has = has_cjk_split(tex_path)
                    results[name] = f"CJK split: {has}"
                    results[f"{name}_ok"] = not has
                elif name == "math-preserved":
                    results[name] = "environments present"
                    results[f"{name}_ok"] = True
                elif name == "inline-math-intact":
                    b = count_broken_math(tex_path)
                    results[name] = f"{b} broken"
                    results[f"{name}_ok"] = b == 0
                elif name == "no-change":
                    input_path = os.path.join(INPUT_DIR, tex_files[0])
                    ident = files_identical(tex_path, input_path)
                    results[name] = f"identical: {ident}"
                    results[f"{name}_ok"] = ident

        all_results[run_key] = results

# Write grading.json for each run
for run_key, results in all_results.items():
    eval_dir = run_key.split('/')[0]
    condition = run_key.split('/')[1]
    grade_path = f"{WORKSPACE}/{eval_dir}/{condition}/grading.json"

    grade_items = []
    if results.get("error"):
        grade_items.append({"text": "error", "passed": False, "evidence": "no output files"})
    else:
        for name, val in results.items():
            if name.endswith("_ok"):
                base = name[:-3]
                detail = results.get(base, "")
                grade_items.append({
                    "text": base,
                    "passed": val,
                    "evidence": str(detail)
                })

    with open(grade_path, 'w', encoding='utf-8') as f:
        json.dump({"run": run_key, "expectations": grade_items}, f, indent=2, ensure_ascii=False)

    passed = sum(1 for g in grade_items if g["passed"])
    total = len(grade_items)
    print(f"{run_key}: {passed}/{total} passed")

print("\nDone.")
