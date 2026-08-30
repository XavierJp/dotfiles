#!/usr/bin/env bash
# ============================================================================
# vps.sh — Idempotent dev environment setup for a headless Ubuntu/Debian VPS
#
# Usage:  ~/dotfiles/provision/vps.sh
# Run directly on the VPS as a normal (non-root) user with sudo rights.
#
# Installs the same CLI toolchain as the distrobox, minus everything GUI:
# no Nerd Font, no Neovide, no Ghostty, no conky, no spotify_player.
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

ARCH="$(uname -m)"

# ──────────────────────────────────────────────────────────────────────────────
# 0. Preflight — make sure this is the right script for this machine
# ──────────────────────────────────────────────────────────────────────────────
preflight() {
    if [ "$(uname -s)" = "Darwin" ]; then
        err "This is macOS. Use provision/mac.sh instead."
        exit 1
    fi

    if [ -f /run/.containerenv ] || [ -f /.dockerenv ]; then
        err "This looks like a container. Use provision/distrobox.sh from the host instead."
        exit 1
    fi

    if ! command -v apt-get &>/dev/null; then
        err "No apt-get found. This script targets Debian/Ubuntu."
        exit 1
    fi

    if [ "$(id -u)" -eq 0 ]; then
        err "Run this as a normal user with sudo rights, not as root."
        exit 1
    fi

    # `sudo -v` needs a TTY even under NOPASSWD, so try the non-interactive
    # path first — that keeps the script usable from cron/CI/a non-tty shell.
    if sudo -n true 2>/dev/null; then
        :
    elif [ -t 0 ] && sudo -v; then
        :
    else
        err "This script needs sudo."
        err "No passwordless sudo, and no terminal available to authenticate."
        exit 1
    fi

    if [ "$ARCH" != "x86_64" ]; then
        warn "Architecture is $ARCH; the binary downloads below assume x86_64."
        warn "Those steps may fail — apt-installed tools will still work."
    fi

    log "Preflight OK ($(. /etc/os-release && echo "$PRETTY_NAME"), $ARCH)"
}

# ──────────────────────────────────────────────────────────────────────────────
# 1. apt base
# ──────────────────────────────────────────────────────────────────────────────
install_apt_base() {
    info "Updating apt and installing base packages..."
    sudo apt-get update
    sudo apt-get install -y \
        build-essential git curl wget unzip \
        zsh tmux \
        python3 python3-pip python3-venv \
        openssh-client ca-certificates gnupg \
        ripgrep bat fd-find \
        software-properties-common
    log "Base packages installed"
}

# ──────────────────────────────────────────────────────────────────────────────
# 2. CLI tools not packaged (or too old) in apt
# ──────────────────────────────────────────────────────────────────────────────
install_fzf() {
    if [ -d "$HOME/.fzf" ]; then log "fzf already installed"; return; fi
    info "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --all --no-bash --no-fish
    log "fzf installed"
}

install_eza() {
    if command -v eza &>/dev/null; then log "eza already installed"; return; fi
    info "Installing eza..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg
    sudo apt-get update
    sudo apt-get install -y eza
    log "eza installed"
}

install_zoxide() {
    if command -v zoxide &>/dev/null; then log "zoxide already installed"; return; fi
    info "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    log "zoxide installed"
}

install_lazygit() {
    if command -v lazygit &>/dev/null; then log "lazygit already installed"; return; fi
    info "Installing lazygit..."
    local version
    version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm -f lazygit lazygit.tar.gz
    log "lazygit installed"
}

install_gh() {
    if command -v gh &>/dev/null; then log "gh already installed"; return; fi
    info "Installing gh..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y gh
    log "gh installed"
}

install_neovim() {
    if command -v nvim &>/dev/null; then log "Neovim already installed"; return; fi
    info "Installing Neovim..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm -f nvim-linux-x86_64.tar.gz
    log "Neovim installed"
}

install_cli_tools() {
    install_fzf
    install_eza
    install_zoxide
    install_lazygit
    install_gh
    install_neovim
}

