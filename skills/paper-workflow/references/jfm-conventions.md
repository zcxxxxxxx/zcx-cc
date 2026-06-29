# JFM (Journal of Fluid Mechanics) — 投稿规范

JFM 为 Cambridge University Press 旗下期刊，有严格的符号、语言和格式要求。**英式英语为强制要求。**

## 语言

### 英式拼写

| 美式 | JFM（英式） |
|------|------------|
| behavior | behaviour |
| modeling | modelling |
| center | centre |
| analyze | analyse |
| color | colour |
| traveling | travelling |
| zero-th | zeroth |
| coordinate | coordinate（不变） |

**专有名词**保留首字母大写：Gaussian, Lagrangian, Cartesian, Pitot。

### 连字符规则

| 规则 | 例 |
|------|----|
| 名词前复合形容词 | large-scale region, low-frequency wave, solid-body rotation |
| 名词后不加连字符 | equation of first order（不加连字符） |
| 固定连字符前缀 | self-interaction, cross-section, half-width |
| non- 例外 | nonlinear（无连字符）；non-uniform, non-dimensional（有连字符） |
| 名词固定写法 | wavenumber, wavelength, sidewall, arclength, bandwidth, subgrid, cutoff, breakup |
| 两个独立词 | time scale, length scale, time step, flow field, grid point |
| 短横连接 (en rule) | gravity–capillary, Navier–Stokes, 10–20 cm |

### 缩写与标点

- 所有缩写首次出现时定义，不设 nomenclature 列表
- 脚注一般不接受
- 章节引用用 §，句首用 "Section"
- 大数不加逗号，用空格：1600, 16 000, 160 000

## 数学符号约定

| 元素 | 字体 | 示例 |
|------|------|------|
| 变量 | *Italic* | $u$, $v$, $p$, $\rho$ |
| 算符/常数 | Upright Roman | $\sin$, $\log$, $\mathrm{d}$, $\mathrm{e}$, $\mathrm{i}$（虚数单位） |
| 微分 d | Upright Roman | $\mathrm{d}$（积分号内） |
| 向量 | **Bold italic** | $\boldsymbol{u}$, $\boldsymbol{\omega}$ |
| 张量/矩阵 | **Bold sans-serif** | $\mathsfbi{D}$（用 `\mathsfbi` 宏） |
| 特殊函数 | Upright Roman | $\Ai$, $\Bi$, $\Real$, $\Imag$ |
| 单位/缩写 | Upright Roman | cm, s, DNS |

**无量纲数专用宏**（必须使用 JFM 类文件 `jfm.cls` 预定义宏）：

| 宏 | 渲染 | 含义 |
|----|------|------|
| `\Rey` | $\Rey$ | Reynolds number |
| `\Pran` | $\Pran$ | Prandtl number |
| `\Pen` | $\Pen$ | Péclet number |

其他无量纲数用 `\mathrm{...}`：$\mathrm{Fr}$, $\mathrm{Ma}$, $\mathrm{St}$。

**其他规则**：$\times$ 仅用于叉乘、换行或数字之间；$\cdot$ 仅用于向量点乘；$\mathcal{O}$ 不用，改用意体 $O$。

## 论文结构

| 元素 | 要求 |
|------|------|
| 标题 | 简洁有信息，sentence case |
| 摘要 | 单段 ≤250 词，不能溢出到第二页 |
| 关键词 | 投稿系统选择（非文中），最多 3 个 |
| 章节标题 | sentence case（仅首字大写）：Governing equations, Numerical method |
| 致谢 | 参考文献前另起一段（无单独标题） |
| 竞争利益声明 | **强制**（即使在致谢前） |
| 数据可用性声明 | 强烈鼓励 |
| 参考文献 | Author (year)，字母顺序排列 |

### 参考文献格式

- **3 位作者**：首次全列，之后用 et al.
- **4 位+作者**：直接 et al.
- 段落内用分号分隔：*(Pope 2000; Moin & Mahesh 1998)*
- 参考文献表按字母顺序排列

## 图表规范

| 元素 | 要求 |
|------|------|
| 图标题 | **在下方**，矢量图 (EPS) 或 ≥300 dpi TIFF |
| 表标题 | **在上方** |
| 彩色 | JFM Rapids 免费；标准论文可能收费 |

## 审稿常见结构性问题

- 摘要超 250 词或溢出第二页
- 缺少网格收敛性/独立性验证
- 无量纲数未使用 JFM 标准符号
- 英式拼写不统一
- 数值结果缺少与实验/文献对比验证
- 变量未在首次出现时定义（用 nomenclature list 替代）
