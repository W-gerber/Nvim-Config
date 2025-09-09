# Tokyo Neon Skyline - Neovim Configuration

A sleek, modular Neovim configuration featuring a glassmorphic design with vibrant neon accents. Built for productivity with modern LSP support, intelligent completion, and a beautiful dashboard experience.

![Neovim Version](https://img.shields.io/badge/Neovim-0.8+-green.svg)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## ✨ Features

- **🎨 Tokyo Neon Theme**: Glassmorphic design with cyan, hotpink, lime, and purple neon accents
- **📁 Modular Structure**: Clean separation between core, plugins, and UI configurations
- **🚀 Modern Plugin Management**: Powered by [lazy.nvim](https://github.com/folke/lazy.nvim)
- **💡 Intelligent LSP**: Full Language Server Protocol support with auto-completion
- **🔍 Advanced Search**: Telescope fuzzy finder with live grep and project search
- **📊 Beautiful Dashboard**: Dynamic alpha-nvim dashboard with real-time system info
- **🔧 Session Management**: Persistent workspaces and project sessions
- **🌳 File Explorer**: Modern neo-tree file browser with git integration
- **⚡ Performance Optimized**: Lazy loading for fast startup times

## 🎯 Quick Start

### Prerequisites

- **Neovim 0.8+** (recommended 0.9+)
- **Git** for plugin management
- **Node.js** (for LSP servers)
- **Python 3** (optional, for Python development)
- **A Nerd Font** (for icons)

### Installation

#### Windows (PowerShell/CMD)

```cmd
# Backup existing config
mkdir "%LOCALAPPDATA%\nvim_backup_%DATE:~-4%%DATE:~4,2%%DATE:~7,2%"
robocopy /MIR "%LOCALAPPDATA%\nvim" "%LOCALAPPDATA%\nvim_backup_%DATE:~-4%%DATE:~4,2%%DATE:~7,2%"

# Clone this configuration
git clone https://github.com/yourusername/tokyo-neon-nvim.git "%LOCALAPPDATA%\nvim"

# Install plugins
nvim --headless +"Lazy! sync" +qa
```

#### Linux/macOS

```bash
# Backup existing config
mv ~/.config/nvim ~/.config/nvim.backup.$(date +%Y%m%d)

# Clone this configuration
git clone https://github.com/yourusername/tokyo-neon-nvim.git ~/.config/nvim

# Install plugins
nvim --headless +"Lazy! sync" +qa
```

## 🗂️ Project Structure

```
nvim/
├── init.lua                    # Entry point and bootstrap
├── lazy-lock.json             # Plugin version lock file
├── README.md                  # This file
└── lua/
    ├── core/                  # Core Neovim configuration
    │   ├── autocmds.lua       # Auto-commands for UI polish
    │   ├── keymaps.lua        # Key mappings
    │   └── settings.lua       # Neovim options and providers
    ├── plugins/               # Plugin configurations
    │   ├── init.lua           # Plugin specifications (lazy.nvim)
    │   └── config/            # Individual plugin configs
    │       ├── alpha.lua      # Dashboard configuration
    │       ├── cmp.lua        # Completion engine
    │       ├── lsp.lua        # Language Server Protocol
    │       ├── telescope.lua  # Fuzzy finder
    │       ├── treesitter.lua # Syntax highlighting
    │       └── ...            # Other plugin configs
    └── ui/                    # User interface customizations
        ├── colors.lua         # Neon color palette
        └── theme.lua          # Custom highlight groups
```

## ⌨️ Key Mappings

**Leader Key**: `<Space>`

### 📁 File Operations
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ff` | Find Files | Telescope file finder |
| `<leader>fr` | Recent Files | Recently opened files |
| `<leader>fb` | Buffers | Open buffer list |
| `<leader>ft` | File Tree | Toggle neo-tree explorer |
| `<leader>e` | Explorer | Quick toggle file explorer |

### 🔍 Advanced Search
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>as` | Live Grep | Search text in project |
| `<leader>ar` | Spectre | Advanced find and replace |

### 📝 Git Integration
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>gs` | Stage Hunk | Stage current hunk |
| `<leader>gb` | Blame Line | Show git blame |
| `<leader>gd` | Diff This | Show git diff |
| `<leader>gv` | Diffview | Open diffview |
| `<leader>gc` | Commit | Git commit |

### 🏢 Workspace Management
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>ws` | Save Session | Save current session |
| `<leader>wl` | Load Session | Load saved session |
| `<leader>wp` | Projects | Open project list |

### 🔧 LSP Actions
| Key | Action | Description |
|-----|--------|-------------|
| `gd` | Go to Definition | Jump to definition |
| `K` | Hover | Show documentation |
| `<leader>la` | Code Action | Show code actions |
| `<leader>lr` | Rename | Rename symbol |
| `<leader>lf` | Format | Format document |
| `<leader>ld` | Diagnostics | Show diagnostics |

### 🧪 Testing
| Key | Action | Description |
|-----|--------|-------------|
| `<leader>tn` | Run Nearest | Run nearest test |
| `<leader>tf` | Run File | Run all tests in file |
| `<leader>ta` | Run All | Run all tests |

## 🎨 Theme Customization

The configuration uses a custom neon color palette defined in [`lua/ui/colors.lua`](lua/ui/colors.lua):

```lua
M.neon = {
  cyan = "#00d7ff",     -- Electric cyan
  hotpink = "#ff2d95",  -- Hot pink
  lime = "#b7ff3a",     # Bright lime
  purple = "#9d7cff",   -- Vivid purple
}
```

### Alternative Themes more on the way

To switch to a different colorscheme:

```vim
:colorscheme gruvbox
:colorscheme catppuccin
:colorscheme kanagawa
```

## 🔧 LSP Configuration

### Supported Languages

The configuration includes LSP support for:

- **Lua**: `lua_ls` with neodev for Neovim API
- **TypeScript/JavaScript**: `tsserver`, `eslint_d`, `prettierd`
- **Python**: `pyright`, `flake8`, `black`
- **Go**: `gopls`, `gofmt`
- **Rust**: `rust_analyzer`, `rustfmt`
- **Java**: `jdtls` with enhanced project detection

### Installing Language Servers

Use Mason to install language servers:

```vim
:Mason
```

Or install specific servers:

```vim
:MasonInstall lua-language-server typescript-language-server pyright
```

### Custom LSP Setup

Add custom LSP configurations in [`lua/plugins/config/lsp.lua`](lua/plugins/config/lsp.lua):

```lua
lspconfig.your_server.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  -- your custom settings
})
```

## 📊 Dashboard Features

The alpha dashboard includes:

- **Dynamic Greeting**: Time-based welcome messages
- **Real-time Clock**: Updates every second
- **Git Information**: Current branch and commit count
- **Project Info**: Current workspace details
- **Quick Actions**: File/folder shortcuts, sessions, configuration

### Dashboard Shortcuts

| Key | Action |
|-----|--------|
| `e` | New file |
| `f` | Find files |
| `r` | Recent files |
| `p` | Project tree |
| `w` | Workspaces |
| `s` | Sessions |
| `c` | Configuration |
| `q` | Quit |

## ⚡ Performance Tips

### Startup Optimization

The configuration uses lazy loading extensively:

- Plugins load on demand (commands, filetypes, key mappings)
- Treesitter parsers install as needed
- LSP servers attach only to relevant file types

### Reducing Startup Time

```vim
# Check startup time
nvim --startuptime startup.log

# Profile plugins
:Lazy profile
```

### Windows-Specific Optimizations

- Disabled unused providers (Ruby, Perl) if not installed
- Safe compiler detection for Treesitter
- Optimized file system operations

## 🧪 Testing Integration

### Neotest Configuration

Supports multiple test adapters:

- **Python**: `pytest`, `unittest`
- **Go**: `go test`
- **JavaScript**: `jest`, `vitest`

### Running Tests

```vim
:Neotest run           # Run nearest test
:Neotest run file      # Run current file
:Neotest summary       # Show test summary
```

## 🔍 Troubleshooting

### Common Issues

1. **Icons not showing**: Install a Nerd Font and configure your terminal
2. **LSP not working**: Check `:LspStatus` and `:Mason` for server installation
3. **Slow startup**: Run `:Lazy profile` to identify bottlenecks
4. **Treesitter errors**: Use `:TSReinstallCore` to reinstall parsers

### Health Checks

```vim
:checkhealth          # General health check
:checkhealth nvim-treesitter
:checkhealth telescope
```

### Debug Commands

```vim
:Lazy              # Plugin manager
:Mason             # LSP/tool installer
:LspStatus         # Current LSP clients
:LspAll            # All active LSP clients
:TSUpdate          # Update Treesitter parsers
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Development Setup

```bash
# Clone for development
git clone https://github.com/yourusername/tokyo-neon-nvim.git
cd tokyo-neon-nvim

# Create symlink (Linux/macOS)
ln -sf $(pwd) ~/.config/nvim-dev

# Test configuration
nvim -u ~/.config/nvim-dev/init.lua
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim) - Base theme
- [folke/lazy.nvim](https://github.com/folke/lazy.nvim) - Plugin manager
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Fuzzy finder
- [goolord/alpha-nvim](https://github.com/goolord/alpha-nvim) - Dashboard
- [nvim-neo-tree/neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) - File explorer

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/tokyo-neon-nvim/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/tokyo-neon-nvim/discussions)
- **Wiki**: [Project Wiki](https://github.com/yourusername/tokyo-neon-nvim/wiki)

---

**Made with ❤️ and lots of ☕ for the Neovim community**