# ──────────────────────────────────────────────────────────────────────────────
# 3. Oh My Zsh + plugins
# ──────────────────────────────────────────────────────────────────────────────
setup_omz() {
    if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        info "Installing Oh My Zsh..."
        rm -rf "$HOME/.oh-my-zsh"
        # --keep-zshrc: setup.sh owns ~/.zshrc, don't let the installer clobber it
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            "" --unattended --keep-zshrc
    else
        log "Oh My Zsh already installed"
    fi

    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    log "OMZ plugins ready"
}

# ──────────────────────────────────────────────────────────────────────────────
# 4. Language toolchains
# ──────────────────────────────────────────────────────────────────────────────
setup_node() {
    # NVM_DIR must match what zsh/zshrc expects ($HOME/.config/nvm), not nvm's
    # own default of $HOME/.nvm — the installer honours the exported value.
    export NVM_DIR="${NVM_DIR:-$HOME/.config/nvm}"

    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        info "Installing nvm..."
        mkdir -p "$NVM_DIR"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    else
        log "nvm already installed"
    fi

    # nvm.sh trips over `set -u`, and nvm itself is a shell function, not a binary.
    set +u
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    if ! type nvm >/dev/null 2>&1; then
        set -u
        err "nvm failed to load from $NVM_DIR; Node not installed."
        return 1
    fi
    nvm install --lts
    nvm alias default "lts/*"
    set -u
    log "Node $(node --version) installed via nvm"

    # A distro-packaged node earlier in PATH would shadow nvm's.
    local system_node
    system_node="$(PATH=/usr/bin:/bin command -v node 2>/dev/null || true)"
    if [ -n "$system_node" ]; then
        warn "A system Node is also present at $system_node (apt)."
        warn "nvm's shims come first in the zshrc PATH, so nvm wins in an interactive"
        warn "shell. Remove it with 'sudo apt-get remove nodejs' if you want it gone."
    fi

    if ! command -v pnpm &>/dev/null; then
        info "Installing pnpm..."
        curl -fsSL https://get.pnpm.io/install.sh | sh -
        log "pnpm installed"
    else
        log "pnpm already installed"
    fi
}

setup_python() {
    if command -v uv &>/dev/null; then log "uv already installed"; return; fi
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    log "uv installed"
}

# ──────────────────────────────────────────────────────────────────────────────
# 5. Extras (gcloud, Claude Code)
# ──────────────────────────────────────────────────────────────────────────────
install_gcloud() {
    if command -v gcloud &>/dev/null; then log "gcloud already installed"; return; fi
    info "Installing Google Cloud CLI..."
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
        | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
    sudo apt-get update && sudo apt-get install -y google-cloud-cli
    log "gcloud installed"
}

install_claude() {
    if command -v claude &>/dev/null; then log "Claude Code already installed"; return; fi
    info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
    log "Claude Code installed"
}

# ──────────────────────────────────────────────────────────────────────────────
# 6. Symlinks (zshrc, gitconfig, tmux, OMZ theme, claude-code settings, nvim)
# ──────────────────────────────────────────────────────────────────────────────
setup_symlinks() {
    bash "$DOTFILES_DIR/setup.sh"
}

# ──────────────────────────────────────────────────────────────────────────────
# 7. Default shell
# ──────────────────────────────────────────────────────────────────────────────
setup_default_shell() {
    local zsh_path
    zsh_path="$(command -v zsh)"

    if [ "$(getent passwd "$(whoami)" | cut -d: -f7)" = "$zsh_path" ]; then
        log "zsh is already the default shell"
        return
    fi

    if ! grep -qxF "$zsh_path" /etc/shells; then
        info "Adding $zsh_path to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    info "Setting zsh as default shell..."
    sudo chsh -s "$zsh_path" "$(whoami)"
    log "Default shell set to zsh"
}

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────
main() {
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║        Dotfiles Setup — Headless VPS         ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    preflight
    install_apt_base
    install_cli_tools
    setup_omz
    setup_node
    setup_python
    install_gcloud
    install_claude
    setup_symlinks
    setup_default_shell

    echo ""
    log "All done! Start a new login shell to pick up zsh:"
    echo "    exec zsh"
    echo ""
    info "Machine-specific settings go in ~/.zshrc.local (not tracked)."
    info "To authenticate Claude Code, run 'claude'."
    echo ""
}

main "$@"
