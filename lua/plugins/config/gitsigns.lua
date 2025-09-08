-- plugins/config/gitsigns.lua
local ok, gitsigns = pcall(require, "gitsigns")
if not ok then return end

gitsigns.setup({
  signs = {
    add          = { text = '│' },
    change       = { text = '│' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signcolumn = true,
  numhl = false,
  linehl = false,
  word_diff = false,
  watch_gitdir = {
    follow_files = true
  },
  attach_to_untracked = true,
  current_line_blame = false,
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol',
    delay = 1000,
  },
  preview_config = {
    border = 'rounded',
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1
  },
})
