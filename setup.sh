#!/bin/bash

# Cross-platform dotfiles setup script
# Works on macOS and Linux/WSL

set -e

DOTFILES_DIR="$HOME/dotfiles"

# Detect OS
if [[ "$OSTYPE" == darwin* ]]; then
    OS="macos"
else
    OS="linux"
fi

echo "Setting up dotfiles for $OS..."

# Install packages
echo "Installing packages..."
if [[ "$OS" == "linux" ]]; then
    sudo apt update && sudo apt install -y zsh neovim ripgrep fd-find
else
    brew install zsh neovim ripgrep fd
fi

# Install oh-my-zsh if not present
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
else
    echo "oh-my-zsh already installed"
fi

# Initialize git submodules (zsh plugins, etc.)
echo "Initializing git submodules..."
git -C "$DOTFILES_DIR" submodule update --init --recursive

# Generate terminfo if they do not already exist
mkdir -p ~/.terminfo/s/
if [[ ! -e ~/.terminfo/s/screen-256color ]]; then
    tic "$DOTFILES_DIR/terminfo/terminfo-20120811.src"
fi

function make_link(){
    # Make parent directories
    mkdir -p "${1%/*}"
    if [[ -h "$1" ]]; then
        rm "$1"
    elif [[ -f "$1" ]]; then
        mv "$1" "$1.bak"
    elif [[ -d "$1" ]]; then
        mv "$1" "$1.bak"
    fi
    ln -s "$2" "$1"
}

# Shell dotfiles
for file in \
    zsh/{zshenv,zshrc} \
    tmux/tmux.conf \
    inputrc/inputrc \
    R/{Renviron,Rprofile} \
    perl/perltidyrc; do
    make_link "$HOME/.${file##*/}" "$DOTFILES_DIR/$file"
done

# Make dircolors link
make_link ~/.dir_colors "$DOTFILES_DIR/dircolors/dircolors.ansi-light"

# Make colemak directory link
make_link ~/.colemak "$DOTFILES_DIR/colemak/"

# Clone work repo for Claude Code tooling
WORK_REPO="$DOTFILES_DIR/work"
if [[ ! -d "$WORK_REPO" ]]; then
    echo "Cloning work repo..."
    git clone https://github.com/jimhester/work.git "$WORK_REPO"
else
    echo "Work repo already exists at $WORK_REPO"
fi

# Work script for Claude Code
make_link ~/.local/bin/work "$WORK_REPO/work"

# Claude Code skills
make_link ~/.claude/skills/work "$WORK_REPO/skills/work"

# Claude Code hooks for auto-detecting work stages
"$WORK_REPO/hooks/install-hooks.sh"

# Git config
git config --global core.excludesfile "$DOTFILES_DIR/.gitignore"
git config --global user.name "Jim Hester"
git config --global user.email "james.f.hester@gmail.com"

# Neovim config (modern setup using lazy.nvim)
mkdir -p ~/.config
make_link ~/.config/nvim "$DOTFILES_DIR/nvim"

echo ""
echo "Dotfiles symlinks created!"

# Set zsh as default shell if not already
if [[ "$SHELL" != *"zsh"* ]]; then
    echo "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Start a new terminal or run 'zsh' to use your new shell."
echo "Neovim plugins will auto-install on first launch."
echo ""
