# zcx-cc — Claude Code Personal Config

Skills, commands, and settings for Claude Code, synced across machines.

## Usage on a new machine

```bash
# 1. Clone
git clone https://github.com/zcxxxxxxx/zcx-cc.git ~/.claude-sync

# 2. Install plugins
xargs -I {} claude plugin install "{}" < ~/.claude-sync/plugins.txt

# 3. Copy commands
cp ~/.claude-sync/commands/* ~/.claude/commands/

# 4. Copy skills
cp -r ~/.claude-sync/skills/* ~/.claude/skills/

# 5. Copy settings (EDIT TOKEN FIRST!)
cp ~/.claude-sync/settings.json ~/.claude/settings.json
# Then edit ~/.claude/settings.json → replace YOUR_TOKEN_HERE with your actual token
```

## Contents

| Path | Description |
|------|-------------|
| `commands/` | Slash command skills (create-deck, critique-deck, docx-*, etc.) |
| `skills/` | Full skill packages (harness-engineering, claude-md-maintainer, etc.) |
| `settings.json` | Global settings template (fill in YOUR_TOKEN_HERE) |
| `plugins.txt` | Plugin manifest for bulk install |

## ⚠️ Important

- `settings.json` contains a **token placeholder** — replace with your real token after copying
- Each machine may need its own `~/.claude.json` for GitHub OAuth
