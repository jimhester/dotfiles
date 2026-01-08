#!/bin/bash
# install-hooks.sh - Install work stage detection hooks for Claude Code
#
# This script:
# 1. Creates the ~/.claude/hooks directory
# 2. Symlinks the work-stage-detector.sh hook
# 3. Updates ~/.claude/settings.json with hook configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Check dependencies
check_dependencies() {
    local missing=()

    if ! command -v jq &>/dev/null; then
        missing+=("jq")
    fi

    if ! command -v sqlite3 &>/dev/null; then
        missing+=("sqlite3")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
        echo "Please install them and try again."
        exit 1
    fi
}

# Create directories
setup_directories() {
    info "Creating Claude hooks directory..."
    mkdir -p "$HOOKS_DIR"
}

# Install hook script
install_hook() {
    local hook_source="${SCRIPT_DIR}/work-stage-detector.sh"
    local hook_dest="${HOOKS_DIR}/work-stage-detector.sh"

    if [[ ! -f "$hook_source" ]]; then
        error "Hook script not found: $hook_source"
        exit 1
    fi

    info "Installing work-stage-detector.sh..."

    # Remove existing symlink or file
    if [[ -L "$hook_dest" ]] || [[ -f "$hook_dest" ]]; then
        rm "$hook_dest"
    fi

    # Create symlink
    ln -sf "$hook_source" "$hook_dest"
    chmod +x "$hook_dest"

    info "Hook installed: $hook_dest -> $hook_source"
}

# Update settings.json with hook configuration
update_settings() {
    info "Updating Claude settings..."

    # Hook configuration to add
    local hook_config='{
        "matcher": "Bash",
        "hooks": [
            {
                "type": "command",
                "command": "~/.claude/hooks/work-stage-detector.sh",
                "timeout": 5000
            }
        ]
    }'

    # Create settings file if it doesn't exist
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo '{}' > "$SETTINGS_FILE"
    fi

    # Read current settings
    local current_settings
    current_settings=$(cat "$SETTINGS_FILE")

    # Check if hooks.PostToolUse already exists
    if echo "$current_settings" | jq -e '.hooks.PostToolUse' &>/dev/null; then
        # Check if our hook is already configured
        if echo "$current_settings" | jq -e '.hooks.PostToolUse[] | select(.hooks[].command | contains("work-stage-detector"))' &>/dev/null; then
            info "Hook already configured in settings.json"
            return 0
        fi

        # Add our hook to existing PostToolUse array
        info "Adding hook to existing PostToolUse configuration..."
        local new_settings
        new_settings=$(echo "$current_settings" | jq --argjson hook "$hook_config" '.hooks.PostToolUse += [$hook]')
        echo "$new_settings" > "$SETTINGS_FILE"
    else
        # Create hooks.PostToolUse array
        info "Creating PostToolUse hook configuration..."
        local new_settings
        new_settings=$(echo "$current_settings" | jq --argjson hook "$hook_config" '.hooks.PostToolUse = [$hook]')
        echo "$new_settings" > "$SETTINGS_FILE"
    fi

    info "Settings updated: $SETTINGS_FILE"
}

# Main
main() {
    echo "=========================================="
    echo "Work Stage Detection Hooks Installer"
    echo "=========================================="
    echo ""

    check_dependencies
    setup_directories
    install_hook
    update_settings

    echo ""
    echo "=========================================="
    info "Installation complete!"
    echo ""
    echo "The hook will automatically detect:"
    echo "  - PR creation (gh pr create)"
    echo "  - CI status changes (gh pr checks)"
    echo "  - PR merges (gh pr merge)"
    echo "  - Merge conflicts (git rebase/merge)"
    echo ""
    echo "To uninstall, run:"
    echo "  rm ~/.claude/hooks/work-stage-detector.sh"
    echo "  # Then remove the hook entry from ~/.claude/settings.json"
    echo "=========================================="
}

main "$@"
