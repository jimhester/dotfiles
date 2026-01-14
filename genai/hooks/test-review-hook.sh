#!/bin/bash
# Test script for work --review and work-review-guard.sh hook
# Run this outside of Claude Code to verify the flow works correctly

set -e

echo "=== Setting up test repo ==="
cd /tmp && rm -rf test-review-repo && mkdir test-review-repo && cd test-review-repo
git init && git commit --allow-empty -m "Initial"
git branch -m main && git branch origin/main HEAD
echo "test" > file.txt && git add . && git commit -m "Change"
echo ""

echo "=== Test 1: Passing review (should exit 0) ==="
~/dotfiles/genai/work --review --dry-run pass
echo "Exit code: $?"
echo ""

echo "=== Test 2: Git note was stored ==="
git notes --ref=reviews show HEAD
echo ""

echo "=== Test 3: Hook should ALLOW after passing review ==="
output=$(echo '{"tool_name": "Bash", "tool_input": {"command": "gh pr create"}}' | \
  ~/.claude/hooks/work-review-guard.sh 2>&1 || true)
if [ -z "$output" ]; then
    echo "✅ Hook allowed (no output)"
else
    echo "❌ Hook blocked: $output"
fi
echo ""

echo "=== Test 4: Failing review (should exit 1) ==="
~/dotfiles/genai/work --review --dry-run fail || true
echo ""

echo "=== Test 5: Hook should BLOCK after failing review ==="
output=$(echo '{"tool_name": "Bash", "tool_input": {"command": "gh pr create"}}' | \
  ~/.claude/hooks/work-review-guard.sh 2>&1 || true)
if [ -z "$output" ]; then
    echo "❌ Hook allowed (unexpected)"
else
    echo "✅ Hook blocked as expected"
fi
echo ""

echo "=== Test 6: Git note shows failure ==="
git notes --ref=reviews show HEAD
echo ""

echo "=== Cleanup ==="
cd ~ && rm -rf /tmp/test-review-repo
echo "Done!"
