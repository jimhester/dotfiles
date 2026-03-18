# User Preferences

## Plan Execution

When presenting plan execution options (subagent-driven in current session vs parallel session), always default to **subagent-driven execution in the current session** without prompting. Do not ask which approach to use.

## Python Dependencies

Never use `pip install` directly. For Netflix Newt projects (`.newt.yml`): edit `requirements.in`, then run `newt deps lock` and `newt venv` (these delegate to pynt/uv internally). For non-Newt projects: use `uv add`, `uv sync`, and `uv run`.

## GitHub Enterprise

A Netflix-patched `gh` CLI is installed (`~/.local/bin/gh`) that auto-detects `git.netflix.net` remotes. Use `gh` directly for all GitHub operations — no special flags or wrappers needed. Both `gh` and `ghe` point to the same binary.

<!-- BEGIN work-directives -->
# Superpowers Skill Overrides

## writing-plans: Always use subagent-driven development

When using the writing-plans skill (or superpowers:writing-plans), after saving the plan do NOT ask which execution approach to use. Always proceed with subagent-driven development in the current session (use superpowers:subagent-driven-development). Never offer the "Parallel Session" option.

## finishing-a-development-branch: Always push and create PR

When using the finishing-a-development-branch skill (or superpowers:finishing-a-development-branch), after verifying tests pass do NOT present the 4 options. Always proceed directly with option 2: push the branch and create a Pull Request. Skip the menu entirely.
<!-- END work-directives -->
