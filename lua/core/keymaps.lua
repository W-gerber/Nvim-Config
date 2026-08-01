-- Global keymaps.
--
-- Plugin-specific mappings live with their plugin spec (so lazy.nvim can use
-- them as load triggers). Only editor-wide bindings belong here.

local utils = require("core.utils")

local function map(mode, lhs, rhs, desc, opts)
  opts = vim.tbl_extend("force", { desc = desc, silent = true }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Neovim 0.11 ships `grn`/`gra`/`grr`/`gri`/`grt` LSP defaults. This config maps
-- bare `gd`/`gr`/`gi` instead, and leaving both in place makes every `gr` wait
-- out 'timeoutlen' to see if a longer sequence follows.
for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt" }) do
  pcall(vim.keymap.del, "n", lhs)
end
pcall(vim.keymap.del, "x", "gra")

-- Windows -------------------------------------------------------------------
map("n", "<C-h>", "<C-w>h", "Window: left")
map("n", "<C-j>", "<C-w>j", "Window: down")
map("n", "<C-k>", "<C-w>k", "Window: up")
map("n", "<C-l>", "<C-w>l", "Window: right")

map("n", "<C-Up>", "<cmd>resize +2<cr>", "Window: taller")
map("n", "<C-Down>", "<cmd>resize -2<cr>", "Window: shorter")
map("n", "<C-Left>", "<cmd>vertical resize -4<cr>", "Window: narrower")
map("n", "<C-Right>", "<cmd>vertical resize +4<cr>", "Window: wider")

map("n", "<leader>q", "<cmd>close<cr>", "Close window")

-- Buffers -------------------------------------------------------------------
local function close_buffer(force) utils.safe_bufdelete(vim.api.nvim_get_current_buf(), force) end

map("n", "<leader>bn", "<cmd>enew<cr>", "New buffer")
map("n", "<leader>bc", function() close_buffer(false) end, "Close buffer")
map("n", "<leader>bC", function() close_buffer(true) end, "Force close buffer")
map("n", "<leader>bo", function() utils.close_other_buffers(false) end, "Close other buffers")
map("n", "<leader>bO", function() utils.close_other_buffers(true) end, "Force close other buffers")

map("n", "]b", function() require("tabline").next() end, "Next buffer")
map("n", "[b", function() require("tabline").prev() end, "Previous buffer")

-- Editing -------------------------------------------------------------------
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", "Save file")
map("n", "<Esc>", "<cmd>nohlsearch<cr>", "Clear search highlight")

map("n", "<A-j>", "<cmd>m .+1<cr>==", "Move line down")
map("n", "<A-k>", "<cmd>m .-2<cr>==", "Move line up")
map("v", "<A-j>", ":m '>+1<cr>gv=gv", "Move selection down")
map("v", "<A-k>", ":m '<-2<cr>gv=gv", "Move selection up")

-- Stay in visual mode after shifting, so indenting is repeatable.
map("v", "<", "<gv", "Indent left")
map("v", ">", ">gv", "Indent right")

-- Leave terminal-insert from any terminal (Claude, toggleterm, lazygit...).
-- Double-Esc so a single Esc still reaches the TUI app running inside.
map("t", "<Esc><Esc>", [[<C-\><C-n>]], "Exit terminal mode")

-- Workspace -----------------------------------------------------------------
map("n", "<leader>fo", function() require("core.workspace").open_dialog() end, "Open folder (workspace)")

-- UI toggles ----------------------------------------------------------------
map("n", "<leader>ub", function() require("core.transparency").toggle() end, "Toggle transparency")

map("n", "<leader>uw", function()
  vim.opt.wrap = not vim.o.wrap
  vim.notify("Wrap " .. (vim.o.wrap and "on" or "off"), vim.log.levels.INFO)
end, "Toggle line wrap")

map("n", "<leader>un", function()
  vim.opt.relativenumber = not vim.o.relativenumber
  vim.notify("Relative numbers " .. (vim.o.relativenumber and "on" or "off"), vim.log.levels.INFO)
end, "Toggle relative numbers")

map("n", "<leader>ud", function()
  local enabled = not vim.diagnostic.is_enabled()
  vim.diagnostic.enable(enabled)
  vim.notify("Diagnostics " .. (enabled and "on" or "off"), vim.log.levels.INFO)
end, "Toggle diagnostics")

-- Show the diagnostic under the cursor automatically after 'updatetime'. Off by
-- default — see the note in core/diagnostics.lua.
map("n", "<leader>uf", function() require("core.diagnostics").toggle_hover_float() end, "Toggle diagnostic float")

map("n", "<leader>uV", function()
  local shown = not vim.diagnostic.config().virtual_lines
  -- Virtual lines put the full message under the offending line, wrapped. Worth
  -- turning on for a Rust or TypeScript error that doesn't fit end-of-line.
  vim.diagnostic.config({ virtual_lines = shown and { current_line = true } or false })
  vim.notify("Diagnostic virtual lines " .. (shown and "on" or "off"), vim.log.levels.INFO)
end, "Toggle diagnostic virtual lines")

-- Cycles the dashboard between the Neovim-intro look and the classic logo
-- (see lua/plugins/alpha.lua); `:Dashboard intro|classic` picks one directly.
map("n", "<leader>ua", "<cmd>Dashboard<cr>", "Toggle dashboard style")

-- Music (core/music.lua — Windows media session via PowerShell) --------------
local function music() return require("core.music") end

map("n", "<leader>mm", function() music().toggle_panel() end, "Music: toggle panel")
map("n", "<leader>mp", function() music().playpause() end, "Music: play/pause")
map("n", "<leader>mn", function() music().next() end, "Music: next track")
map("n", "<leader>mb", function() music().prev() end, "Music: previous track")
map("n", "<leader>mS", function() music().stop() end, "Music: stop")
map("n", "<leader>mu", function() music().volume_up() end, "Music: volume up")
map("n", "<leader>md", function() music().volume_down() end, "Music: volume down")
map("n", "<leader>mv", function() music().set_volume_prompt() end, "Music: set volume")
