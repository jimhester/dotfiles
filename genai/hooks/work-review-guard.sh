#!/bin/bash
# work-review-guard.sh - Block PR operations without passing self-review
#
# PreToolUse hook for Claude Code that enforces running `work --review`
# before `gh pr create` and `work --review --pre-merge` before `gh pr merge`.
#
# The hook checks for a .work-review-status file in the repo root that is:
# 1. Present
# 2. Newer than the last commit
# 3. Contains "APPROVED"

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract tool info using jq
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty')

# Only process Bash tool calls
if [[ "$TOOL_NAME" != "Bash" ]]; then
    exit 0
fi

COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // empty')

# Check for gh pr create or gh pr merge
if [[ "$COMMAND" =~ gh[e]?[[:space:]]+pr[[:space:]]+create ]]; then
    ACTION="create"
    REVIEW_CMD="work --review"
elif [[ "$COMMAND" =~ gh[e]?[[:space:]]+pr[[:space:]]+merge ]]; then
    ACTION="merge"
    REVIEW_CMD="work --review --pre-merge"
else
    exit 0
fi

# Find repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "$REPO_ROOT" ]]; then
    exit 0  # Not in a git repo, let it proceed
fi

# Check for review marker file
REVIEW_MARKER="$REPO_ROOT/.work-review-status"

if [[ ! -f "$REVIEW_MARKER" ]]; then
    cat << EOF
{"decision": "block", "reason": "Must run $REVIEW_CMD before $ACTION"}
EOF
    cat >&2 << EOF

🛑 BLOCKED: Run '$REVIEW_CMD' before attempting to $ACTION PR

No review has been run yet. Before you can $ACTION a PR, you must:
1. Run: $REVIEW_CMD
2. Address any issues found
3. Try again

EOF
    exit 0
fi

# Check if review is newer than last commit
LAST_COMMIT_TIME=$(git log -1 --format=%ct 2>/dev/null || echo "0")
REVIEW_TIME=$(stat -c %Y "$REVIEW_MARKER" 2>/dev/null || stat -f %m "$REVIEW_MARKER" 2>/dev/null || echo "0")

if [[ "$REVIEW_TIME" -lt "$LAST_COMMIT_TIME" ]]; then
    cat << EOF
{"decision": "block", "reason": "Review is stale - new commits since last review"}
EOF
    cat >&2 << EOF

🛑 BLOCKED: New commits since last review

Your review is out of date. Since your last review, new commits have been made.
Please run '$REVIEW_CMD' again to review the latest changes.

EOF
    exit 0
fi

# Check if review passed (case-insensitive)
if ! grep -qi "APPROVED" "$REVIEW_MARKER" 2>/dev/null; then
    cat << EOF
{"decision": "block", "reason": "Last review found issues"}
EOF
    cat >&2 << EOF

🛑 BLOCKED: Last review found issues

Your last review identified issues that need to be addressed.
Please:
1. Review the issues in $REVIEW_MARKER
2. Fix the issues
3. Commit your fixes
4. Run '$REVIEW_CMD' again
5. Try again once the review passes

EOF
    exit 0
fi

# All checks passed, allow the command
exit 0
