# Episodic memory with omp

## Setup

`setup.sh` runs `bin/setup-episodic-memory`, which:

- installs Homebrew `node@24` (macOS);
- clones `obra/episodic-memory` to `~/p/episodic-memory` (override with
  `EPISODIC_MEMORY_DIR`);
- links `bin/episodic-memory` to `~/.local/bin/episodic-memory`;
- links `~/.omp/agent/hooks/post` to `omp/hooks/post`;
- merges an `episodic-memory` stdio entry (`episodic-memory mcp`) into
  `~/.omp/agent/mcp.json`, leaving other servers alone.

`bin/episodic-memory` is the CLI and MCP entry point for omp and Codex
(`codex/config.toml`). It installs dependencies on first run and rebuilds
`better-sqlite3` when the Node ABI changes or the binding fails to load.
`better-sqlite3` 12.6.2 supports Node 20–25 and does not compile on Node 26, so
the wrapper prefers `node@24`; override with `EPISODIC_MEMORY_NODE`.

`omp/hooks/post/episodic-memory.js` runs `episodic-memory sync --background`
on `session_start` and `session_shutdown` for main sessions only. omp ignores
symlinked hook files (`entry.isFile()` in its hook discovery), so the whole
`hooks/post` directory is linked instead. `EPISODIC_MEMORY_DISABLE_AUTO_SYNC=1`
disables the hook-triggered sync.

## Known bug: omp sessions are archived but never indexed

Observed 2026-11-04 with episodic-memory v1.6.0 (`2741503`); still present on
upstream `main` at `7e06519`. All 652 omp session files were copied to
`~/.config/superpowers/conversation-archive/`, but the index had zero omp
exchanges, so search only returns Claude/Codex/Cursor/opencode results.
This may already be fixed on another machine; check before redoing it.

Two bugs in `src/parser.ts`:

1. **Harness detection.** `detectConversationHarness` returns `'claude'` on the
   first line it doesn't recognize. Current omp transcripts start with a
   `{"type":"title",...}` line (109/109 top-level sessions checked), so they're
   parsed as Claude transcripts. `src/show.ts`'s `isOmpTranscript` already
   skips `title`/`session_init`/`custom` lines; detection should do the same.
2. **Active-path walk.** `parseOmpConversation` only stores `type:"message"`
   entries in `nodesById`, then walks `parentId` from the last message to the
   root. In omp, `parentId` links run through every entry type (`custom`,
   `model_change`, `thinking_level_change`, …), so the walk stops at the first
   non-message parent, usually before any user turn. Even with the title line
   removed, a real session parsed to 0 exchanges. Fix: record `parentId` for
   every entry, walk the full chain, and keep only messages.

After fixing: rebuild `dist/` (the CLI and MCP server run from it), add a
regression test with a real-shaped omp transcript, and reindex the existing omp
archives. Re-syncing won't reindex them because their archive copies are
already current. Upstream `obra/episodic-memory` has the same bugs.
