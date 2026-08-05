# Dotfiles

Personal dotfiles with colemak support, solarized color scheme, and AI coding-agent tooling.

## Setup

```bash
git clone https://github.com/jimhester/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

## AI coding agents

`workon` starts Codex in a Herdr-managed git worktree:

```bash
workon 123                         # GitHub issue in the current repository
workon AIE-123                     # Jira issue
workon "add dark mode support"     # Free-form task
workon --dry-run 123               # Show the branch and prompt only
```

Herdr owns worktree creation, workspaces, agent state, session restoration, and
notifications. The launcher only resolves task metadata and starts Codex.

The matching Codex skill teaches agents to dispatch issue work through `workon`
and use Herdr for lifecycle management.

The `work/` directory retains the older Claude Code tooling for compatibility.
