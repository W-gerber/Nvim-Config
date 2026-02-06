-- Fast window navigation with Ctrl+h/j/k/l
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = "Move to left window" })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = "Move to below window" })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = "Move to above window" })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = "Move to right window" })
-- Leader key
vim.g.mapleader = " "

-- =========================
-- Buffer / file shortcuts
-- =========================
local function safe_bufdelete(bufnr, force)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local windows = vim.fn.win_findbuf(bufnr)
  for _, win in ipairs(windows) do
    if vim.api.nvim_win_is_valid(win) then
      local alt = vim.fn.bufnr("#")
      if alt > 0 and vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buflisted then
        pcall(vim.api.nvim_win_set_buf, win, alt)
      else
        local scratch = vim.api.nvim_create_buf(true, false)
        pcall(vim.api.nvim_win_set_buf, win, scratch)
      end
    end
  end

  local ok = pcall(vim.api.nvim_buf_delete, bufnr, { force = force or false })
  if not ok then
    vim.notify("Could not close buffer (unsaved changes?)", vim.log.levels.WARN)
  end
end

local function close_current_buffer(force)
  safe_bufdelete(vim.api.nvim_get_current_buf(), force)
end

-- New empty file (buffer)
vim.keymap.set("n", "<leader>bn", ":enew<CR>", { desc = "New buffer", silent = true })

-- Close current file (buffer)
vim.keymap.set("n", "<leader>bc", function()
  close_current_buffer(false)
end, { desc = "Close buffer", silent = true })

vim.keymap.set("n", "<leader>bC", function()
  close_current_buffer(true)
end, { desc = "Force close buffer", silent = true })

-- Close other files (buffers)
vim.keymap.set("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= current and vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted then
      safe_bufdelete(b, false)
    end
  end
end, { desc = "Close other buffers", silent = true })

vim.keymap.set("n", "<leader>bO", function()
  local current = vim.api.nvim_get_current_buf()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= current and vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted then
      safe_bufdelete(b, true)
    end
  end
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

-- Some bufferline/tabline plugins still expect this legacy global to exist.
-- Keeping it defined avoids startup errors in newer Neovim versions.
vim.g.bufferline = vim.g.bufferline or {}

-- Basic options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.o.showmode = false
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Indentation (fix misaligned starts like `private`)
-- Use spaces by default so columns line up consistently.
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Filetype overrides
vim.api.nvim_create_autocmd("FileType", {
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
  local mingw64_bin = "C:\\msys64\\mingw64\\bin"
  if vim.fn.isdirectory(mingw64_bin) == 1 then
    local path = vim.env.PATH or ""
    if not path:lower():find(mingw64_bin:lower(), 1, true) then
      vim.env.PATH = mingw64_bin .. ";" .. path
    end
  end
end
-- =========================
-- Lazy.nvim bootstrap
-- =========================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =========================
-- Plugins
-- =========================
require("lazy").setup(require("plugins"), {
  -- No plugins in this config use luarocks; disabling avoids Lua 5.1 warnings on Windows.
  rocks = { enabled = false },
})

-- =========================
-- Theme + Lualine
-- =========================
pcall(function()
  require("theme_switcher").setup()
end)

pcall(require, "statusline")

-- =========================
-- Custom pill-style tabline
-- =========================
pcall(function()
  require("tabline").setup()
end)

-- Keymap: <leader>q closes the current window (split)
vim.keymap.set('n', '<leader>q', ':close<CR>', { desc = "Close current window" })




