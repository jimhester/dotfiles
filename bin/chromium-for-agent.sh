#!/bin/bash
# Wrapper that runs Chromium as jimhester (who has a GUI session with Mach port access).
# Used by Playwright MCP in claude-agent's sandbox, since claude-agent doesn't
# have a macOS GUI domain and Chrome/WebKit need Mach IPC to function.
#
# Requires sudoers: claude-agent ALL=(jimhester) NOPASSWD: /Users/jimhester/dotfiles/bin/chromium-for-agent.sh
#
# Security: Chrome runs as jimhester but uses a temp profile (Playwright's default),
# so no user data is exposed. The agent controls it via the DevTools protocol pipe.

# Find the Playwright chromium headless shell
CHROME=""
for dir in /Users/claude-agent/Library/Caches/ms-playwright/chromium_headless_shell-*/; do
    candidate="${dir}chrome-headless-shell-mac-arm64/chrome-headless-shell"
    if [[ -x "$candidate" ]]; then
        CHROME="$candidate"
    fi
done

if [[ -z "$CHROME" ]]; then
    echo "ERROR: No Playwright chromium found" >&2
    exit 1
fi

exec "$CHROME" "$@"
