# 流体力学论文通用规范

适用于 JCP、JFM 及一般流体力学/计算物理期刊的共通写作规范。

## 控制方程与边界条件

### 必须完整报告
- Navier–Stokes 方程（可压/不可压）或 Euler 方程
- 边界条件（壁面、进口/出口、对称、周期）
- 初始条件
- 湍流模型（如 RANS、LES、DNS）及其适用范围
- 状态方程（如涉及可压缩流）

### 无量纲化
- 明确报告使用的无量纲化方案（参考长度 $L_\text{ref}$、参考速度 $U_\text{ref}$、Reynolds 数等）
- 所有无量纲参数需给出具体数值
- Reynolds 数：$\Rey = UL/\nu$；Mach 数：$\Ma = U/c$；Froude 数：$\Fr = U/\sqrt{gL}$ 等

## 数值方法标准

### 报告清单
- [ ] 空间离散格式（有限差分/有限体积/有限元/谱方法）及精度阶数
- [ ] 时间推进格式（显式/隐式）及 CFL 数
- [ ] 网格类型（结构化/非结构化/自适应/笛卡尔）及单元数
- [ ] 网格收敛性/独立性研究（Grid Convergence Index 或类似方法）
- [ ] 求解器/线性系统求解方法
- [ ] 并行策略（如 MPI/GPU 加速）

### 网格收敛性验证
必须包含：
- 至少 3 套网格（粗/中/细）
- 关键积分量（阻力系数、升力系数、Strouhal 数等）随网格变化的趋势
- 如使用 Richardson 外推，报告收敛阶和 GCI

### 验证与确认 (Verification & Validation)
| 类型 | 内容 |
|------|------|
| Verification | 数值解是否正确地求解了方程？（网格收敛性、精度阶数） |
| Validation | 数值解是否正确地描述了物理？（与实验/文献数据对比） |
| Uncertainty | 数值不确定度量化（如需要） |

## 常用流体力学术语

| 术语 | 规范写法 |
|------|---------|
| 雷诺数 | Reynolds number ($\Rey$) |
| 马赫数 | Mach number ($\Ma$) |
| 斯特劳哈尔数 | Strouhal number ($\St$) |
| 边界层 | boundary layer |
| 分离泡 | separation bubble |
| 涡脱落 | vortex shedding |
| 剪切层 | shear layer |
| 湍流 | turbulence |
| 转换 | transition |
| 气动系数 | aerodynamic coefficients |
| 阻力/升力 | drag / lift |
| 涡量 | vorticity ($\boldsymbol{\omega} = \nabla \times \boldsymbol{u}$) |

## 结果呈现惯例

### 流场可视化
- 涡量/压力/速度云图：标注颜色条、给出物理量范围
- 流线/迹线：标注流动方向
- Q 准则/$\lambda_2$ 准则涡识别：说明阈值选择依据
- 所有云图标注坐标轴及无量纲参数（$x/L$, $y/L$）

### 定量对比
- 力系数收敛曲线（$C_D$, $C_L$ vs. time steps/iterations）
- 频谱分析（Strouhal 数谱峰）
- 剖面数据对比（平均速度剖面、雷诺应力剖面）
- 需包含误差带或不确定度范围

## 符号一致性规则

- 同一符号在全文表示同一物理量，不得跨节重用
- 向量用粗体或箭头上标，保持统一
- 张量用双线体或粗体（或明确说明）
- 下标需自解释或首次定义：$u_\text{wall}$, $p_\infty$, $T_\text{ref}$
- 带撇号表示脉动量：$u'$（Reynolds 分解）
- 时间平均：$\overline{u}$；系综平均：$\langle u \rangle$

## 参考文献常见格式

- **JFM**：Author (year)，字母顺序 — "(Pope 2000)"，参考表有标题和末页
- **JCP**：[1] 方括号顺序编号 — Elsevier Vancouver 风格
- **Physics of Fluids / Phys. Fluids**：编号引用，具体见期刊 Guide for Authors
- 同一篇论文同时投多个期刊时，先确认目标期刊的引用格式
