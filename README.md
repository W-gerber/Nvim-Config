README - modular Neovim config (copy/install)

This folder contains a modular Neovim configuration (lua/core, lua/plugins, lua/ui).
To install it into your real Neovim config (C:\Users\wgerb\AppData\Local\nvim) do these steps in cmd.exe:

1) Backup your existing config (run in cmd.exe):
   mkdir C:\Users\wgerb\AppData\Local\nvim_backup_%DATE:~-4%%DATE:~4,2%%DATE:~7,2%
   robocopy /MIR "C:\Users\wgerb\AppData\Local\nvim" "C:\Users\wgerb\AppData\Local\nvim_backup_%DATE:~-4%%DATE:~4,2%%DATE:~7,2%"

2) Copy new config into place (run in cmd.exe):
   robocopy /MIR "C:\Users\wgerb\Desktop\Everything\VimConfig\nvim" "C:\Users\wgerb\AppData\Local\nvim"

3) Start Neovim and run :Lazy install (or from shell):
   nvim --headless +"Lazy! sync" +qa

Notes:
- This is a minimal modular layout to get you started. After copying, open Neovim and watch Lazy install plugins. Then run :TSUpdate for treesitter if needed.

Quick usage:

- Leader is <Space>. which-key shows grouped mappings.
- Advanced Search: <leader>a (Telescope, Spectre)
- Files: <leader>f (file tree, recent files, buffers)
- Git: <leader>g (gitsigns commands)
- Workspace: <leader>w (sessions)
- LSP: <leader>l (diagnostics, code actions, format)
- Tests: <leader>t (optional)

Fallback theme: to use gruvbox if you don't like the neon look, run:

   :colorscheme gruvbox

Recommended LSPs & tools (these will be auto-managed by mason):
 - TypeScript/JS: `tsserver`, `eslint_d`, `prettierd`
 - Python: `pyright`, `flake8`, `black`/`ruff`
 - Go: `gopls`, `gofmt`
 - Rust: `rust_analyzer`, `rustfmt`
 - Lua: `lua_ls` (with `neodev` enabled), `stylua`

To customize which servers are installed, edit `lua/plugins/config/mason.lua` and add specific servers to `ensure_installed` or install them with `:Mason`.

Session & tests:
 - Save session: <leader>w s (requires `neovim-session-manager`)
 - Projects list: <leader>w p (telescope projects)
 - Run nearest test: <leader>t n (neotest)


