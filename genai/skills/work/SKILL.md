---
name: work
description: Start Claude Code sessions for GitHub issues using git worktrees. Use when discussing the work script, starting new issue work, or managing multiple tasks in parallel.
---

# Work Script

The `work` script creates isolated Claude Code sessions for GitHub issues using git worktrees, with SQLite-based worker monitoring for managing multiple parallel sessions.

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

## Worker Management

Monitor and control spawned workers from a parent session:

```bash
# Show all active workers across repos
work --status
# repo_name          | issue | status   | phase          | mins_idle
# hawkins-dash       | 12    | running  | implementation | 2
# dotfiles           | 45    | ci_wait  | ci_review      | 8

# Show recent events (optionally filtered by issue)
work --events
work --events 42

# View events for a specific worker
work --logs 42

# Stop a specific worker
work --stop 42
```

## Parent-to-Worker Messaging

Send messages from a parent session to workers:

```bash
# Send a message to a worker
work --send 42 "Check the updated API spec before continuing"
work --send 42 --type priority "This is now high priority"
work --send 42 --type context "The database schema changed, see PR #123"

# View pending messages (from parent or worker)
work --messages 42              # View messages for issue #42
work --messages                 # From within worker, uses WORK_WORKER_ID
work --messages 42 --mark-read  # View and mark as read
```

Message types:
- `info` (default) - General information
- `priority` - Priority change notifications
- `context` - Additional context or requirements
- `instruction` - Specific instructions to follow

## What it does

1. Parses GitHub issue/PR URLs or numbers
2. Fetches issue title from GitHub for branch naming
3. Creates or reuses a git worktree with branch `issue-{num}-{slug}`
4. Registers worker in SQLite database for monitoring
5. Starts Claude Code with a structured prompt for end-to-end completion
6. Tracks worker status (starting, running, pr_open, ci_waiting, done, failed)

## Database

Worker state is stored in `~/.worktrees/work-sessions.db` with four tables:
- `workers` - Active worker metadata (repo, issue, branch, PID, status, phase)
- `events` - History of status changes and events
- `completions` - Final summaries when workers complete
- `messages` - Parent-to-worker message queue

## Environment variables

- `MAIN_BRANCH` - Base branch for new branches (default: main)
- `WORKTREE_BASE` - Directory for worktrees (default: ~/.worktrees)
- `SPAWN_DELAY` - Delay between tab spawns (default: 0.5s)

Workers also export these variables for use by Claude Code:
- `WORK_WORKER_ID` - Database ID of the current worker
- `WORK_DB_PATH` - Path to the SQLite database

## When to suggest this script

If the user wants to:
- Start working on a different GitHub issue
- Work on multiple issues in parallel
- Create an isolated environment for a task
- Monitor status of running workers
- Stop a runaway worker process
- Send messages/instructions to running workers

Suggest they exit the current session and run `work <issue>` from their terminal.

## Note

This script is designed to run *outside* Claude Code to start new sessions. If run from within a Claude Code session, it outputs the task info instead of starting a nested session.
