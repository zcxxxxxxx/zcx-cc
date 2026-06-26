---
name: hunong-teacher
description: |
  Read an academic paper and produce a natural, polished PPT-style HTML presentation
  for group meeting reporting. Only use when explicitly invoked via /hunong-teacher.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Bash
---

# Hunong Teacher — 组会论文汇报生成器

Use this skill **only when manually invoked** via `/hunong-teacher`. The user provides a paper (text, PDF path, DOI, or notes), and this skill produces a self-contained HTML presentation for group meeting reporting.

## Inputs

Accept any of:
- Full paper text pasted by the user
- A local PDF/DOCX/Markdown/TXT file path
- A paper title plus abstract or notes
- A DOI or URL (if web access is available)

For PDFs longer than 10 pages, read title, abstract, introduction, method, results, discussion, conclusion first; inspect other pages only if needed. If critical information is missing, still produce the deck and mark uncertain items as `待确认` in small footnotes.

## Core Design Principle

**The HTML must look like a real researcher's group meeting slides — not an AI-generated template.** Each slide should feel naturally written, with varied layouts, conversational Chinese titles, and a professional but not rigid visual style.

| ❌ AI-template look (avoid) | ✅ Natural look (aim for) |
|----------------------------|--------------------------|
| Every slide identical layout | Varied layouts: title full-width, two-column, grid, split |
| Generic titles like "Innovation Points" | Contextual titles like "本文的核心创新点" or "方法上做了什么改进" |
| Bullet lists everywhere | Mix: concise text, inline emphasis, card-style grouping |
| Robotic Chinese | Natural academic Chinese — like a real presenter explaining |
| Same font size throughout | Clear visual hierarchy: titles → section headers → body → footnotes |

## Output Requirements

- One self-contained `.html` file
- CSS inside `<style>` block — no external assets or network fonts
- Chinese as default language (override if user asks)
- Default filename: `paper-summary-<short-title-slug>.html`

## Slide Content (8–12 slides, adjust based on paper depth)

Plan slides naturally — not every paper needs the same number. Group content by logic, not by template slot:

1. **Title slide** — Paper title, authors, venue/year, one-sentence takeaway
2. **背景与研究问题** — Field context, why it matters, the specific problem
3. **核心思路** — Main idea, central hypothesis, paper's overall logic
4. **创新点** — 2–4 concrete innovations (distinguish conceptual vs methodological vs application)
5. **方法路线** — Pipeline, framework, or analytical path. Use diagrams/timelines where helpful
6. **关键发现** — Main results, evidence, conclusions. Include metrics when the paper provides them
7. **启发与可借鉴之处** — What can be borrowed or extended — **this is for the group meeting audience**
8. **两个问题** — Exactly two specific, research-oriented questions for discussion
9. **未来方向** — 2–4 directions for follow-up research
10. **总结** — Synthesis + takeaways

## Visual Design

### Layout Principles
- 16:9 full-screen slides
- Each slide = `<section class="slide">`
- **Varied layouts**: not every slide should look the same
  - Title slide: centered, large text, minimal
  - Content slides: mix of full-width, two-column, card grid, or split layouts
  - Use card-style grouping for comparable items, inline text for flow narratives
- Slide numbers in footer

### Color Palette
- Choose one accent color based on the paper's topic/field
- Background: `#ffffff` or very light warm `#faf9f7` (warmer than pure gray)
- Text: `#1a1a2e`
- Accent options: `#2563eb` (blue, engineering), `#0f766e` (teal, physics/CS), `#b45309` (amber, math), `#7c3aed` (purple, interdisciplinary)
- Light accent background for cards: add with low opacity

### Typography
- Titles: bold, 1.8–2.2rem
- Section headers: 1.2–1.4rem, accent-color underline
- Body: 0.95–1rem, comfortable line-height (1.5–1.6)
- Footnotes: 0.75rem, muted color
- System fonts only: `"PingFang SC", "Microsoft YaHei", "Noto Sans SC", sans-serif`

### Natural Feel Techniques
- Add subtle CSS transitions for slide appearance (fade/slide-in)
- Use CSS `box-shadow` for light card elevation (not flat design, not heavy shadows)
- Card border-radius: 6–10px
- Don't over-decorate — one visual accent per slide maximum

### Print Support

```css
@page { size: 16in 9in; margin: 0; }
@media print {
  body { background: #fff; }
  .slide { break-after: page; box-shadow: none; }
}
```

## Analysis Standards

- Separate what the paper explicitly says from your inference
- Do not invent experimental results, datasets, baselines, or claims
- Prefer concrete nouns and verbs over generic academic filler
- Innovation points must explain: what is new **relative to prior work or common practice**
- Methods must be traceable: reader understands how input → result
- Questions must be useful for seminar discussion, not ceremonial
- Future directions must be actionable, not vague

## Quality Checklist

- [ ] Slide layout varies — not every slide looks identical
- [ ] Titles sound natural, not machine-generated
- [ ] Chinese is natural academic register (not stiff, not colloquial)
- [ ] All critical information from the paper is captured
- [ ] No invented results or claims
- [ ] Two discussion questions are specific and research-oriented
- [ ] Visual hierarchy is clear (title → section → body → footnote)
- [ ] File opens correctly in a browser
- [ ] Colors are restrained and professional

## Output

After creating the HTML file, respond with:
- Created file path
- Number of slides
- Any missing paper metadata or assumptions made
- Whether the file can be opened directly in a browser

Do not paste the full HTML into chat unless the user explicitly asks.
