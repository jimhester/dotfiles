#!/bin/bash
# Bootstraps the claude-agent home directory with Claude Code config.
# Run as: sudo -u claude-agent bash ~/dotfiles/bin/setup-agent-home.sh
#
# Can be re-run safely to update config.

set -euo pipefail

AGENT_USER="claude-agent"
AGENT_HOME="/Users/${AGENT_USER}"
PRIMARY_USER="jimhester"
PRIMARY_HOME="/Users/${PRIMARY_USER}"
DOTFILES_DIR="${PRIMARY_HOME}/dotfiles"

# Verify running as agent user
if [[ "$(whoami)" != "${AGENT_USER}" ]]; then
    echo "Run as agent user: sudo -u ${AGENT_USER} bash $0"
    exit 1
fi

echo "Setting up ${AGENT_HOME} for Claude Code..."

# --- Helper ---
make_link() {
    mkdir -p "${1%/*}"
    if [[ -h "$1" ]]; then
        rm "$1"
    elif [[ -f "$1" ]]; then
        mv "$1" "$1.bak"
    fi
    ln -s "$2" "$1"
}

# --- .claude/ directory ---
echo "Setting up .claude/..."
mkdir -p "${AGENT_HOME}/.claude/hooks"
mkdir -p "${AGENT_HOME}/.claude/skills"
mkdir -p "${AGENT_HOME}/.claude/scripts"

# CLAUDE.md
make_link "${AGENT_HOME}/.claude/CLAUDE.md" "${DOTFILES_DIR}/claude/CLAUDE.md"

# Skills
make_link "${AGENT_HOME}/.claude/skills/work" "${DOTFILES_DIR}/work/skills/work"
make_link "${AGENT_HOME}/.claude/skills/rollover" "${DOTFILES_DIR}/work/skills/rollover"
make_link "${AGENT_HOME}/.claude/skills/trim" "${DOTFILES_DIR}/work/skills/trim"

# Hooks
make_link "${AGENT_HOME}/.claude/hooks/work-stage-detector.sh" "${DOTFILES_DIR}/work/hooks/work-stage-detector.sh"
make_link "${AGENT_HOME}/.claude/hooks/work-review-guard.sh" "${DOTFILES_DIR}/work/hooks/work-review-guard.sh"

# Status line script
make_link "${AGENT_HOME}/.claude/scripts/work-statusline.sh" "${DOTFILES_DIR}/work/scripts/work-statusline.sh"

# Plugins — share the primary user's installed plugins (read-only is fine)
make_link "${AGENT_HOME}/.claude/plugins" "${PRIMARY_HOME}/.claude/plugins"

# Statsig — share feature flags/trust state
make_link "${AGENT_HOME}/.claude/statsig" "${PRIMARY_HOME}/.claude/statsig"

# MCP config
make_link "${AGENT_HOME}/.claude/mcp.json" "${PRIMARY_HOME}/.claude/mcp.json"

# Share trust state and project onboarding (stored in ~/.claude.json)
make_link "${AGENT_HOME}/.claude.json" "${PRIMARY_HOME}/.claude.json"

# settings.json — adapted from primary user's config
# Hook paths use ~ which resolves to AGENT_HOME, status line uses absolute path
cat > "${AGENT_HOME}/.claude/settings.json" <<'SETTINGS'
{
  "attribution": {
    "commit": "Co-Authored-By: Claude <noreply@anthropic.com>",
    "pr": ""
  },
  "enabledPlugins": {
    "bdp-skills@bdp-skills": true,
    "code-review@claude-plugins-official": true,
    "github-enterprise-plugin@ngp-skills": true,
    "jenkins-plugin@ngp-skills": true,
    "jira-plugin@ngp-skills": true,
    "mcp-registry-plugin@ngp-skills": true,
    "mesh-plugin@ngp-skills": true,
    "metatron-plugin@ngp-skills": true,
    "nflx-posit-connect-mcp-server@nflx-posit-connect-mcp-server": true,
    "playwright@claude-plugins-official": true,
    "pyright-lsp@claude-plugins-official": true,
    "python-plugin@ngp-skills": true,
    "radar-plugin@ngp-skills": true,
    "skill-creator-plugin@ngp-skills": true,
    "slack-interactions-plugin@ngp-skills": true,
    "spinnaker-plugin@ngp-skills": true,
    "superpowers@claude-plugins-official": true,
    "wall-e-plugin@ngp-skills": true
  },
  "env": {
    "ANTHROPIC_BASE_URL": "http://claudecode.local.dev.netflix.net:9123/",
    "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY": "1",
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "CLAUDE_CODE_SUBAGENT_MODEL": "opus",
    "DISABLE_AUTOUPDATER": "1",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "http://claudemetricscollector.cluster.us-east-1.prod.cloud.netflix.net:4318",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
    "OTEL_LOGS_EXPORT_INTERVAL": "5000",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_METRIC_EXPORT_INTERVAL": "10000",
    "OTEL_RESOURCE_ATTRIBUTES": "user.netflix_email=jimhester@netflix.com,runtime_environment=local,wrapper.version=2604021846"
  },
  "extraKnownMarketplaces": {
    "ngp-skills": {
      "source": {
        "source": "git",
        "url": "https://git.netflix.net/corp/ngp-skills.git"
      }
    }
  },
  "fastMode": false,
  "fastModePerSessionOptIn": true,
  "hooks": {
    "PostToolUse": [
      {
        "hooks": [
          {
            "command": "~/.claude/hooks/work-stage-detector.sh",
            "timeout": 5000,
            "type": "command"
          }
        ],
        "matcher": "Bash"
      }
    ],
    "PreToolUse": [
      {
        "hooks": [
          {
            "command": "~/.claude/hooks/work-review-guard.sh",
            "timeout": 5000,
            "type": "command"
          }
        ],
        "matcher": "Bash"
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "command": "episodic-memory sync --background",
            "type": "command"
          }
        ]
      }
    ]
  },
  "model": "opus[1m]",
  "permissions": {
    "defaultMode": "auto"
  },
  "skipAutoPermissionPrompt": true,
  "skipDangerousModePermissionPrompt": true,
  "statusLine": {
    "command": "~/.claude/scripts/work-statusline.sh",
    "padding": 0,
    "type": "command"
  }
}
SETTINGS

