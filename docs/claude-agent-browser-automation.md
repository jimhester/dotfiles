# claude-agent browser automation (incl. Meechum / SSO)

The `claude-agent` sandbox user has **no macOS GUI / WindowServer session**. That
is fine for headless scraping, but it makes interactive logins impossible: there
is no window to click through Meechum (Netflix SSO), and the default Playwright
path uses `chrome-headless-shell` with a throwaway profile, so even a successful
login wouldn't persist.

## Two modes

| | Default (headless) | Authenticated (CDP connect) |
|---|---|---|
| Browser | `chrome-headless-shell` | headed Google Chrome |
| Runs as | `jimhester` via `chromium-for-agent.sh` (reverse-sudo, fd pipe) | `jimhester` directly (owns the GUI session) |
| Profile | throwaway (Playwright temp) | persistent, mode 0700: `~/.cache/claude-agent-chrome` |
| Agent connects via | Playwright `launch()` | `PLAYWRIGHT_MCP_CDP_ENDPOINT` → CDP on `127.0.0.1:<random port>` |
| Credentials | none | your live logins |

The authenticated mode follows the same model sandvault uses: the browser runs
on the host as the GUI user, and the sandboxed agent connects to it over a
localhost CDP endpoint. `@playwright/mcp` reads `PLAYWRIGHT_MCP_CDP_ENDPOINT`
and, when it's set, **connects** to that running browser instead of launching
its own — so the agent drives the session you logged into by hand.

## Usage

```sh
become-agent --browser
```

This starts (or reuses) a headed Chrome via `bin/chrome-debug-session`, then
launches the agent with `PLAYWRIGHT_MCP_CDP_ENDPOINT` pointing at it. Log into
Meechum once in the window that opens; the dedicated profile keeps the session,
so later runs are already authenticated and need no interaction.

Quit it when done:

```sh
chrome-debug-session --stop
```

To start the browser by itself, run it as `jimhester` — in a normal terminal,
or with the `!` prefix from a Claude session **running as your normal user**.
Do *not* run `! chrome-debug-session` from inside a `claude-agent` session: there
`!` runs as `claude-agent`, which has no GUI and can't show a window.

`--browser` is the supported way to wire an agent to it; it reads the chosen
port and exports `PLAYWRIGHT_MCP_CDP_ENDPOINT` itself. (You can still point an
agent at a running session manually by exporting that var, but `become-agent`
scrubs any inherited value unless `--browser` is given.)

Tunables: `CHROME_DEBUG_PORT` (default `0` = Chrome picks a random free port),
`CHROME_DEBUG_PROFILE` (default `~/.cache/claude-agent-chrome`).

## Why no new sudoers / ACLs

The headed Chrome runs as `jimhester` directly (not reverse-sudo from the agent),
and the agent reaches it only over a localhost TCP port — which is not
user-scoped — so no `/etc/sudoers.d/claude-agent` change and no profile ACLs are
needed. Contrast the headless path, which needs `closefrom_override` + reverse
sudo to share the DevTools fd pipe.

## Security

Threat model: the `claude-agent` sandbox is **mostly for accidental protection**
— stopping the agent from wandering into the wrong files or making destructive
mistakes — not for containing a deliberately malicious/compromised agent. CDP
mode fits that model: it's an **intentional, opt-in trust elevation**. While
connected, the agent drives a browser holding your live Meechum session, so its
*mistakes* now happen against authenticated, state-changing sessions (it can
reach any internal app and act as you). That's the real thing to weigh — not an
attacker, but the blast radius of an accident.

Note this is **not** a hard boundary against a compromised agent: CDP is full
browser control, and a determined local process could port-scan and connect.
The mitigations below address accidents and casual exposure, which is what this
sandbox is for. For true isolation you'd run the browser as a separate
GUI-capable user (not done here — see the git history / review notes).

Mitigations baked in:

- **Opt-in only.** The default agent session has no browser credentials.
  `become-agent` scrubs any inherited `PLAYWRIGHT_MCP_CDP_ENDPOINT` unless
  `--browser` is given, and **fails closed** (exits) if Chrome won't start —
  so the agent never silently connects to a dangling or wrong endpoint.
- **Dedicated profile**, mode `0700`, separate from your daily browser, with a
  symlink/ownership check before launch — so cookies aren't world-readable and
  it only accumulates sessions you deliberately log into. (Also required: Chrome
  136+ refuses `--remote-debugging-port` on the default profile.)
- **Random loopback port** (`--remote-debugging-port=0` + explicit
  `--remote-debugging-address=127.0.0.1`), so there's no fixed `9222` to collide
  with or squat, and a tracked PID file means reuse only attaches to *our* live
  Chrome.
- **Lifecycle**: `chrome-debug-session --stop` quits it; do that when you're
  done with the authenticated task.
