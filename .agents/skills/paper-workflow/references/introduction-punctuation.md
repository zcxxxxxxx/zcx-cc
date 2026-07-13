# Introduction Em-Dash Convention

Introduction paragraphs 2–5 (problem definition, PINN intro, existing methods, gap) are where Chinese em-dashes most commonly appear. Each em-dash function requires a specific connective word — never leave a bare `：` or `，` in place of `——`.

## Chinese patterns

| —— function | Fix | Before | After |
|-------------|-----|--------|-------|
| **Elaboration** — B explains what A means | `A。具体而言，B` | `涉及高阶导数路径——低秩修正不仅影响u_θ` | `涉及高阶导数路径。具体而言，低秩修正不仅影响u_θ` |
| **Cause** — B is the reason for A | `A，因为B` | `特别的意义——继承源权重可加速收敛` | `特别的意义，因为继承源权重可加速收敛` |
| **Definition** — B defines what A means | `A。此时B` / `A，即B` | `算子保持型变化——各阶导数权重不变` | `算子保持型变化，即各阶导数权重不变` |
| **Enumeration** — B lists components of A | `A，涉及B、C、D` | `重新启动——重分网格、组装矩阵、迭代` | `重新启动，涉及重分网格、组装矩阵、迭代` |

## English patterns

| — function | Fix | Before | After |
|------------|-----|--------|-------|
| **Elaboration** | colon / "namely" / "specifically" | "a key limitation — training must restart" | "a key limitation: training must restart" |
| **Parenthetical** | commas | "PINNs — unlike FDM — require no mesh" | "PINNs, unlike FDM, require no mesh" |
| **Cause** | "because" / "since" | "backbone is frozen — AD still traverses all layers" | "although the backbone is frozen, AD still traverses all layers" |
