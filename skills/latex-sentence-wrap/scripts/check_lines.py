"""Check for long text lines in .tex files."""
import sys

SKIP_PREFIXES = (
    '%', '\\section', '\\subsection', '\\begin{', '\\end{', '\\label',
    '\\input{', '\\mathcal', '\\mathbb', '\\documentclass', '\\usepackage',
    '\\graphicspath', '\\setCJK', '\\title', '\\author', '\\affiliation',
    '\\shorttitle', '\\shortauthors', '\\cormark', '\\cortext', '\\ead',
    '\\maketitle', '\\bibliography', '\\bibliographystyle', '\\appendix',
    '\\bigskip', '\\medskip', '\\smallskip', '\\newcommand', '\\renewcommand',
)


def main():
    for fname in sys.argv[1:]:
        with open(fname, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        long_lines = []
        for i, line in enumerate(lines):
            stripped = line.strip()
            if len(stripped) > 80 and stripped and not any(
                    stripped.startswith(p) for p in SKIP_PREFIXES):
                punct = []
                for p, name in [('。', '句'), ('；', '分号'), ('：', '冒'),
                                ('，', '逗'), ('、', '顿'), ('——', '破折')]:
                    if p in stripped:
                        punct.append(name)
                info = ' '.join(punct) if punct else 'NO-BREAK'
                long_lines.append((i + 1, len(stripped), info, stripped[:120]))
        if not long_lines:
            print(f'  OK: {fname}')
        else:
            print(f'  {fname}: {len(long_lines)} long lines')
            for num, length, info, preview in long_lines[:6]:
                print(f'    L{num} ({length}c) [{info}]: {preview}')
            if len(long_lines) > 6:
                print(f'    ... and {len(long_lines) - 6} more')


if __name__ == '__main__':
    main()
