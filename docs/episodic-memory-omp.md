# Episodic memory with omp

## Setup

`setup.sh` runs `bin/setup-episodic-memory`, which:

- installs Homebrew `node@24` (macOS);
- clones `jimhester/episodic-memory` (fork of `obra/episodic-memory` carrying
  the omp parser fixes below) to `~/p/episodic-memory` (override with
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

## Fixed: omp sessions archived but never indexed

Upstream episodic-memory v1.6.0 (through `7e06519`) copied omp sessions to
`~/.config/superpowers/conversation-archive/` but indexed zero omp exchanges.
Two bugs in `src/parser.ts`, fixed in the fork (`c27aaa5`, `fe05b16`):

1. **Harness detection.** `detectConversationHarness` returned `'claude'` on
   the first unrecognized line; current omp transcripts open with a
   `{"type":"title",...}` line. Detection now skips `title` lines.
2. **Active-path walk.** `parseOmpConversation` only stored `type:"message"`
   entries, but omp's `parentId` chain runs through every entry type
   (`custom`, `model_change`, `thinking_level_change`, `toolResult` messages),
   so the leaf-to-root walk stopped before any user turn. Every entry with an
   `id` is now a tree node; only user/assistant messages contribute text.

Existing archives need a reindex after upgrading: re-syncing skips them
(their archive copies are current) and the high-water mark (`MAX(line_end)`)
hides sessions that were indexed with a bogus single exchange. Delete the
`harness = 'omp'` exchanges via `deleteExchange` in `dist/db.js`, then run
`episodic-memory index --cleanup --no-summaries`.
