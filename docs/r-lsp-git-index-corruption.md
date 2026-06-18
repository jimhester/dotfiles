# R language server corrupting git index files — debugging writeup

**Status:** Root cause confirmed and reproduced. Culprit directories now identified (see UPDATE). No fixes applied yet.
**Date:** 2026-06-18
**Investigated by:** Claude Code (running as `claude-agent`; some steps blocked by that user boundary — see "Next investigation as jimhester"). UPDATE section added by a follow-up session running as `jimhester`.
**Example repo where it surfaced:** `~/p/rstudioconnectserver`

---

## UPDATE (2026-06-18, run as jimhester) — culprit directories identified

The follow-up session ran the blocked steps. Key results that **refine** the diagnosis below:

- **Four repos are corrupt, not one.** `git fsck` across `~/p/*` flags:
  `aie-posit-connect-control-plane`, `ap-api`, `datadoodles-semantic_connect`, `rstudioconnectserver`.
  **All four have intact HEAD trees** (`git ls-tree -r HEAD` succeeds) — damage is index-only everywhere, so repair is safe.

- **The corruption is mostly in *linked-worktree* indices, not main indices.** `git fsck` checks
  every worktree's index. Three of the four flag `.git/worktrees/<name>/index` (this is a heavy
  git-worktree workflow — the `work` skill creates a worktree per issue). Only
  `rstudioconnectserver` has its **main** `.git/index` clobbered.

- **There are two distinct culprit directories, same mechanism:**
  - **Tree A — the r-languageserver launcher** → overwrote `rstudioconnectserver/.git/index`
    (the 11-entry foreign tree below). Launcher is no longer on disk; older event (index mtime 2026-06-08).
  - **Tree B — `~/p/superpowers`** → wrote its tree into the worktree indices of the three Netflix
    repos. **Confirmed by blob identity** — the "missing" blobs resolve to superpowers files in
    `git -C ~/p/superpowers ls-tree -r HEAD`:
    `hooks/session-start.sh`, `skills/requesting-code-review/code-reviewer.md`,
    `skills/systematic-debugging/root-cause-tracing.md`,
    `tests/skill-triggering/prompts/{systematic-debugging,writing-plans}.txt`,
    `tests/subagent-driven-dev/svelte-todo/scaffold.sh`.
    The same blob/cache-tree hashes recur across all three victims → a single shared culprit object
    store wrote into all of them. The cache-tree root tree objects are "missing" because a later
    `git gc` in superpowers pruned them; the blobs survive in HEAD.

- **So it is *not* specifically the R language server.** The launcher was one vector; `~/p/superpowers`
  was another. The common factor: a `git` subprocess running with cwd in **a repo being *edited*** while
  it inherited a leaked `GIT_INDEX_FILE` from a `git commit` happening in **a repo being *committed***.

- **Likely in-nvim vector: `gitsigns.nvim` (and/or `vim-fugitive`).** Both run `git` subprocesses
  scoped to the *buffer's* repo. nvim has no session/persistence plugin and `nvr` is only R's editor.
  The pattern "tree of repo-I'm-editing written into the index of repo-I'm-committing-in" matches
  gitsigns (editing superpowers / the launcher) × the `EDITOR=nvim` commit-editor env (committing in
  the victim) running in one nvim instance.

- **Consequence for the fix:** the narrow "scrub GIT_* only on the R-LSP `cmd`" option below would
  **not** have prevented the superpowers corruption. **Use the broad fix** — scrub `GIT_*` from
  nvim's whole environment in `nvim/init.lua` (before `require("lazy").setup`) so gitsigns, fugitive,
  the R LSP, `:terminal`, and any other subprocess are all covered.

- Confirmed footgun: `zsh/zshenv:6` PATH is
  `.:$HOME/bin:…:./node_modules/.bin:…` — `.` is first, `./node_modules/.bin` near the end.

### Repair DONE (2026-06-18)

All four repos repaired with `git read-tree HEAD` on each corrupt index (rebuilds index from HEAD;
working tree untouched). Indices fixed:

- `~/p/rstudioconnectserver` — main `.git/index`
- `~/.worktrees/aie-posit-connect-control-plane/feature-setup-sync-service-for-posit-connect-owners`
- `~/.worktrees/aie-posit-connect-control-plane/issue-66`
- `~/.worktrees/ap-api/feature-errors-in-the-metadata-diff-endpoint`
- `~/.worktrees/datadoodles-semantic_connect/async-metadata-refresh`

`git fsck` on all four parent repos is now clean of `missing blob` / `cache-tree` errors; only
harmless dangling objects remain (gc anytime). `git status` works in every repo again.

### Preventive fixes APPLIED (2026-06-18)

All three applied (not yet committed):

1. **Broad `GIT_*` env scrub in `nvim/init.lua`** (top of file, before lazy bootstrap) — unsets
   `GIT_INDEX_FILE`/`GIT_DIR`/`GIT_WORK_TREE`/`GIT_OBJECT_DIRECTORY`/`GIT_COMMON_DIR`/`GIT_PREFIX`/
   `GIT_NAMESPACE`. Closes the gitsigns/fugitive/R-LSP/`:terminal` channels. Verified: launching
   nvim with those vars set leaves them `nil` inside nvim.
