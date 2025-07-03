#!/usr/bin/env bash
set -e

# usage: ./commit_and_push.sh [branch] [commit message]
branch=${1:-main}
message=${2:-"feat: implement end-to-end guest join flow"}

# 1. Checkout (or create) the branch
if git show-ref --verify --quiet refs/heads/"$branch"; then
  git checkout "$branch"
else
  git checkout -b "$branch"
fi

# 2. Stage all changes
git add .

# 3. Commit
git commit -m "$message"

# 4. Ensure remote 'origin' exists (prompt if not)
if ! git remote get-url origin &>/dev/null; then
  read -p "Remote 'origin' not found. Enter remote URL: " remote_url
  git remote add origin "$remote_url"
fi

# 5. Push and set upstream
git push -u origin "$branch"

echo "✅ Pushed to origin/$branch"