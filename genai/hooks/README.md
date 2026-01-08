# Work Stage Detection Hooks

This directory contains Claude Code hooks for auto-detecting work stage transitions.

## Overview

The `work-stage-detector.sh` hook automatically detects workflow events from Bash commands and updates the worker's status in the SQLite database.

### Supported Stage Transitions

| Event | Resulting Stage | Phase |
|-------|-----------------|-------|
| `gh pr create` | `ci_waiting` | `ci_review` |
| CI passes (`gh pr checks`) | `review_waiting` | `review` |
| `gh pr merge` | `merged` | `follow_up` |
| Merge/rebase conflicts | `merge_conflicts` | `blocked` |
| Conflict resolved | `running` | `implementation` |

## Installation

### Automatic Installation

Run the installation script:

```bash
./genai/hooks/install-hooks.sh
```

### Manual Installation

1. Copy or symlink the hook to your Claude hooks directory:

```bash
mkdir -p ~/.claude/hooks
ln -sf "$(pwd)/genai/hooks/work-stage-detector.sh" ~/.claude/hooks/
```

2. Add the hook configuration to your Claude settings (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/work-stage-detector.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

## Requirements

- `jq` must be installed for JSON parsing
- `sqlite3` must be installed for database updates
- Environment variables `WORK_WORKER_ID` and `WORK_DB_PATH` must be set (automatically set by the `work` script)

## How It Works

1. The hook runs after every Bash tool call in Claude Code
2. It parses the command and output from the hook input (JSON via stdin)
3. It detects workflow events (PR creation, CI checks, merges, conflicts)
4. It updates the worker's status/phase in the SQLite database
5. It logs events to the `events` table for tracking

## Debugging

To see hook activity, check the events table:

```bash
sqlite3 ~/.worktrees/work-sessions.db "SELECT * FROM events ORDER BY created_at DESC LIMIT 20;"
```

Or use the work script:

```bash
work --events
```
