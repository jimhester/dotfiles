#!/bin/bash
# install-hooks.sh - Install work hooks for Claude Code
#
# This script:
# 1. Creates the ~/.claude/hooks directory
# 2. Symlinks work-stage-detector.sh (PostToolUse) and work-review-guard.sh (PreToolUse)
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

# Install a single hook script
install_single_hook() {
    local hook_name="$1"
    local hook_source="${SCRIPT_DIR}/${hook_name}"
    local hook_dest="${HOOKS_DIR}/${hook_name}"

    if [[ ! -f "$hook_source" ]]; then
        error "Hook script not found: $hook_source"
        exit 1
    fi

    info "Installing ${hook_name}..."

    # Remove existing symlink or file
    if [[ -L "$hook_dest" ]] || [[ -f "$hook_dest" ]]; then
        rm "$hook_dest"
    fi

    # Create symlink
    ln -sf "$hook_source" "$hook_dest"
    chmod +x "$hook_dest"

    info "Hook installed: $hook_dest -> $hook_source"
}

# Install all hook scripts
install_hooks() {
    install_single_hook "work-stage-detector.sh"
    install_single_hook "work-review-guard.sh"
}

# Add or update a hook in settings.json
configure_hook() {
    local hook_type="$1"  # PreToolUse or PostToolUse
    local hook_name="$2"
    local hook_config="$3"

    # Read current settings
    local current_settings
    current_settings=$(cat "$SETTINGS_FILE")

    # Check if hooks.<type> already exists
    if echo "$current_settings" | jq -e ".hooks.${hook_type}" &>/dev/null; then
        # Check if our hook is already configured
        if echo "$current_settings" | jq -e ".hooks.${hook_type}[] | select(.hooks[].command | contains(\"${hook_name}\"))" &>/dev/null; then
            info "${hook_name} already configured in ${hook_type}"
            return 0
        fi

        # Add our hook to existing array
        info "Adding ${hook_name} to existing ${hook_type} configuration..."
        current_settings=$(echo "$current_settings" | jq --argjson hook "$hook_config" ".hooks.${hook_type} += [\$hook]")
    else
        # Create hooks.<type> array
        info "Creating ${hook_type} hook configuration for ${hook_name}..."
        current_settings=$(echo "$current_settings" | jq --argjson hook "$hook_config" ".hooks.${hook_type} = [\$hook]")
    fi

    echo "$current_settings" > "$SETTINGS_FILE"
}

# Update settings.json with hook configuration
update_settings() {
    info "Updating Claude settings..."

    # Create settings file if it doesn't exist
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo '{}' > "$SETTINGS_FILE"
    fi

    # PostToolUse: work-stage-detector.sh (detects PR creation, CI status, merges)
    local post_hook_config='{
        "matcher": "Bash",
        "hooks": [
            {
                "type": "command",
                "command": "~/.claude/hooks/work-stage-detector.sh",
                "timeout": 5000
            }
        ]
    }'
    configure_hook "PostToolUse" "work-stage-detector" "$post_hook_config"

    # PreToolUse: work-review-guard.sh (blocks PR create/merge without review)
    local pre_hook_config='{
        "matcher": "Bash",
        "hooks": [
            {
                "type": "command",
                "command": "~/.claude/hooks/work-review-guard.sh",
                "timeout": 5000
            }
        ]
    }'
    configure_hook "PreToolUse" "work-review-guard" "$pre_hook_config"

    info "Settings updated: $SETTINGS_FILE"
}

# Main
main() {
    echo "=========================================="
    echo "Work Hooks Installer for Claude Code"
    echo "=========================================="
    echo ""

    check_dependencies
    setup_directories
    install_hooks
    update_settings

    echo ""
    echo "=========================================="
    info "Installation complete!"
    echo ""
    echo "Installed hooks:"
    echo ""
    echo "  work-stage-detector.sh (PostToolUse):"
    echo "    - Detects PR creation (gh pr create)"
    echo "    - Tracks CI status changes (gh pr checks)"
    echo "    - Detects PR merges (gh pr merge)"
    echo "    - Detects merge conflicts (git rebase/merge)"
    echo ""
    echo "  work-review-guard.sh (PreToolUse):"
    echo "    - Blocks PR creation without passing 'work --review'"
    echo "    - Blocks PR merge without passing 'work --review --pre-merge'"
    echo ""
    echo "To uninstall, run:"
    echo "  rm ~/.claude/hooks/work-*.sh"
    echo "  # Then remove hook entries from ~/.claude/settings.json"
    echo "=========================================="
}

main "$@"
