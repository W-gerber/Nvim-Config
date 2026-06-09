-- Fast window navigation with Ctrl+h/j/k/l
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = "Move to left window" })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = "Move to below window" })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = "Move to above window" })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = "Move to right window" })
-- Leader key
vim.g.mapleader = " "

local utils = require("core.utils")
local safe_bufdelete = utils.safe_bufdelete

local uv = vim.uv or vim.loop

local function first_existing_dir(paths)
  for _, path in ipairs(paths) do
    if type(path) == "string" and path ~= "" and vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
end

local function close_buffer(bufnr, force)
  safe_bufdelete(bufnr or vim.api.nvim_get_current_buf(), force)
end

local function close_other_buffers(force)
  local current = vim.api.nvim_get_current_buf()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= current and vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted then
      safe_bufdelete(b, force)
    end
  end
end

-- New empty file (buffer)
vim.keymap.set("n", "<leader>bn", "<cmd>enew<CR>", { desc = "New buffer", silent = true })

-- Close current file (buffer)
vim.keymap.set("n", "<leader>bc", function()
  close_buffer(nil, false)
end, { desc = "Close buffer", silent = true })

vim.keymap.set("n", "<leader>bC", function()
  close_buffer(nil, true)
end, { desc = "Force close buffer", silent = true })

-- Close other files (buffers)
vim.keymap.set("n", "<leader>bo", function()
  close_other_buffers(false)
end, { desc = "Close other buffers", silent = true })

vim.keymap.set("n", "<leader>bO", function()
  close_other_buffers(true)
end, { desc = "Force close other buffers", silent = true })

-- Provider config (silence warnings for providers you don't use)
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Prefer an explicit Python 3 host when available
do
  local python3 = vim.fn.exepath("python3")
  if python3 == "" then
    python3 = vim.fn.exepath("python")
  end
  if python3 ~= "" then
    vim.g.python3_host_prog = python3
  end
end

-- Basic options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.o.showmode = false
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Essential options for a polished experience
vim.opt.undofile = true              -- persistent undo across sessions
vim.opt.clipboard = "unnamedplus"    -- system clipboard integration
vim.opt.ignorecase = true            -- case-insensitive search...
vim.opt.smartcase = true             -- ...unless uppercase is typed
vim.opt.signcolumn = "yes"           -- prevent layout shift from diagnostics
vim.opt.scrolloff = 8                -- keep 8 lines visible above/below cursor
vim.opt.sidescrolloff = 8            -- keep 8 cols visible left/right
vim.opt.updatetime = 250             -- faster CursorHold (default 4000ms)
vim.opt.timeoutlen = 300             -- faster keymap sequences
vim.opt.cursorline = true            -- highlight current line
vim.opt.wrap = false                 -- no line wrapping by default
vim.opt.mouse = "a"                  -- enable mouse in all modes

-- Indentation (fix misaligned starts like `private`)
-- Use spaces by default so columns line up consistently.
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Filetype overrides
local ft_group = vim.api.nvim_create_augroup("UserFiletypeOverrides", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = ft_group,
  pattern = { "java" },
  callback = function()
    vim.bo.expandtab = true
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.softtabstop = 4
  end,
})

-- Windows: ensure MSYS2 MinGW64 runtime DLLs are discoverable.
-- nvim-treesitter spawns gcc which then spawns internal binaries (cc1.exe) that rely on PATH.
do
  local sysname = uv and uv.os_uname and uv.os_uname().sysname or vim.loop.os_uname().sysname
  if sysname == "Windows_NT" then
    local mingw64_bin = first_existing_dir({
      vim.env.MINGW64_BIN,
      "C:/msys64/mingw64/bin",
      "C:/mingw64/bin",
    })

    if mingw64_bin then
      local path = vim.env.PATH or ""
      if not path:lower():find(mingw64_bin:lower(), 1, true) then
        vim.env.PATH = mingw64_bin .. ";" .. path
      end
    end
  end
end
-- =========================
-- Lazy.nvim bootstrap
-- =========================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (uv and uv.fs_stat and uv.fs_stat(lazypath)) then
  if vim.fn.executable("git") == 0 then
    vim.api.nvim_err_writeln("git is required to bootstrap lazy.nvim")
    return
  end

  local clone_output = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    clone_output = tostring(clone_output or ""):gsub("%s+$", "")
    vim.api.nvim_err_writeln("Failed to bootstrap lazy.nvim")
    if clone_output ~= "" then
      vim.api.nvim_err_writeln(clone_output)
    end
    return
  end
end
vim.opt.rtp:prepend(lazypath)

-- =========================
-- Plugins
-- =========================
require("lazy").setup(require("plugins"), {
  -- No plugins in this config use luarocks; disabling avoids Lua 5.1 warnings on Windows.
  rocks = { enabled = false },
  defaults = {
    lazy = true,
    version = false,
  },
  checker = {
    enabled = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "rplugin",
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
      },
    },
  },
})

-- =========================
-- Theme + Lualine
-- =========================
-- Glass / neon UI: keep core surfaces transparent but readable.
do
  local glass_group = vim.api.nvim_create_augroup("GlassUI", { clear = true })
  local function apply_glass_highlights()
    local cursorline_bg = vim.o.background == "light" and "#e8ecf4" or "#111111"
    local set = vim.api.nvim_set_hl
    set(0, "Normal",      { bg = "NONE" })
    set(0, "NormalFloat", { bg = "NONE" })
    set(0, "FloatBorder", { bg = "NONE" })
    set(0, "CursorLine",  { bg = cursorline_bg })
  end

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = glass_group,
    callback = apply_glass_highlights,
  })

  apply_glass_highlights()
end

-- Defer statusline and tabline setup so they don't block initial render.
-- They load right after the UI is drawn (VeryLazy fires ~10ms after startup).
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    pcall(function()
      require("theme_switcher").setup()
    end)
    pcall(function()
      require("tabline").setup()
    end)
  end,
})

-- Keymap: <leader>q closes the current window (split)
vim.keymap.set('n', '<leader>q', '<cmd>close<CR>', { desc = "Close current window", silent = true })

-- Save with Ctrl+S (VS Code habit)
vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file", silent = true })

-- Escape clears search highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Briefly highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

-- Move lines up/down (VS Code Alt+Up/Down)
vim.keymap.set("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down", silent = true })
vim.keymap.set("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up", silent = true })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Auto-save when Neovim loses focus
vim.api.nvim_create_autocmd("FocusLost", {
  group = vim.api.nvim_create_augroup("AutoSave", { clear = true }),
  callback = function()
    vim.cmd("silent! wall")
  end,
})

