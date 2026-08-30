<h1 align="center">~/.dotfiles</h1>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-000?logo=apple&logoColor=white" />
  <img src="https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black" />
  <img src="https://img.shields.io/badge/Zsh-121011?logo=gnu-bash&logoColor=white" />
  <img src="https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white" />
</p>

<p align="center"><i>Personal dotfiles for macOS and Linux (distrobox).</i></p>

---

### 📦 What's included

| Config | Description |
|--------|-------------|
| `zsh/` | zshrc + custom Oh My Zsh theme |
| `git/` | gitconfig |
| `nvim/` | Neovim config (lazy.nvim) |
| `ghostty/` | terminal config |
| `tmux/` | tmux.conf |
| `iterm2/` | preferences plist (macOS) |
| `.conkyrc` | system monitor, Bazzite host (Linux) |
| `claude-code/` | Claude Code settings |
| `provision/` | platform bootstrap scripts (mac, distrobox, vps) |

---

### 🚀 Setup

```bash
git clone git@github.com:parsio-ai/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

<table>
<tr><td>🍎 <b>macOS</b></td><td><code>./provision/mac.sh</code></td></tr>
<tr><td>📦 <b>Distrobox</b></td><td><code>./provision/distrobox.sh</code></td></tr>
<tr><td>☁️ <b>VPS</b> (headless Ubuntu/Debian)</td><td><code>./provision/vps.sh</code></td></tr>
<tr><td>🔗 <b>Symlinks only</b></td><td><code>./setup.sh</code></td></tr>
</table>

---

### 🔒 Local overrides

Machine-specific settings go in `~/.zshrc.local` (not tracked).
