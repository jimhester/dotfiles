#!/usr/bin/env bash
# Wrapper for episodic-memory MCP server that auto-rebuilds native modules
# when the Node.js version changes or a native binding is missing/stale.

set -euo pipefail

PLUGIN_ROOT="${EPISODIC_MEMORY_DIR:-$HOME/p/episodic-memory}"
MARKER="$PLUGIN_ROOT/node_modules/.node_abi_version"
CURRENT_ABI="$(node -p process.versions.modules 2>/dev/null || echo unknown)"

needs_rebuild=false
if [[ ! -f "$MARKER" || "$(cat "$MARKER")" != "$CURRENT_ABI" ]]; then
  echo "Node ABI changed (was $(cat "$MARKER" 2>/dev/null || echo 'unset'), now $CURRENT_ABI); rebuilding native modules..." >&2
  needs_rebuild=true
elif ! (cd "$PLUGIN_ROOT" && node -e "const Database = require('better-sqlite3'); const db = new Database(':memory:'); db.close();" >/dev/null 2>&1); then
  echo "better-sqlite3 native binding is missing or stale; rebuilding native modules..." >&2
  needs_rebuild=true
fi

if [[ "$needs_rebuild" == true ]]; then
  (cd "$PLUGIN_ROOT" && npm rebuild better-sqlite3 --silent 2>&1) >&2
  echo "$CURRENT_ABI" > "$MARKER"
fi

exec node "$PLUGIN_ROOT/cli/mcp-server-wrapper.js" "$@"
