---
name: workon
description: Dispatch GitHub issues, Jira issues, and free-form coding tasks to dedicated Codex agents in Herdr-managed git worktrees. Use when the user asks to work on, start, fix, or implement an issue; spin up a separate agent; launch coding work in another workspace; or dispatch multiple tasks in parallel. Do not dispatch when the user explicitly asks to work in the current session.
---

# Work On

Use `workon` from the repository that should receive the change. It resolves the
task, creates or reopens a Herdr worktree workspace, starts Codex, and submits the
task prompt. Herdr owns agent status, notifications, and session restoration.

## Dispatch a task

Run the matching form:

```bash
workon 123
workon https://github.com/owner/repo/issues/123
workon AIE-123
workon "add dark mode support"
```

For a bare GitHub issue number targeting a non-default remote, pass the GitHub
repository explicitly:

```bash
workon --repo owner/repo 123
```

Before using a full issue URL, ensure the current directory is the local checkout
that should receive the change. Change directories first when necessary.

Use `--no-focus` to dispatch in the background. When dispatching multiple tasks,
invoke `workon --no-focus` separately for each task so each gets its own worktree
and Codex agent.

Use `--dry-run` when the target, branch, or prompt needs verification before
creating anything:

```bash
workon --dry-run 123
```

After dispatching, report the task label and branch printed by `workon`. Do not
also implement the task in the current session.

## Inspect agents

Use Herdr directly instead of the retired `work --status`, messaging, or resume
commands:

```bash
herdr agent list
herdr workspace list
herdr worktree list
```

If a task worktree is already open with Codex, `workon` reuses and focuses that
workspace rather than starting a duplicate agent.