2. **R-LSP `cmd` fixed** in `nvim/lua/plugins/init.lua` — now
   `{ "R", "--slave", "-e", "languageserver::run()" }` instead of the bare `r-languageserver`
   launcher. Bypasses the git-running launcher; resolves `R` via PATH (no cwd). NOTE: the R
   `languageserver` package is **not installed** — run `R -e 'install.packages("languageserver")'`
   for the LSP to attach.
3. **PATH footgun removed** in `zsh/zshenv` (both darwin and Linux branches) — dropped leading `.`
   and trailing `./node_modules/.bin`.

Reload: new nvim picks up the config on next launch; `zshenv` applies to new shells (or
`source ~/.zshenv`). Dotfiles are symlinked into place (`~/.config/nvim`, `~/.zshenv`).

---

## Symptom

`git status` in an affected repo fails:

```
fatal: unable to read c29dedc4a729f1ab564b7f85709931a3aaf5c73d
```

`git fsck` shows a corrupt index referencing objects that don't exist locally:

```
error: a9eda19c…: invalid sha1 pointer in cache-tree of .git/index
missing blob 84c048a7…
missing blob d0416825…
…
```

This has happened before; it was thought to be "fixed" (commit `06487e4`, see below) but has recurred.

---

## Root cause (confirmed)

A `git` process runs **inside the `r-languageserver` launcher's own directory** while it has
inherited a stale **`GIT_INDEX_FILE`** environment variable pointing at an *unrelated* repo's
index. That git command writes the **launcher's** file tree into the wrong repo's `.git/index`,
while the blobs are written to the **launcher's** object store. Result: the victim repo's index
references blobs it doesn't have → "missing blob" / "invalid sha1 pointer in cache-tree".

The leak channel:

1. `git` **exports `GIT_INDEX_FILE` to the processes it spawns** (hooks, and the editor). Verified
   empirically — a pre-commit hook saw `GIT_INDEX_FILE=.git/index`.
2. `EDITOR=nvim` (`zsh/zshrc:15`), so `git commit` (and friends) launch neovim with that env set.
3. While that env is live, the R language server (spawned by nvim) runs a `git` command in the
   launcher's directory. It inherits the stale `GIT_INDEX_FILE` and clobbers the victim's index.

Contributing footgun: `zsh/zshenv:6` puts `.` and `./node_modules/.bin` at the **front** of `PATH`,
so a bare `r-languageserver` (configured in `nvim/lua/plugins/init.lua`) resolves relative to the
current directory — which is how a git-clone'd copy of the launcher gets invoked.

---

## Evidence

### 1. The corrupt index contains a *foreign* tree — the launcher's own source

`git ls-files -s` reads the index itself (not the objects), so it works even when blobs are missing.
In `~/p/rstudioconnectserver` it listed **11 entries that are not part of this project**:

```
.github/workflows/release.yaml
.gitignore
LICENSE
README.md
bin/install
bin/install.ps1
bin/r-languageserver        ← the R language server launcher
bin/r-languageserver.cmd
scripts/release.sh
src/install.r
src/server.r
```

The project's *actual* HEAD tree is completely different (`.netflix`, `.newt.yml`, `docs/`, `ops/`,
`post-install.sh`, `root/`, `scripts/`, …). The index was overwritten with the launcher's repo tree.

Index size: `1124` bytes (11 entries). Every worktree index in the same repo is 4.5–5.6 KB — i.e.
the main index was replaced by a much smaller, foreign one.

### 2. fsck signature = "index written against a different object store"

The 10 `missing blob` hashes reported by fsck are exactly the blob hashes of those 11 foreign index
entries. The objects live in the launcher's repo, not here.

### 3. The damage is confined to `.git/index`

- HEAD = `e340542` on branch `bump-grace`; `git ls-tree -r HEAD` succeeds → **all real objects present**.
- Working tree is intact.
- Only `.git/index` is bad → repair is trivial (rebuild from HEAD).

### 4. git leaks `GIT_INDEX_FILE` to spawned processes (verified)

A throwaway repo with a pre-commit hook dumping the environment showed:

```
GIT_INDEX_FILE=.git/index
GIT_PREFIX=
GIT_EXEC_PATH=/opt/homebrew/opt/git/libexec/git-core
GIT_AUTHOR_*
```

(Note `GIT_DIR` was *not* exported here — consistent with the corruption: only the index path was
redirected, the object store was not, which is why blobs end up "missing".)

### 5. Reproduction — byte-for-byte match

