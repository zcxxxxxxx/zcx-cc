#!/bin/bash
# Auto-commit script — commits without pushing
# Used after task completion. For push, use smart_commit.sh instead.
set -e

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "→ Current branch: $CURRENT_BRANCH"

# Check if there are changes
if git diff --quiet && git diff --cached --quiet; then
    echo "⚠ No changes to commit"
    exit 0
fi

# Stage all changes (Claude's own changes only — user's pre-existing changes are excluded by instruction)
git add .

STAGED_FILES=$(git diff --cached --name-only)
NUM_FILES=$(echo "$STAGED_FILES" | wc -l | xargs)

# Generate commit message
SCOPE=$(echo "$STAGED_FILES" | head -1 | cut -d'/' -f1)
MSG="chore: update $NUM_FILES file(s)"
if [ -n "$SCOPE" ]; then
    MSG="chore(${SCOPE}): update $NUM_FILES file(s)"
fi

if [ -n "$1" ]; then
    MSG="$1"
fi

git commit -m "$(cat <<EOF
${MSG}

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

echo "→ Created commit: $(git rev-parse --short HEAD)"
echo "→ NOT pushed to remote (auto-commit policy)"
