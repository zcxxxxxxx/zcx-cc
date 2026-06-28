---
name: git-pushing
description: Stage, commit, and push git changes with conventional commit messages. AUTO-TRIGGER: after completing a task that modified repo files, automatically create a commit (do NOT push unless asked). Also triggers when user says "push", "commit", "save work", "提交", or similar git workflow requests.
---

# Git Push Workflow

Two modes: **auto-commit** (after task completion, no push) and **manual push** (user explicitly asks).

## Mode 1: Auto-Commit (after task completion)

**Triggers automatically** when a task that modified repo files is complete.

Do NOT ask the user — just run it. Only commit Claude's own changes, not unrelated pre-existing user changes.

```bash
bash "$CLAUDE_SKILL_DIR/scripts/auto_commit.sh"
```

With custom message:
```bash
bash "$CLAUDE_SKILL_DIR/scripts/auto_commit.sh" "feat: add rank-4 LoRA sweep"
```

**This script commits but NEVER pushes.** To push, the user must explicitly ask.

## Mode 2: Manual Push (user-initiated)

Use when the user explicitly says "push", "commit and push", "save to remote", etc.

```bash
bash "$CLAUDE_SKILL_DIR/scripts/smart_commit.sh"
```

With custom message:
```bash
bash "$CLAUDE_SKILL_DIR/scripts/smart_commit.sh" "feat: add feature"
```

Script handles: staging, conventional commit message, Claude footer, push with -u flag.
