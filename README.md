<div align="center">

# Nvim-Config

**A modern, modular Neovim configuration with dynamic themes and AI-powered coding**

[![Neovim](https://img.shields.io/badge/Neovim-0.9+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-5.1+-purple.svg?style=flat-square&logo=lua)](https://www.lua.org)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

[Features](#-features) • [Install](#-installation) • [Keybindings](#%EF%B8%8F-keybindings) • [Themes](#-themes)

</div>

---

## 📸 Screenshots

<div align="center">

### Dashboard
![Dashboard](https://via.placeholder.com/800x450/1a1b26/c0caf5?text=Dashboard+Screenshot)

### Editor View
![Editor](https://via.placeholder.com/800x450/1a1b26/c0caf5?text=Editor+Screenshot)

### Theme Picker
![Themes](https://via.placeholder.com/800x450/1a1b26/c0caf5?text=Theme+Picker+Screenshot)

</div>

---

## ✨ Features

- 🎨 **Dynamic Theme Switcher** - Live preview with persistent state
- 🤖 **GitHub Copilot** - AI-powered completion and chat
- ⚡ **Blazing Fast** - Lazy loading with 40-60ms startup time
- 💡 **Full LSP Support** - Auto-completion, diagnostics, and formatting
- 🔍 **Telescope** - Fuzzy file and text searching
- 🌳 **Neo-tree** - File explorer with Git integration
- 📊 **Custom Dashboard** - Quick actions and folder picker
- 🎯 **Treesitter** - Advanced syntax highlighting
- 🪟 **Windows Optimized** - Native folder dialogs and integrations

---

## 🚀 Installation

### Requirements

| Tool | Version | Required |
|------|---------|----------|
| Neovim | 0.9+ | ✅ |
| Git | Latest | ✅ |
| Node.js | 16+ | ✅ |
| Nerd Font | Any | ✅ |
| GitHub Copilot | Active | ⚪ Optional |

### Quick Setup

**Windows**
```powershell
git clone https://github.com/W-gerber/Nvim-Config.git $env:LOCALAPPDATA\nvim
nvim
```

**Linux/macOS**
```bash
git clone https://github.com/W-gerber/Nvim-Config.git ~/.config/nvim
nvim
```

Plugins install automatically on first launch. Restart Neovim when complete.

---

## ⌨️ Keybindings

> **Leader key:** `Space`

### Essential

| Key | Action |
|-----|--------|
| `<Space>ff` | Find files |
| `<Space>fg` | Find text |
| `<Space>e` | File explorer |
| `<Space>th` | Theme picker |
| `<C-h/j/k/l>` | Navigate windows |

### LSP

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `K` | Hover docs |
| `<Space>ca` | Code actions |
| `<Space>rn` | Rename |

### Copilot

| Key | Action |
|-----|--------|
| `<Tab>` | Accept suggestion |
| `<Space>cc` | Open chat |
| `<Space>ce` | Explain code |

[View all keybindings →](#)

---

## 🎨 Themes

<table>
<tr>
<td align="center" width="25%">
<img src="https://via.placeholder.com/200x120/1a1b26/c0caf5?text=Neon+Commit" />
<br/><b>Neon Commit</b>
</td>
<td align="center" width="25%">
<img src="https://via.placeholder.com/200x120/1a1b26/c0caf5?text=Tokyo+Night" />
<br/><b>Tokyo Night</b>
</td>
<td align="center" width="25%">
<img src="https://via.placeholder.com/200x120/282a36/f8f8f2?text=Dracula" />
<br/><b>Dracula</b>
</td>
<td align="center" width="25%">
<img src="https://via.placeholder.com/200x120/faf4ed/575279?text=Light" />
<br/><b>Default Light</b>
</td>
</tr>
</table>

**Switch themes:** `Space + th`

Includes 20+ themes: Catppuccin, Gruvbox, Nord, Rose Pine, and more.

---

## 🔧 LSP & Tools

**Pre-configured:**  
`lua_ls` • `tsserver` • `pyright` • `gopls` • `rust_analyzer` • `clangd` • `jdtls`

**Install servers:**
```vim
:Mason
```

**Features:**
- ✅ Auto-completion
- ✅ Go to definition
- ✅ Code actions
- ✅ Diagnostics
- ✅ Auto-formatting

---

## 📦 Included Plugins

<details>
<summary>🔌 Core Plugins (click to expand)</summary>

- **Plugin Manager:** lazy.nvim
- **LSP:** nvim-lspconfig, Mason
- **Completion:** nvim-cmp, Copilot
- **Fuzzy Finder:** Telescope
- **File Explorer:** Neo-tree
- **Syntax:** Treesitter
- **Theme Engine:** Base46
- **UI:** Lualine, Noice, Notify
- **Git:** Lazygit, Gitsigns
- **Extras:** Flash, Trouble, Todo Comments

</details>

---

## 🛠️ Troubleshooting

### Plugins not loading
```vim
:Lazy sync
```

### LSP not working
```vim
:Mason
:LspInfo
```

### Icons missing
Install a [Nerd Font](https://www.nerdfonts.com/) and set it in your terminal.

### Health check
```vim
:checkhealth
```

---

## 📚 Documentation

- **Structure:** [`Lua/`](Lua/) folder contains all configs
- **Plugins:** Each plugin has its own file in [`Lua/plugins/`](Lua/plugins/)
- **Themes:** Custom themes in [`Lua/themes/`](Lua/themes/)
- **Settings:** Core config in [`Lua/nvconfig.lua`](Lua/nvconfig.lua)

---

## 🤝 Contributing

Contributions welcome! Follow [conventional commits](https://www.conventionalcommits.org/).

```bash
git checkout -b feature/amazing-feature
git commit -m "feat: add amazing feature"
git push origin feature/amazing-feature
```

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 💬 Support

- 🐛 [Issues](https://github.com/W-gerber/Nvim-Config/issues)
- 💡 [Discussions](https://github.com/W-gerber/Nvim-Config/discussions)
- 📖 [Neovim Docs](https://neovim.io/doc/)
- 💬 [r/neovim](https://reddit.com/r/neovim)

---

<div align="center">

**⭐ Star this repo if you find it helpful!**

Made with ❤️ for the Neovim community

</div>