"""Diagnose CJK split and broken citation issues."""
import re

tex = r"C:/Users/WIN11/.claude/skills/latex-sentence-wrap-workspace/iteration-1/eval-2-chinese-english-mixed/with_skill/outputs/chinese_mixed.tex"
with open(tex, 'r', encoding='utf-8') as f:
    content = f.read()

# Find broken citations
print("=== BROKEN CITATIONS ===")
for m in re.finditer(r'\\cite\{', content):
    brace_depth = 1
    pos = m.end()
    while pos < len(content) and brace_depth > 0:
        if content[pos] == '{': brace_depth += 1
        elif content[pos] == '}': brace_depth -= 1
        pos += 1
    between = content[m.start():pos]
    if '\n' in between:
        start = max(0, m.start() - 40)
        end = min(len(content), pos + 40)
        print("Context:", repr(content[start:end]))

print("\n=== CJK BOUNDARIES (line endings with CJK chars) ===")
lines = content.split('\n')
for i in range(len(lines) - 1):
    cur = lines[i].rstrip()
    nxt = lines[i + 1].lstrip()
    if not cur or not nxt:
        continue
    cjk_end = [c for c in cur[-2:] if 0x4E00 <= ord(c) <= 0x9FFF]
    cjk_start = [c for c in nxt[:2] if 0x4E00 <= ord(c) <= 0x9FFF]
    if cjk_end and cjk_start:
        print(f"L{i + 1}: ...{cur[-15:]} | {nxt[:15]}...")

# Also check broken math in eval 3
print("\n=== BROKEN MATH (eval 3 with-skill) ===")
tex3 = r"C:/Users/WIN11/.claude/skills/latex-sentence-wrap-workspace/iteration-1/eval-3-math-and-environments/with_skill/outputs/math_environments.tex"
with open(tex3, 'r', encoding='utf-8') as f:
    content3 = f.read()
pos = 0
while True:
    start = content3.find('$', pos)
    if start == -1:
        break
    end = content3.find('$', start + 1)
    if end == -1:
        break
    if '\n' in content3[start:end + 1]:
        ctx_start = max(0, start - 30)
        ctx_end = min(len(content3), end + 30)
        print("Broken math:", repr(content3[ctx_start:ctx_end]))
    pos = end + 1
