#!/usr/bin/env bash
set -euo pipefail

DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
REMOTE_NAME="${REMOTE_NAME:-origin}"
COMMIT_MESSAGE="${1:-Update LLM Wiki}"

cd "$(dirname "$0")/.."

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -b "$DEFAULT_BRANCH"
fi

if ! git remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
  cat <<EOF >&2
Git remote '$REMOTE_NAME' is not configured.

Run this once, replacing the URL with your GitHub repository:
  git remote add $REMOTE_NAME git@github.com:YOUR_USER/YOUR_REPO.git

Then run:
  ./scripts/sync-wiki-to-github.sh
EOF
  exit 1
fi

# Keep private capture folders and local Obsidian state out of GitHub even if
# they were accidentally tracked before .gitignore existed.
git rm -r --cached --ignore-unmatch raw obsidian .obsidian >/dev/null 2>&1 || true

git add -A

if git diff --cached --quiet; then
  echo "No new local wiki changes to commit."
else
  git commit -m "$COMMIT_MESSAGE"
fi

if git ls-remote --exit-code --heads "$REMOTE_NAME" "$DEFAULT_BRANCH" >/dev/null 2>&1; then
  git pull --rebase "$REMOTE_NAME" "$DEFAULT_BRANCH"
fi

git push -u "$REMOTE_NAME" "$DEFAULT_BRANCH"
