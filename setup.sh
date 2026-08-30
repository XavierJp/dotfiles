#!/usr/bin/env bash
# ============================================================================
# setup.sh — Common symlinks for all environments (mac, distrobox, etc.)
#
# Usage:  ~/dotfiles/setup.sh
# Can be sourced or called directly from platform-specific scripts.
# ============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors (skip if already defined by caller)
GREEN="${GREEN:-\033[0;32m}"
BLUE="${BLUE:-\033[0;34m}"
NC="${NC:-\033[0m}"

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
info() { echo -e "${BLUE}[i]${NC} $*"; }

# ──────────────────────────────────────────────────────────────────────────────
# Symlinks
# ──────────────────────────────────────────────────────────────────────────────
setup_common_symlinks() {
    info "Setting up common symlinks..."

    # Zshrc
    ln -sf "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
    log "zshrc linked"

    # Gitconfig
    ln -sf "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
    log "gitconfig linked"

    # tmux
    ln -sf "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
    log "tmux config linked"

    # OMZ custom theme
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [ -d "$ZSH_CUSTOM" ]; then
        mkdir -p "$ZSH_CUSTOM/themes"
        ln -sf "$DOTFILES_DIR/zsh/arrow-custom.zsh-theme" "$ZSH_CUSTOM/themes/arrow-custom.zsh-theme"
        log "OMZ theme linked"
    fi

    # Claude Code settings
    mkdir -p "$HOME/.claude"
    if [ -f "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ]; then
        info "Backing up existing Claude Code settings..."
        mv "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.bak"
    fi
    ln -sf "$DOTFILES_DIR/claude-code/settings.json" "$HOME/.claude/settings.json"
    log "Claude Code settings linked"

    # Neovim config
    mkdir -p "$HOME/.config"
    if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
        info "Removing old nvim config..."
        rm -rf "$HOME/.config/nvim"
    fi
    ln -sfn "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    log "Neovim config linked"
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_common_symlinks
fi
