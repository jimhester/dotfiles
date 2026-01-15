#!/bin/bash
# work-stage-detector.sh - Claude Code hook for auto-detecting work stage transitions
#
# This PostToolUse hook detects workflow events from Bash commands and updates
# the worker's stage via the work CLI. It also checks for pending messages after
# every command to ensure timely delivery. It supports:
#
#   Event                    | Resulting Stage
#   -------------------------|----------------
#   gh pr create             | ci_waiting
#   CI passes (gh pr checks) | review_waiting
#   gh pr merge              | done
#   Merge/rebase conflicts   | merge_conflicts
#
# Additionally, after every Bash command, it checks for and displays any pending
# messages sent to this worker via `work --send`.

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Check if we have required environment variables
if [[ -z "${WORK_WORKER_ID:-}" ]]; then
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

# Find work script
WORK_SCRIPT="${HOME}/dotfiles/genai/work"
if [[ ! -x "$WORK_SCRIPT" ]]; then
    exit 0
fi

# Detect PR creation: gh pr create or ghe pr create
if [[ "$COMMAND" =~ gh[e]?[[:space:]]+pr[[:space:]]+create ]] && [[ "$EXIT_CODE" == "0" ]]; then
    # Extract PR URL from output (format: https://github.com/owner/repo/pull/123)
    PR_URL=$(echo "$STDOUT" | grep -oE 'https://[^[:space:]]+/pull/[0-9]+' | head -1 || true)

    if [[ -n "$PR_URL" ]]; then
        # Extract PR number from URL
        PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$')
        if [[ -n "$PR_NUMBER" ]]; then
            "$WORK_SCRIPT" --pr "$PR_NUMBER" "$PR_URL" >/dev/null 2>&1 || true
        fi
    fi

# Detect CI check results: gh pr checks
elif [[ "$COMMAND" =~ gh[e]?[[:space:]]+pr[[:space:]]+checks ]]; then
    # Check if watching (--watch flag)
    if [[ "$COMMAND" =~ --watch ]]; then
        # For --watch, we need to check the final status
        if echo "$STDOUT" | grep -qiE '(fail|error)'; then
            "$WORK_SCRIPT" --event "ci_failure" "CI checks failed" >/dev/null 2>&1 || true
        elif echo "$STDOUT" | grep -qiE '(pass|success|✓)' && ! echo "$STDOUT" | grep -qiE '(pending|running|queued)'; then
            # All checks passed - transition to review_waiting
            "$WORK_SCRIPT" --transition "review_waiting" "review" "review_waiting" "ci_passed" "All CI checks passed" >/dev/null 2>&1 || true
        fi
    else
        # Non-watch mode: just log the check
        if echo "$STDOUT" | grep -qiE '(fail|error)'; then
            "$WORK_SCRIPT" --event "ci_check" "CI checks show failures" >/dev/null 2>&1 || true
        elif echo "$STDOUT" | grep -qiE '(pass|success|✓)'; then
            if ! echo "$STDOUT" | grep -qiE '(pending|running|queued)'; then
                "$WORK_SCRIPT" --transition "review_waiting" "review" "review_waiting" "ci_passed" "All CI checks passed" >/dev/null 2>&1 || true
            fi
        fi
    fi

# Detect PR merge: gh pr merge
elif [[ "$COMMAND" =~ gh[e]?[[:space:]]+pr[[:space:]]+merge ]] && [[ "$EXIT_CODE" == "0" ]]; then
    # Check if merge was successful from output
    if echo "$RESPONSE" | grep -qiE '(merged|successfully)'; then
        "$WORK_SCRIPT" --transition "merged" "follow_up" "done" "pr_merged" "PR merged successfully" >/dev/null 2>&1 || true
    fi

# Detect resolved conflicts: git rebase --continue or git merge --continue
# NOTE: This must come BEFORE the conflict detection check since both match git rebase/merge
elif [[ "$COMMAND" =~ git[[:space:]]+(rebase|merge)[[:space:]]+--continue ]] && [[ "$EXIT_CODE" == "0" ]]; then
    # Transition back to implementing (CLI handles the state check)
    "$WORK_SCRIPT" --transition "running" "implementation" "implementing" "conflict_resolved" "Merge conflicts resolved" >/dev/null 2>&1 || true

# Detect merge conflicts from git rebase or git merge
elif [[ "$COMMAND" =~ git[[:space:]]+(rebase|merge|pull) ]]; then
    if echo "$RESPONSE" | grep -qiE '(CONFLICT|conflict|Automatic merge failed)'; then
        "$WORK_SCRIPT" --transition "merge_conflicts" "blocked" "merge_conflicts" "conflict_detected" "Merge conflict detected" >/dev/null 2>&1 || true
    fi
fi

# Check for pending messages and display them
# This ensures workers receive messages in a timely manner
"$WORK_SCRIPT" --messages --quiet 2>&1 || true

exit 0
