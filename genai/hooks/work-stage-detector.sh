#!/bin/bash
# work-stage-detector.sh - Claude Code hook for auto-detecting work stage transitions
#
# This PostToolUse hook detects workflow events from Bash commands and updates
# the worker's stage in the SQLite database. It supports:
#
#   Event                    | Resulting Stage
#   -------------------------|----------------
#   gh pr create             | ci_waiting
#   CI passes (gh pr checks) | review_waiting
#   gh pr merge              | done
#   Merge/rebase conflicts   | merge_conflicts

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Check if we have required environment variables
if [[ -z "${WORK_WORKER_ID:-}" ]] || [[ -z "${WORK_DB_PATH:-}" ]]; then
    exit 0
fi

# Verify database exists
if [[ ! -f "$WORK_DB_PATH" ]]; then
    exit 0
fi

# Extract tool info using jq
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty')

# Only process Bash tool calls
if [[ "$TOOL_NAME" != "Bash" ]]; then
    exit 0
fi

COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // empty')
STDOUT=$(echo "$HOOK_INPUT" | jq -r '.tool_response.stdout // empty' 2>/dev/null || echo "")
STDERR=$(echo "$HOOK_INPUT" | jq -r '.tool_response.stderr // empty' 2>/dev/null || echo "")
EXIT_CODE=$(echo "$HOOK_INPUT" | jq -r '.tool_response.exitCode // .tool_response.exit_code // "0"' 2>/dev/null || echo "0")
RESPONSE="${STDOUT}${STDERR}"

# Helper function to update worker status, stage, and log event
update_worker() {
    local status="$1"
    local phase="$2"
    local stage="$3"
    local event_type="$4"
    local message="$5"

    sqlite3 "$WORK_DB_PATH" <<SQL
UPDATE workers
SET status='$status', phase='$phase', stage='$stage', updated_at=CURRENT_TIMESTAMP
WHERE id=$WORK_WORKER_ID;

INSERT INTO events (worker_id, event_type, message)
VALUES ($WORK_WORKER_ID, '$event_type', '$message');
SQL
}

# Helper function to log event only (no status change)
log_event() {
    local event_type="$1"
    local message="$2"

    sqlite3 "$WORK_DB_PATH" "INSERT INTO events (worker_id, event_type, message) VALUES ($WORK_WORKER_ID, '$event_type', '$message');"
}

# Helper function to update PR info
update_pr_info() {
    local pr_number="$1"
    local pr_url="$2"

    sqlite3 "$WORK_DB_PATH" <<SQL
UPDATE workers
SET pr_number=$pr_number, pr_url='$pr_url', status='ci_waiting', phase='ci_review', stage='ci_waiting', updated_at=CURRENT_TIMESTAMP
WHERE id=$WORK_WORKER_ID;

INSERT INTO events (worker_id, event_type, message)
VALUES ($WORK_WORKER_ID, 'pr_created', 'PR #$pr_number created');
SQL
}

# Detect PR creation: gh pr create or ghe pr create
if [[ "$COMMAND" =~ gh[e]?[[:space:]]+pr[[:space:]]+create ]] && [[ "$EXIT_CODE" == "0" ]]; then
    # Extract PR URL from output (format: https://github.com/owner/repo/pull/123)
    PR_URL=$(echo "$STDOUT" | grep -oE 'https://[^[:space:]]+/pull/[0-9]+' | head -1 || true)

    if [[ -n "$PR_URL" ]]; then
        # Extract PR number from URL
        PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$')
        if [[ -n "$PR_NUMBER" ]]; then
            update_pr_info "$PR_NUMBER" "$PR_URL"
        fi
    fi
    exit 0
fi

# Detect CI check results: gh pr checks
if [[ "$COMMAND" =~ gh[e]?[[:space:]]+pr[[:space:]]+checks ]]; then
    # Check if watching (--watch flag)
    if [[ "$COMMAND" =~ --watch ]]; then
        # For --watch, we need to check the final status
        if echo "$STDOUT" | grep -qiE '(fail|error)'; then
            log_event "ci_failure" "CI checks failed"
        elif echo "$STDOUT" | grep -qiE '(pass|success|✓)' && ! echo "$STDOUT" | grep -qiE '(pending|running|queued)'; then
            # All checks passed - transition to review_waiting
            update_worker "review_waiting" "review" "review_waiting" "ci_passed" "All CI checks passed"
        fi
    else
        # Non-watch mode: just log the check
        if echo "$STDOUT" | grep -qiE '(fail|error)'; then
            log_event "ci_check" "CI checks show failures"
        elif echo "$STDOUT" | grep -qiE '(pass|success|✓)'; then
            if ! echo "$STDOUT" | grep -qiE '(pending|running|queued)'; then
                update_worker "review_waiting" "review" "review_waiting" "ci_passed" "All CI checks passed"
            fi
        fi
    fi
    exit 0
fi

# Detect PR merge: gh pr merge
if [[ "$COMMAND" =~ gh[e]?[[:space:]]+pr[[:space:]]+merge ]] && [[ "$EXIT_CODE" == "0" ]]; then
    # Check if merge was successful from output
    if echo "$RESPONSE" | grep -qiE '(merged|successfully)'; then
        update_worker "merged" "follow_up" "done" "pr_merged" "PR merged successfully"
    fi
    exit 0
fi

# Detect resolved conflicts: git rebase --continue or git merge --continue
# NOTE: This must come BEFORE the conflict detection check since both match git rebase/merge
if [[ "$COMMAND" =~ git[[:space:]]+(rebase|merge)[[:space:]]+--continue ]] && [[ "$EXIT_CODE" == "0" ]]; then
    # Get current status to see if we were in merge_conflicts
    CURRENT_STATUS=$(sqlite3 "$WORK_DB_PATH" "SELECT status FROM workers WHERE id=$WORK_WORKER_ID;")
    if [[ "$CURRENT_STATUS" == "merge_conflicts" ]]; then
        update_worker "running" "implementation" "implementing" "conflict_resolved" "Merge conflicts resolved"
    fi
    exit 0
fi

# Detect merge conflicts from git rebase or git merge
if [[ "$COMMAND" =~ git[[:space:]]+(rebase|merge|pull) ]]; then
    if echo "$RESPONSE" | grep -qiE '(CONFLICT|conflict|Automatic merge failed)'; then
        update_worker "merge_conflicts" "blocked" "merge_conflicts" "conflict_detected" "Merge conflict detected"
    fi
    exit 0
fi

exit 0
