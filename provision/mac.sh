#!/usr/bin/env bash
# ============================================================================
# mac.sh — Idempotent dev environment setup for macOS
#
# Usage:  ~/dotfiles/provision/mac.sh
# ============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
info() { echo -e "${BLUE}[i]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; }

# ──────────────────────────────────────────────────────────────────────────────
# 1. Xcode Command Line Tools
# ──────────────────────────────────────────────────────────────────────────────
setup_xcode_cli() {
    if xcode-select -p &>/dev/null; then
        log "Xcode CLI tools already installed"
    else
        info "Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "Press enter once the installation completes..."
        read -r
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 2. Homebrew
# ──────────────────────────────────────────────────────────────────────────────
setup_homebrew() {
    if command -v brew &>/dev/null; then
        log "Homebrew already installed"
    else
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    info "Updating Homebrew..."
    brew update
}

# ──────────────────────────────────────────────────────────────────────────────
# 3. Brew packages
# ──────────────────────────────────────────────────────────────────────────────
install_brew_packages() {
    info "Installing brew packages..."

    local packages=(
        # Core
        git
        curl
        wget

        # Shell tools
        bat
        fd
        fzf
        ripgrep
        eza
        zoxide
        tmux
        lazygit
        lazydocker
        rtk

        # Dev
        python3
        neovim
        nvm
        uv
        pnpm

        # Cloud
        google-cloud-sdk
    )

    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! brew list "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        brew install "${to_install[@]}"
        log "Installed: ${to_install[*]}"
    else
        log "All brew packages already installed"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 4. fzf key bindings & completion
# ──────────────────────────────────────────────────────────────────────────────
setup_fzf() {
    if [ -f "$HOME/.fzf.zsh" ]; then
        log "fzf shell integration already configured"
    else
        info "Setting up fzf key bindings..."
        "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish
        log "fzf shell integration configured"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 5. Oh My Zsh + plugins
# ──────────────────────────────────────────────────────────────────────────────
setup_omz() {
    if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        log "Oh My Zsh already installed"
    else
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log "Oh My Zsh installed"
    fi

    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # Plugins
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
    log "OMZ plugins ready"
}

# ──────────────────────────────────────────────────────────────────────────────
# 6. NVM + Node.js LTS
# ──────────────────────────────────────────────────────────────────────────────
setup_node() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    mkdir -p "$NVM_DIR"

    # Load nvm from Homebrew
    [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && source "$(brew --prefix)/opt/nvm/nvm.sh"

    if command -v nvm &>/dev/null; then
        if nvm ls --no-colors lts/* 2>/dev/null | grep -q "N/A"; then
            info "Installing Node.js LTS..."
            nvm install --lts
        else
            log "Node.js LTS already installed"
        fi
    else
        warn "nvm not available in this shell — run 'nvm install --lts' after restarting"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 7. Neovim config (handled by setup.sh symlink)
# ──────────────────────────────────────────────────────────────────────────────
setup_neovim() {
    log "Neovim config managed via dotfiles symlink (setup.sh)"
}

# ──────────────────────────────────────────────────────────────────────────────
# 7b. JetBrains Mono Nerd Font
# ──────────────────────────────────────────────────────────────────────────────
setup_nerd_font() {
    if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
        log "JetBrains Mono Nerd Font already installed"
    else
        info "Installing JetBrains Mono Nerd Font..."
        brew install --cask font-jetbrains-mono-nerd-font
        log "JetBrains Mono Nerd Font installed"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 7c. Neovide
# ──────────────────────────────────────────────────────────────────────────────
setup_neovide() {
    if brew list --cask neovide &>/dev/null; then
        log "Neovide already installed"
    else
        info "Installing Neovide..."
        brew install --cask neovide
        log "Neovide installed"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 8. Bruin CLI
# ──────────────────────────────────────────────────────────────────────────────
setup_bruin() {
    if command -v bruin &>/dev/null; then
        log "Bruin CLI already installed"
    else
        info "Installing Bruin CLI..."
        curl -LsSf https://getbruin.com/install/cli | sh
        log "Bruin CLI installed"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 9. Claude Code
# ──────────────────────────────────────────────────────────────────────────────
setup_claude() {
    if command -v claude &>/dev/null; then
        log "Claude Code already installed"
    else
        info "Installing Claude Code..."
        curl -fsSL https://claude.ai/install.sh | bash
        log "Claude Code installed"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 10. iTerm2
# ──────────────────────────────────────────────────────────────────────────────
setup_iterm2() {
    if [ -d "/Applications/iTerm.app" ]; then
        log "iTerm2 already installed"
    else
        info "Installing iTerm2..."
        brew install --cask iterm2
        log "iTerm2 installed"
    fi

    # Point iTerm2 at dotfiles for preferences (idempotent)
    defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DOTFILES_DIR/iterm2"
    defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
    log "iTerm2 configured to load preferences from dotfiles"
}

# ──────────────────────────────────────────────────────────────────────────────
# 11. Common symlinks (zshrc, gitconfig, OMZ theme, claude-code settings)
# ──────────────────────────────────────────────────────────────────────────────
setup_symlinks() {
    bash "$DOTFILES_DIR/setup.sh"
}

# ──────────────────────────────────────────────────────────────────────────────
# 12. Default shell
# ──────────────────────────────────────────────────────────────────────────────
setup_default_shell() {
    local zsh_path
    zsh_path="$(which zsh)"

    if [ "$SHELL" = "$zsh_path" ]; then
        log "zsh is already the default shell"
        return
    fi

    # Ensure the zsh path is in /etc/shells (required by macOS chsh)
    if ! grep -qxF "$zsh_path" /etc/shells; then
        info "Adding $zsh_path to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    info "Setting zsh as default shell..."
    chsh -s "$zsh_path"
    log "Default shell set to zsh"
}

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────
main() {
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║       Dotfiles Setup — macOS + Homebrew       ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    # Check we're on macOS
    if [ "$(uname)" != "Darwin" ]; then
        err "This script should be run on macOS."
        exit 1
    fi

    setup_xcode_cli
    setup_homebrew
    install_brew_packages
    setup_fzf
    setup_omz
    setup_node
    setup_neovim
    setup_nerd_font
    setup_neovide
    setup_bruin
    setup_claude
    setup_iterm2
    setup_symlinks
    setup_default_shell

    echo ""
    log "All done! Restart your terminal to pick up all changes."
    echo ""
    info "Run 'claude' to authenticate Claude Code."
    info "Run 'gcloud init' to configure Google Cloud CLI."
    echo ""
}

main "$@"
