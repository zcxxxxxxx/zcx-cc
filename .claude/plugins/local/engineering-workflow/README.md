# Engineering Workflow Plugin — 工程工作流插件

## 简介

三层工程工作流插件，面向复杂多步任务、实验验证、循环自动化。为 Claude 提供结构化的工程设计方法论。

## 核心功能

| 功能 | 说明 |
|------|------|
| **Cost-Aware Fast Path** | 自动判断任务类型，只加载必要上下文。纯脚本任务跳过循环设计/实验框架 |
| **循环设计 (Loop Engineering)** | 5 步构建法：目标定义 → 最小循环 → W/V 分离 → 硬停止 → 单一指标 |
| **实验框架 (Harness Engineering)** | STATE.md 状态跟踪、check-harness.sh 完整性检查、验证模板 |
| **代码模板** | `scripts/templates/` 提供即用脚本（文件处理、方程求解），copy-paste 即用 |
| **W/V 分离** | 执行器与验证器独立，验证器不共享执行器上下文 |
| **硬停止条件** | 迭代限制 + 超时 + 失败阈值三保险，retry→notify→halt 升梯报警 |
| **熵管理** | 自动归档已完成实验，清理过期输出 |

## Cost-Aware Fast Path

Fast Path 根据任务类型智能分级，避免加载无关上下文：

| 任务类型 | 加载内容 | Token 节省 |
|---------|---------|-----------|
| **code_only** | 仅代码模板 | 跳过 loop + harness，节省 ~16% |
| **pure harness** | 仅 harness-engineering | 跳过循环设计 |
| **pure loop** | 仅 loop-engineering | 跳过实验框架 |
| **full stack** | 完整加载 | 两者都需时值得 |

## 目录结构

```
engineering-workflow/
├── CLAUDE.md                     # 插件入口（agent 指引）
├── INTERFACES.md                 # 三层间接口契约
├── skills/
│   ├── harness-engineering/      # 实验基础设施
│   │   ├── SKILL.md
│   │   ├── scripts/
│   │   │   ├── check-harness.sh
│   │   │   └── templates/        # 代码模板目录
│   │   │       ├── file-watcher.py
│   │   │       └── equation-solver.py
│   │   └── references/
│   │       ├── entropy-checklist.md
│   │       ├── taste-invariants.md
│   │       └── validation-templates.md
│   └── loop-engineering/         # 循环编排
│       ├── SKILL.md
│       ├── scripts/loop-audit.sh
│       └── references/
│           ├── anti-patterns.md
│           └── readiness-test.md
└── .claude-plugin/plugin.json    # 插件注册文件
```

## 安装

### 作为本地插件安装

```bash
# 克隆或复制到本地插件目录
cp -r engineering-workflow ~/.claude/plugins/local/engineering-workflow
# 插件会自动注册到 installed_plugins.json
```

### 依赖

需要 [Superpowers](https://github.com/obra/superpowers) 插件提供 TDD、调试、并行代理等会话能力。插件启动时会自动检测安装。

## 使用场景

- **CFD/PINN/ML 实验** — 参数扫描 + 收敛检测 + 结果验证
- **网站监控循环** — 定时检查 HTTP 健康 + 自动恢复 + Slack 报警
- **文件批处理** — 监听目录、处理文件、记录 CSV、归档已处理
- **方程求解验证** — 读 JSON、逐题求解、比对预期、写 STATE.md
- **论文级验证** — W/V 分离 + 声明级别 (L1/L2/L3) + 完整可复现性审计

## 版本历史

| 版本 | 迭代 | 新增 |
|------|------|------|
| 1.0.0 | 1 | 基础技能定义 + 3 个设计类 evals |
| 1.0.1 | 2 | Cost-Aware Fast Path + INTERFACES.md + plugin 重构 |
| 1.0.2 | 3 | **code_only** fast path + 代码模板 + STATE.md 双变体 |