# --- pip / uv config (Netflix PyPI index) ---
echo "Setting up pip/uv config..."
mkdir -p "${AGENT_HOME}/.config/pip"
cat > "${AGENT_HOME}/.config/pip/pip.conf" <<'PIPCONF'
[global]
index-url = https://pypi.netflix.net/simple
PIPCONF

mkdir -p "${AGENT_HOME}/.config/uv"
cat > "${AGENT_HOME}/.config/uv/uv.toml" <<'UVTOML'
index-url = "https://pypi.netflix.net/simple"
[pip]
index-url = "https://pypi.netflix.net/simple"
UVTOML

# --- .gitconfig ---
echo "Setting up .gitconfig..."
cat > "${AGENT_HOME}/.gitconfig" <<GITCONFIG
# Auto-generated for claude-agent — references primary user's auth config
[include]
    path = ${PRIMARY_HOME}/.gitconfig-proxy
[core]
    excludesfile = ${DOTFILES_DIR}/.gitignore
[user]
    name = Jim Hester
    email = jimhester@netflix.com
[core]
    sharedRepository = group
[safe]
    directory = *
[push]
    default = current
[credential]
    helper =
    helper = cache --timeout=86400
[credential "https://dev.azure.com"]
    useHttpPath = true
[credential "https://github.com"]
    username = jimhester
[init]
    defaultBranch = main
[alias]
    pushf = push --force-with-lease
GITCONFIG

# --- Metatron certs (mTLS auth for Netflix services, gh, git) ---
echo "Setting up metatron..."
make_link "${AGENT_HOME}/.metatron" "${PRIMARY_HOME}/.metatron"

# --- gh CLI auth ---
# gh token is passed via GH_TOKEN env var from become-agent (read from
# primary user's keychain at exec time), so no per-agent auth is needed.
# The config dir still needs to exist for gh to function.
echo "Setting up gh config dir..."
mkdir -p "${AGENT_HOME}/.config/gh"
cat > "${AGENT_HOME}/.config/gh/config.yml" <<'GHCONFIG'
git_protocol: https
prompt: disabled
GHCONFIG

# --- .local/bin/ tool symlinks ---
echo "Setting up tool symlinks..."
mkdir -p "${AGENT_HOME}/.local/bin"
make_link "${AGENT_HOME}/.local/bin/claude" "/opt/nflx/bin/claude"
# Point directly at the binary, not through ~/.local/bin/ (which is 700)
make_link "${AGENT_HOME}/.local/bin/gh" "$(readlink -f "${PRIMARY_HOME}/.local/bin/gh" 2>/dev/null || echo "${PRIMARY_HOME}/.local/bin/gh")"
make_link "${AGENT_HOME}/.local/bin/ghe" "${AGENT_HOME}/.local/bin/gh"
make_link "${AGENT_HOME}/.local/bin/work" "${DOTFILES_DIR}/work/work"
make_link "${AGENT_HOME}/.local/bin/become-agent" "${DOTFILES_DIR}/bin/become-agent"
make_link "${AGENT_HOME}/.local/bin/llm" "${DOTFILES_DIR}/zsh/bin/llm"

# --- .zshenv (minimal shell config) ---
echo "Setting up .zshenv..."
cat > "${AGENT_HOME}/.zshenv" <<'ZSHENV'
setopt no_global_rcs

# PATH: agent tools + homebrew + netflix + system
export PATH="$HOME/.local/bin:/opt/nflx/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Claude Code settings
export ENABLE_INCREMENTAL_TUI=true
export CLAUDE_CODE_EFFORT_LEVEL=max

# llm-panel: override stale defaults (nf-gemini-pro doesn't exist)
export LLM_PANEL_MODELS="nflx/gpt-5.2,nflx/claude-opus-4-6,nflx/gemini-3.1-pro-preview"

# Source API keys from primary user (ACL-granted read access)
ZSHENV
cat >> "${AGENT_HOME}/.zshenv" <<ZSHENV
[[ -f ${PRIMARY_HOME}/.zshenv.local ]] && source ${PRIMARY_HOME}/.zshenv.local
ZSHENV

echo ""
echo "=== Agent home setup complete ==="
echo ""
echo "Home: ${AGENT_HOME}"
echo "Test: sudo -u ${AGENT_USER} whoami"
echo ""
