---
name: work
description: Start Claude Code sessions for GitHub issues using git worktrees. Use when discussing the work script, starting new issue work, or managing multiple tasks in parallel.
---

# Work Script

The `work` script creates isolated Claude Code sessions for GitHub issues using git worktrees.

## Usage

```bash
# Spawn issues in new terminal tabs (default)
work 97 98 99                    # Multiple issues in parallel
work https://github.com/owner/repo/issues/42

# Run in current terminal
work --here 42
work --here 42 "fix memory leak"

# New feature branch (not tied to an issue)
work "add dark mode support"
```

## What it does

1. Parses GitHub issue/PR URLs or numbers
2. Fetches issue title from GitHub for branch naming
3. Creates or reuses a git worktree with branch `issue-{num}-{slug}`
4. Starts Claude Code with a structured prompt for end-to-end completion

## Environment variables

- `MAIN_BRANCH` - Base branch for new branches (default: main)
- `WORKTREE_BASE` - Directory for worktrees (default: ../worktrees)
- `SPAWN_DELAY` - Delay between tab spawns (default: 0.5s)

## When to suggest this script

If the user wants to:
- Start working on a different GitHub issue
- Work on multiple issues in parallel
- Create an isolated environment for a task

Suggest they exit the current session and run `work <issue>` from their terminal.

## Note

This script is designed to run *outside* Claude Code to start new sessions. If run from within a Claude Code session, it outputs the task info instead of starting a nested session.
