#!/bin/bash
# Creates a limited macOS user account for running Claude Code agents.
# This user can only access project directories — not your home, SSH keys, etc.
#
# Run once: sudo bash ~/dotfiles/bin/setup-agent-user.sh

set -euo pipefail

AGENT_USER="claude-agent"
AGENT_UID="502"
AGENT_HOME="/Users/${AGENT_USER}"
GROUP_NAME="_agents"
GROUP_GID="502"
PRIMARY_USER="jimhester"
PRIMARY_HOME="/Users/${PRIMARY_USER}"

# Must run as root
if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo: sudo bash $0"
    exit 1
fi

# --- Create group ---
if dscl . -read "/Groups/${GROUP_NAME}" 2>/dev/null; then
    echo "Group ${GROUP_NAME} already exists"
else
    echo "Creating group ${GROUP_NAME}..."
    dscl . -create "/Groups/${GROUP_NAME}"
    dscl . -create "/Groups/${GROUP_NAME}" PrimaryGroupID "${GROUP_GID}"
    dscl . -create "/Groups/${GROUP_NAME}" RealName "Claude Code Agents"
fi

# Add primary user to group
if dscl . -read "/Groups/${GROUP_NAME}" GroupMembership 2>/dev/null | grep -qw "${PRIMARY_USER}"; then
    echo "${PRIMARY_USER} already in ${GROUP_NAME}"
else
    echo "Adding ${PRIMARY_USER} to ${GROUP_NAME}..."
    dscl . -append "/Groups/${GROUP_NAME}" GroupMembership "${PRIMARY_USER}"
fi

# --- Create agent user ---
if dscl . -read "/Users/${AGENT_USER}" 2>/dev/null; then
    echo "User ${AGENT_USER} already exists"
else
    echo "Creating user ${AGENT_USER}..."

    # Find next available UID if 502 is taken
    while dscl . -list /Users UniqueID 2>/dev/null | awk '{print $2}' | grep -qw "${AGENT_UID}"; do
        AGENT_UID=$((AGENT_UID + 1))
    done

    dscl . -create "/Users/${AGENT_USER}"
    dscl . -create "/Users/${AGENT_USER}" UniqueID "${AGENT_UID}"
    dscl . -create "/Users/${AGENT_USER}" PrimaryGroupID "${GROUP_GID}"
    dscl . -create "/Users/${AGENT_USER}" UserShell /bin/zsh
    dscl . -create "/Users/${AGENT_USER}" NFSHomeDirectory "${AGENT_HOME}"
    dscl . -create "/Users/${AGENT_USER}" RealName "Claude Code Agent"

    # Hide from login window
    dscl . -create "/Users/${AGENT_USER}" IsHidden 1

    # Add to agents group
    dscl . -append "/Groups/${GROUP_NAME}" GroupMembership "${AGENT_USER}"
fi

# --- Create home directory ---
if [[ -d "${AGENT_HOME}" ]]; then
    echo "Home directory ${AGENT_HOME} already exists"
else
    echo "Creating home directory..."
    mkdir -p "${AGENT_HOME}"
    chown "${AGENT_USER}:${GROUP_NAME}" "${AGENT_HOME}"
    chmod 750 "${AGENT_HOME}"
fi

# --- Sudoers: let primary user run commands as agent without password ---
SUDOERS_FILE="/etc/sudoers.d/claude-agent"
if [[ -f "${SUDOERS_FILE}" ]]; then
    echo "Sudoers entry already exists"
else
    echo "Creating sudoers entry..."
    cat > "${SUDOERS_FILE}" <<EOF
# Allow ${PRIMARY_USER} to run commands as ${AGENT_USER} without password
${PRIMARY_USER} ALL=(${AGENT_USER}) NOPASSWD: SETENV: ALL

# Allow ${AGENT_USER} to run Chrome as ${PRIMARY_USER} (needs GUI session for Mach ports)
${AGENT_USER} ALL=(${PRIMARY_USER}) NOPASSWD: SETENV: ${PRIMARY_HOME}/dotfiles/bin/chromium-for-agent.sh

# Allow fd passthrough for Playwright debugging pipe (fds 3-4)
Defaults:${AGENT_USER} closefrom_override
EOF
    chmod 440 "${SUDOERS_FILE}"
    # Validate
    if ! visudo -cf "${SUDOERS_FILE}"; then
        echo "ERROR: Invalid sudoers file, removing"
        rm "${SUDOERS_FILE}"
        exit 1
    fi
fi

# --- Set directory ACLs ---
echo ""
echo "Setting directory ACLs..."

# Helper: add ACL only if not already present (prevents duplication on re-runs)
add_acl() {
    local path="$1" acl="$2" label="$3"
    if ls -le "$path" 2>/dev/null | grep -q "${AGENT_USER}"; then
        echo "  ${path} — ACL already set, skipping"
    else
        echo "  ${path} (${label})"
        chmod +a "${acl}" "$path"
    fi
}

