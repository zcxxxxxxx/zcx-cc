# Global Claude Instructions

## Default Skills

The following skills should be used by default in all projects:

### harness-engineering

For any complex, multi-step task (implementing a feature, running experiments, multi-file changes, CFD/ML validation, paper-grade verification, or any task where future agents must resume from repo artifacts), invoke the `harness-engineering` skill before starting work.

Trigger criteria:
- Task requires 3+ distinct steps or touches multiple files
- Task involves long-running experiments or validation
- Task needs durable handoffs or progress tracking across sessions
- User mentions "做实验" (running experiments), "跑仿真" (simulation), "复现" (reproduce), "验证" (validation/verification), "记录决策" (recording decisions), or "paper 提交" (paper submission)

### claude-md-maintainer

Use `claude-md-maintainer` whenever CLAUDE.md is created, changed, reviewed, or discussed. Every edit to CLAUDE.md should pass through this skill. Also use when creating/initializing CLAUDE.md, reviewing/improving an existing CLAUDE.md, or turning repeated mistakes into durable rules.

## Git Management

If the current working directory is a git repository, use `git-pushing` skill for git operations:
- After completing a task that changed repository files, automatically create a git commit for Claude's own changes only
- Do not push unless the user explicitly asks
- Do not include unrelated pre-existing user changes in the commit
- For any git workflow (status, diff, commit, push, branch, log, etc.), prefer using the `git-pushing` skill

## Search Strategy

When performing web searches, file searches, or information retrieval tasks:
- First try using `opencli-browser-automation` for browser-based searches
- Fall back to the built-in WebSearch tool if opencli is not available or inappropriate
