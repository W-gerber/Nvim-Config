-- Editor-wide autocommands.

local function augroup(name) return vim.api.nvim_create_augroup("User" .. name, { clear = true }) end

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("YankHighlight"),
  callback = function() vim.hl.on_yank({ timeout = 200 }) end,
})

-- Save everything when Neovim loses focus.
vim.api.nvim_create_autocmd("FocusLost", {
  group = augroup("AutoSave"),
  callback = function() vim.cmd("silent! wall") end,
})

-- Keep splits proportional when the terminal is resized.
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("Resize"),
  callback = function()
    local tab = vim.api.nvim_get_current_tabpage()
    vim.cmd("tabdo wincmd =")
    pcall(vim.api.nvim_set_current_tabpage, tab)
  end,
})

-- Reload files changed outside Neovim. 'autoread' only re-reads on certain
-- commands, so `:checktime` is what actually triggers the check; it is set
-- explicitly here rather than relied on as a default.
vim.opt.autoread = true

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("Checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Jump back to the last cursor position when reopening a file.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("LastPosition"),
  callback = function(event)
    local exclude = { "gitcommit", "gitrebase" }
    if vim.tbl_contains(exclude, vim.bo[event.buf].filetype) or vim.b[event.buf].last_position_restored then
      return
    end

    vim.b[event.buf].last_position_restored = true
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(event.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Create missing parent directories when writing a new file.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("MkdirOnSave"),
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end

    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- `q` closes throwaway/help windows instead of trying to record a macro.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("QuickClose"),
  pattern = {
    "help",
    "qf",
    "man",
    "lspinfo",
    "checkhealth",
    "notify",
    "startuptime",
    "query",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true, desc = "Close window" })
  end,
})

-- Soft-wrap and spellcheck prose.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("Prose"),
  pattern = { "markdown", "gitcommit", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Per-language indentation overrides (the default is 2 spaces).
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("Indentation"),
  pattern = { "java", "python", "rust", "go" },
  callback = function(event)
    local buf = event.buf
    vim.bo[buf].expandtab = vim.bo[buf].filetype ~= "go" -- Go is gofmt-tabbed
    vim.bo[buf].tabstop = 4
    vim.bo[buf].shiftwidth = 4
    vim.bo[buf].softtabstop = 4
  end,
})
