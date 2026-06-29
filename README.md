# zcx-cc — Claude Code Personal Config

Skills, plugins, commands, and settings for Claude Code, synced across machines.

## Usage on a new machine

```bash
# 1. Clone
git clone https://github.com/zcxxxxxxx/zcx-cc.git ~/.claude-sync

# 2. Install plugins
#   - academic-research-skills: claude plugin install "github:Imbad0202/academic-research-skills"
#   - superpowers:            claude plugin install "github:obra/superpowers"
#   - karpathy-skills:        claude plugin install "github:forrestchang/andrej-karpathy-skills"
#   - frontend-design:        claude plugin install "@anthropic/frontend-design"
#   - skill-creator:          claude plugin install "@anthropic/skill-creator"
#   - local-tools:            (copy plugins/local/local-tools to ~/.claude/plugins/local/)

# 3. Copy commands
cp -r ~/.claude-sync/commands/* ~/.claude/commands/

# 4. Copy skills
cp -r ~/.claude-sync/skills/* ~/.claude/skills/

# 5. Copy settings (EDIT TOKEN FIRST!)
cp ~/.claude-sync/settings.json ~/.claude/settings.json
# Then edit ~/.claude/settings.json → replace YOUR_TOKEN_HERE with your actual token
```

## Plugins

| Plugin | Version | Source | Purpose |
|--------|---------|--------|---------|
| **academic-research-skills** | 3.9.3 | [Imbad0202/academic-research-skills](https://github.com/Imbad0202/academic-research-skills) (CC-BY-NC-4.0) | 学术论文全周期：研究→写作→审稿→修订。4 skill + 35+ mode + 38-agent 集成 |
| **superpowers** | 5.1.0 | [obra/superpowers](https://github.com/obra/superpowers) (MIT) | 核心技能库：TDD、debugging、brainstorming、代码审查、plan 编写、并行 agent 调度 |
| **andrej-karpathy-skills** | 1.0.0 | [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (MIT) | Karpathy 编码准则：减少 LLM 常见编码错误 |
| **frontend-design** | — | Anthropic 官方 | 前端 UI/UX 设计与实现 |
| **skill-creator** | — | Anthropic 官方 | Skill 创建、评测、迭代优化、description 优化 |
| **local-tools** | — | 本地目录 | 本地工具封装：harness-engineering + opencli-browser-automation（由插件系统统一加载） |

## Custom Skills

| Skill | Purpose |
|-------|---------|
| **harness-engineering** | 复杂多步任务的持久化工作流：plan、日志、验证记录、决策记录 |
| **opencli-browser-automation** | 浏览器自动化（Web 搜索、页面操作、截图），用于信息检索 |
| **git-pushing** | Git commit/push 工作流，自动生成 conventional commit |
| **claude-md-maintainer** | CLAUDE.md 创建、审查、维护 |
| **paper-workflow** | 学术论文全流程：IMRaD 结构指导（含 JCP/JFM 期刊规范）+ 27 项终审检查清单 |
| **latex-sentence-wrap** | LaTeX 句子换行格式化（一句一行） |
| **translate-book** | 书籍翻译 skill |
| **skill-generator** | Skill 生成器 |
| **hunong-teacher** | 护农教学相关 |

## Commands

| Command | Purpose |
|---------|---------|
| `create-deck` | 创建 deck 演示文稿 |
| `critique-deck` | 审阅 deck |
| `demo-cycle` | 演示循环 |
| `docx-batch` / `docx-sarukas` / `docx-skill` | DOCX 文档处理 |
| `edit-slide` | 编辑幻灯片 |
| `learn-template` | 学习模板 |
| `polish-deck` | 润色 deck |
| `review-deck` | 审查 deck |

## ⚠️ Important

- `settings.json` contains a **token placeholder** — replace with your real token after copying
- `settings.json` references local plugin paths (e.g., `local-tools`) — adjust path for your machine
- Each machine may need its own `~/.claude.json` for GitHub OAuth