# Helper: add ACL to a directory AND all existing contents recursively.
# file_inherit only covers newly-created files; this fixes existing 600-perm files.
# Always re-applies (chmod -R +a is idempotent on macOS — duplicates are harmless).
add_acl_recursive() {
    local path="$1" acl="$2" label="$3"
    echo "  ${path} (${label}, recursive)"
    chmod -R +a "${acl}" "$path" 2>/dev/null || true
}

RW_ACL="${AGENT_USER} allow read,write,execute,delete,add_file,add_subdirectory,list,search,file_inherit,directory_inherit"
RO_ACL="${AGENT_USER} allow read,execute,list,search,file_inherit,directory_inherit"

# Home directory — agent needs traverse-only (execute/search, NOT read/list)
# Required so the agent can reach ACL'd subdirectories like ~/p/
add_acl "${PRIMARY_HOME}" "${AGENT_USER} allow execute,search" "traverse-only"

# Projects — agent needs full r/w (inheritable for new repos)
PROJECTS_DIR="${PRIMARY_HOME}/p"
if [[ -d "${PROJECTS_DIR}" ]]; then
    add_acl_recursive "${PROJECTS_DIR}" "${RW_ACL}" "read/write"
else
    echo "  WARNING: ${PROJECTS_DIR} not found, skipping"
fi

# Worktrees — agent needs full r/w
WORKTREES_DIR="${PRIMARY_HOME}/.worktrees"
if [[ ! -d "${WORKTREES_DIR}" ]]; then
    echo "  Creating ${WORKTREES_DIR}..."
    mkdir -p "${WORKTREES_DIR}"
    chown "${PRIMARY_USER}:staff" "${WORKTREES_DIR}"
fi
add_acl_recursive "${WORKTREES_DIR}" "${RW_ACL}" "read/write"

# Metatron certs — agent needs read-only for git auth
METATRON_DIR="${PRIMARY_HOME}/.metatron"
if [[ -d "${METATRON_DIR}" ]]; then
    add_acl_recursive "${METATRON_DIR}" "${RO_ACL}" "read-only"
else
    echo "  WARNING: ${METATRON_DIR} not found, skipping"
fi

# Credential helper — agent needs read+execute
GHCREDS="${PRIMARY_HOME}/.ghcreds.sh"
if [[ -f "${GHCREDS}" ]]; then
    add_acl "${GHCREDS}" "${AGENT_USER} allow read,execute" "read+execute"
fi

# API keys — agent needs read
ZSHENV_LOCAL="${PRIMARY_HOME}/.zshenv.local"
if [[ -f "${ZSHENV_LOCAL}" ]]; then
    add_acl "${ZSHENV_LOCAL}" "${AGENT_USER} allow read" "read-only"
fi

# ~/.local/bin — agent needs traverse+read to access gh, work, etc.
LOCAL_BIN="${PRIMARY_HOME}/.local"
if [[ -d "${LOCAL_BIN}" ]]; then
    add_acl "${LOCAL_BIN}" "${AGENT_USER} allow execute,search,list" "traverse"
    add_acl "${LOCAL_BIN}/bin" "${RO_ACL}" "read+execute, inheritable"
fi

# Claude global state (~/.claude.json) — agent needs read/write for shared trust state
CLAUDE_JSON="${PRIMARY_HOME}/.claude.json"
if [[ -f "${CLAUDE_JSON}" ]]; then
    add_acl "${CLAUDE_JSON}" "${AGENT_USER} allow read,write" "read/write"
fi

# Claude config dir — agent needs read/write for plugins cache, statsig, etc.
CLAUDE_DIR="${PRIMARY_HOME}/.claude"
if [[ -d "${CLAUDE_DIR}" ]]; then
    add_acl_recursive "${CLAUDE_DIR}" "${RW_ACL}" "read/write"
fi

# Dotfiles — agent needs read (for symlinked configs)
DOTFILES_DIR="${PRIMARY_HOME}/dotfiles"
if [[ -d "${DOTFILES_DIR}" ]]; then
    add_acl "${DOTFILES_DIR}" "${RO_ACL}" "read-only, inheritable"
fi

# --- Git shared repository mode ---
# Both users create git objects; group-writable mode prevents permission conflicts
echo ""
echo "Setting git core.sharedRepository = group for ${PRIMARY_USER}..."
sudo -u "${PRIMARY_USER}" git config --global core.sharedRepository group

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Run: sudo -u ${AGENT_USER} bash ${DOTFILES_DIR}/bin/setup-agent-home.sh"
echo "  2. Test: become-agent ${AGENT_USER} whoami"
echo ""
