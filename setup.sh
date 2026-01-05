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

# Git config
git config --global core.excludesfile "$DOTFILES_DIR/.gitignore"
git config --global user.name "Jim Hester"
git config --global user.email "james.f.hester@gmail.com"

# Neovim config (modern setup using lazy.nvim)
mkdir -p ~/.config
make_link ~/.config/nvim "$DOTFILES_DIR/nvim"

echo ""
echo "Dotfiles symlinks created!"
echo ""
echo "=== Manual steps required ==="
echo ""
echo "1. Install packages (run with sudo on Linux):"
if [[ "$OS" == "linux" ]]; then
    echo "   sudo apt update && sudo apt install -y neovim ripgrep fd-find"
else
    echo "   brew install neovim ripgrep fd"
fi
echo ""
echo "2. Install oh-my-zsh:"
echo '   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
echo ""
echo "3. Install zsh plugins:"
echo '   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting'
echo '   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions'
echo '   git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/history-substring-search'
echo ""
echo "4. Set zsh as default shell:"
echo "   chsh -s \$(which zsh)"
echo ""
echo "5. Start nvim to install plugins (lazy.nvim will auto-bootstrap)"
echo ""
