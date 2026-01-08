---
name: work
description: REQUIRED for starting work on GitHub issues. When user says "work on issue X", "start issue X", "fix issue X", or similar - ALWAYS use this skill to spawn a dedicated worker session instead of working in the current session.
---

# Work Script

**IMPORTANT: When the user asks to work on, start, or fix a GitHub issue, USE THIS SKILL to spawn a dedicated worker. Do NOT work on the issue in the current session unless explicitly told to (e.g., "work on issue 42 here" or "in this session").**

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
# repo_name          | issue | stage           | in_stage | pr   | status
# hawkins-dash       | 12    | implementing    | 15m      | -    | running
# dotfiles           | 45    | ci_waiting      | 8m       | #47  | running
# hawkins-dash       | 34    | review_waiting  | 1h       | #46  | running

# Show recent events (optionally filtered by issue)
work --events
work --events 42

# View events for a specific worker
work --logs 42

# Stop a specific worker
work --stop 42
```

### Issue Argument Syntax

All worker management commands support flexible issue lookups:

```bash
# By issue number (defaults to current repo)
work --stop 42
work --logs 42

# By PR number (searches both issue_number and pr_number)
work --logs 47                  # Finds worker by its PR number

# Explicit repo (for cross-repo management)
work --stop hawkins-dash:42     # Stop issue 42 in hawkins-dash repo
work --send myrepo:50 "message" # Send message to worker in different repo
```

This is useful when managing workers across multiple repositories simultaneously.

## Stage Tracking

Workers report their current stage for better visibility. Stages are:

| Stage | Description |
|-------|-------------|
| `exploring` | Reading issue, understanding codebase |
| `planning` | Designing approach, creating todo list |
| `implementing` | Writing code |
| `testing` | Running local tests |
| `pr_creating` | Creating PR, writing description |
| `ci_waiting` | PR created, waiting for CI to pass |
| `review_waiting` | CI passed, waiting for review |
| `review_responding` | Addressing review feedback |
| `merge_conflicts` | Resolving merge conflicts |
| `done` | PR merged or issue closed |
| `blocked` | Waiting on external dependency |

Workers update their stage via:
```bash
work --stage implementing      # Set current stage
work --stage ci_waiting --pr 47  # Set stage with PR number
```

## Parent-to-Worker Messaging

Send messages from a parent session to workers:

```bash
# Send a message to a worker
work --send 42 "Check the updated API spec before continuing"
work --send 42 --type priority "This is now high priority"
work --send 42 --type context "The database schema changed, see PR #123"

# View pending messages (marks as read by default)
work --messages 42              # View messages for issue #42 (marks as read)
work --messages                 # From within worker, uses WORK_WORKER_ID
work --messages 42 --peek       # View without marking as read
```

Message types:
- `info` (default) - General information
- `priority` - Priority change notifications
- `context` - Additional context or requirements
- `instruction` - Specific instructions to follow

## What it does

1. Parses GitHub issue/PR URLs or numbers
2. Fetches issue title from GitHub for branch naming
3. Creates or reuses a git worktree at `~/.worktrees/{repo}/{branch}` (repo-isolated)
4. Registers worker in SQLite database for monitoring
5. Starts Claude Code with a structured prompt for end-to-end completion
6. Tracks worker status and stage for visibility into workflow progress

## Auto-Detection Hooks

When installed, Claude Code hooks automatically detect workflow events and update worker status:

| Event | Resulting Status | Phase |
|-------|-----------------|-------|
| `gh pr create` | `ci_waiting` | `ci_review` |
| CI passes (`gh pr checks`) | `review_waiting` | `review` |
| `gh pr merge` | `merged` | `follow_up` |
| Merge/rebase conflicts | `merge_conflicts` | `blocked` |
| Conflict resolved | `running` | `implementation` |

### Installing Hooks

```bash
# Run the installer from your dotfiles repo
./genai/hooks/install-hooks.sh
```

This installs a PostToolUse hook that monitors Bash commands and automatically updates the worker database.

### How It Works

The hook script (`~/.claude/hooks/work-stage-detector.sh`):
1. Runs after every Bash tool call
2. Parses the command and output from the hook input
3. Detects workflow events (PR creation, CI checks, merges, conflicts)
4. Updates the worker's status/phase in the SQLite database
5. Logs events for tracking via `work --events`

This eliminates manual stage reporting, ensuring accurate workflow progression tracking.

## Database

Worker state is stored in `~/.worktrees/work-sessions.db` with four tables:
- `workers` - Active worker metadata (repo, issue, branch, PID, status, stage, pr_number)
- `events` - History of status changes, stage transitions, and events
- `completions` - Final summaries when workers complete
- `messages` - Parent-to-worker message queue

## Directory Structure

Worktrees are organized by repository to prevent issue number collisions:

```
~/.worktrees/
├── work-sessions.db          # Shared SQLite database
├── hawkins-dash/
│   ├── issue-42-fix-auth/
│   └── issue-99-add-metrics/
└── dotfiles/
    └── issue-15-work-hooks/
```

## Environment variables

- `MAIN_BRANCH` - Base branch for new branches (default: main)
- `WORKTREE_BASE` - Directory for worktrees (default: ~/.worktrees)
- `SPAWN_DELAY` - Delay between tab spawns (default: 0.5s)

Workers also export these variables for use by Claude Code:
- `WORK_WORKER_ID` - Database ID of the current worker
- `WORK_DB_PATH` - Path to the SQLite database

## When to use this skill

**ALWAYS use this skill when the user:**
- Says "work on issue X", "start issue X", "fix issue X", "implement issue X"
- Wants to work on a GitHub issue (spawn a worker, don't work here)
- Asks to work on multiple issues in parallel
- Wants to check on running workers (`work --status`)
- Needs to send messages to workers (`work --send`)
- Wants to stop a worker (`work --stop`)

**DO NOT use this skill when:**
- User explicitly says "work on it here" or "in this session"
- User is asking about the work script itself (just answer the question)
- User wants to see worker status (use `work --status` directly via Bash)

## Note

This script is designed to run *outside* Claude Code to start new sessions. If run from within a Claude Code session, it outputs the task info instead of starting a nested session.
