# Dotfiles

Personal dotfiles with colemak support, solarized color scheme, and Claude Code tooling.

## Setup

```bash
git clone https://github.com/jimhester/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

## Claude Code

The `genai/` directory contains tooling for Claude Code:

- **`work`** - Script to spawn isolated Claude Code sessions for GitHub issues using git worktrees
- **`skills/work`** - Skill that teaches Claude when/how to use the work script
- **`hooks/`** - Auto-detection hooks that update worker status based on workflow events (PR creation, CI, merges, conflicts)

See `genai/skills/work/SKILL.md` for usage details.