```sh
set -e
ROOT=$(mktemp -d)

# victim = like rstudioconnectserver
V="$ROOT/victim"; git init -q "$V"; cd "$V"; git config user.email a@a; git config user.name a
printf 'real project file\n' > app.R; git add app.R; git commit -qm "victim real commit"

# tool = like the r-languageserver launcher's own git clone
TOOL="$ROOT/tool"; git init -q "$TOOL"; cd "$TOOL"; git config user.email b@b; git config user.name b
mkdir -p bin src
printf '#!/bin/sh\nexec R --slave -e "languageserver::run()"\n' > bin/r-languageserver
printf 'languageserver::run()\n' > src/server.r
printf 'install.packages("languageserver")\n' > src/install.r
git add -A; git commit -qm "tool repo"

# SIMULATE THE LEAK: GIT_INDEX_FILE points at the victim, git runs inside the tool dir
cd "$TOOL"
GIT_INDEX_FILE="$V/.git/index" git read-tree HEAD

cd "$V"; git ls-files -s; git fsck
```

Output reproduced the real failure exactly:

```
100644 …  bin/r-languageserver
100644 …  src/install.r
100644 …  src/server.r
error: …: invalid sha1 pointer in cache-tree of .git/index
missing blob …
missing blob …
missing blob …
```

---

## Why the previous fix didn't hold

Commit `06487e4` ("Add root_markers to all LSP configs to prevent git index corruption") added
`root_markers` to each server. But `root_markers` only sets the LSP's **rootUri / working
directory** — it does **nothing** about inherited `GIT_*` environment variables, which is the actual
leak channel. It treated a symptom. The `root_markers` are still in the config today and the
corruption recurred anyway.

---

## Proposed fix

Strip git environment variables from the R language server's spawned process so its launcher can
never act on a leaked index. In `nvim/lua/plugins/init.lua`:

```lua
vim.lsp.config("r_language_server", {
  cmd = { "env",
          "-u", "GIT_INDEX_FILE", "-u", "GIT_DIR", "-u", "GIT_WORK_TREE",
          "-u", "GIT_OBJECT_DIRECTORY", "-u", "GIT_COMMON_DIR",
          "-u", "GIT_PREFIX", "-u", "GIT_NAMESPACE",
          "r-languageserver" },
  filetypes = { "r", "rmd" },
  root_markers = { "DESCRIPTION", ".Rproj", ".git" },
})
```

Broader alternative (protects every LSP / terminal / gitsigns subprocess) — scrub the vars from
neovim's own environment early in init, since no nvim plugin relies on an *inherited* git env (they
rediscover the repo from the buffer path):

```lua
for _, v in ipairs({
  "GIT_INDEX_FILE", "GIT_DIR", "GIT_WORK_TREE",
  "GIT_OBJECT_DIRECTORY", "GIT_COMMON_DIR", "GIT_PREFIX", "GIT_NAMESPACE",
}) do
  vim.env[v] = nil
end
```

Separately worth considering: removing the leading `.` (and `./node_modules/.bin`) from `PATH` in
`zsh/zshenv:6`.

---

## Repairing an affected repo

Only the index is corrupt; history and working tree are fine.

```sh
cd ~/p/rstudioconnectserver
git read-tree HEAD          # rebuild index from HEAD  (or: git reset --mixed)
git status                  # should work again
git gc --prune=now          # drop the dangling/leaked objects
git fsck                    # verify clean
```

To scan for *other* repos hit by the same bug:

```sh
for d in ~/p/*/.git; do
  r="${d%/.git}"
  git -C "$r" fsck 2>&1 | grep -q 'missing blob\|cache-tree' && echo "CORRUPT: $r"
done
```

---

## Next investigation (run as jimhester)

As `claude-agent` I can't see the launcher in your `PATH`/filesystem. These pin down the exact
trigger:

1. **Locate the launcher(s):**
   ```sh
   which -a r-languageserver
   ```

2. **Does the launcher run git?** Inspect the script and anything it sources:
   ```sh
   ls=$(which r-languageserver); echo "$ls"; cat "$ls"
   grep -rn git "$(dirname "$ls")" 2>/dev/null
   ```

3. **Is the launcher dir itself a git repo, and does it match the leaked tree?**
   ```sh
   d=$(dirname "$(readlink -f "$(which r-languageserver)")")
   git -C "$d" rev-parse --show-toplevel
   git -C "$d" ls-tree -r HEAD --name-only   # compare to the 11 leaked paths above
   ```

4. **Catch it live — instrument the LSP.** Temporarily point the nvim `cmd` at a shim that logs the
   environment every time the server starts. When corruption next happens, the log shows whether
   `GIT_INDEX_FILE` was set and what `pwd` was:
   ```sh
   cat > ~/bin/r-languageserver-debug <<'EOF'
   #!/bin/sh
   { date; echo "pwd=$(pwd)"; env | grep '^GIT_' || echo '(no GIT_ env)'; echo '---'; } \
     >> /tmp/r-ls-env.log
   exec r-languageserver "$@"
   EOF
   chmod +x ~/bin/r-languageserver-debug
   # then set cmd = { "r-languageserver-debug" } in nvim/lua/plugins/init.lua and reproduce
   ```

5. **How do you trigger commits?** terminal `git commit`, fugitive `:Git`, lazygit, or a
   long-running nvim via neovim-remote (`nvr`, referenced in `R/Rprofile`)? This determines how
   `GIT_INDEX_FILE` reaches the R LSP. If you use `nvr` as the git editor, a persistent nvim could
   hold a stale `GIT_INDEX_FILE` across many edits — a prime suspect.
