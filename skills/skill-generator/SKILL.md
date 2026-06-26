---
name: skill-generator
description: >
  Meta-skill for creating new Claude Code skills with proper structure, frontmatter,
  and quality standards. Use when asked to "create a skill", "generate a skill",
  "new skill", "write a skill", "build a skill", or "skill creator".
  Triggers on "create skill", "new skill", "skill generator", "skill模板".
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
---

# Skill Generator

Meta-skill for creating new Claude Code skills. Follows the 5-phase pipeline to produce production-ready skills.

## Phase 0: Specification Study

Before generating, understand these core principles:

### Skill Structure
```
skill-name/
├── SKILL.md       # Required: main definition
├── references/    # Optional: reference docs
├── examples/      # Optional: example outputs
└── scripts/       # Optional: executable scripts
```

### SKILL.md = YAML Frontmatter + Markdown Body

```yaml
---
name: skill-name           # kebab-case, ≤64 chars, 默认=目录名
description: 做什么，何时触发   # 推荐，用于自动触发判断
when_to_use: 额外触发场景     # 追加到 description
# 可选字段:
allowed-tools: Read, Grep    # 预授权工具
model: sonnet                # 模型覆盖
context: fork                # fork=隔离子 agent 执行
disable-model-invocation: false # true=仅手动调用
user-invocable: true          # false=隐藏/菜单
paths: "src/**/*.py"          # glob 限定自动触发范围
---

Body: 工作流 + 规则 + 示例 + 检查清单
```

### Key Rules
- description 用第三人称，包含 trigger phrases
- 必须写明不适用场景
- 正反例对比（Do This / Not This）
- 包含验证自检步骤
- 最小权限原则

## Phase 1: Requirements Discovery

Ask the user these questions to gather requirements:

1. **Skill name?** (kebab-case, e.g., `code-reviewer`, `paper-structure-coach`)
2. **Trigger description?** (what should Claude match against to auto-trigger this skill)
3. **Skill type?** (Reference/knowledge injection or Task/workflow)
4. **Execution mode?** (inline or `context: fork` subagent)
5. **Tools needed?** (minimum required tools to accomplish the task)
6. **Model?** (sonnet/opus/haiku/inherit)

## Phase 2: Structure Generation

Generate the output at `.claude/skills/{skill-name}/SKILL.md`.

### Template: Minimal Skill

```markdown
---
name: skill-name
description: >
  [One-line: what it does]. Use when [trigger scenario].
  Triggers on [trigger phrase 1], [trigger phrase 2].
  Do NOT use for [exclusion scenario].
allowed-tools: Read, Grep, Bash
---

# Skill Name

[Instructions in Markdown]

## Workflow
1. Step one
2. Step two

## Checklist
- [ ] Verification step
```

### Template: Full Skill

```markdown
---
name: skill-name
description: >
  [what it does, when to trigger]
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep
model: sonnet
---

# Skill Name

## Activation
Use when: [trigger scenarios]
Skip if: [exclusions]

## Workflow

### 1. Decision Step
[Scenarios → actions table]

### 2. Core Process
[Numbered steps]

### 3. Validation
[Self-check items]

## Boundaries
[What this skill explicitly does NOT do]

## Example
```markdown
[Example output or template]
```
```

## Phase 3: Generation

Generate the SKILL.md following these quality criteria:

- [ ] description 包含 trigger phrases 和 exclusion
- [ ] 最小权限原则
- [ ] 有明确的工作流步骤
- [ ] 有验证闭环（自检清单）
- [ ] 有边界说明（不做什么）
- [ ] 正反例对比
- [ ] body 简洁，无废话

## Phase 4: Validation

Check the generated skill:
- [ ] 文件路径正确：`.claude/skills/{name}/SKILL.md`
- [ ] Frontmatter 格式正确（YAML --- 分隔符）
- [ ] description 对触发条件的描述足够明确
- [ ] 不适用场景已写清
- [ ] 工具列表为最小权限
- [ ] 命令可以在项目根目录运行
