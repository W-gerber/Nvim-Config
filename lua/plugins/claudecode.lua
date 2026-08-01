-- Claude Code CLI integration
-- Provides :ClaudeCode and related commands

local function apply_claude_highlights()
  local ui = require("core.ui")
  local p = ui.palette()
  local hl = vim.api.nvim_set_hl

  -- Snacks.nvim's terminal window links its winhighlight to these groups by
  -- default (see snacks/win.lua), so theming them here reskins the Claude
  -- terminal split without having to fight Snacks' own winhighlight string.
  hl(0, "SnacksNormal", { bg = "NONE", fg = p.fg })
  hl(0, "SnacksNormalNC", { bg = "NONE", fg = p.fg })
  hl(0, "SnacksWinBar", { bg = p.panel, fg = ui.contrast(p.panel), bold = true })
  hl(0, "SnacksWinBarNC", { bg = p.panel, fg = p.muted })
  hl(0, "SnacksTitle", { bg = "NONE", fg = p.accent, bold = true })
  hl(0, "SnacksFooter", { bg = "NONE", fg = p.muted, italic = true })
  hl(0, "SnacksWinSeparator", { bg = "NONE", fg = p.border })
  hl(0, "SnacksBackdrop", { bg = p.bg })
end

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  cmd = {
    "ClaudeCode",
    "ClaudeCodeFocus",
    "ClaudeCodeSelectModel",
    "ClaudeCodeAdd",
    "ClaudeCodeSend",
    "ClaudeCodeTreeAdd",
    "ClaudeCodeStatus",
    "ClaudeCodeStart",
    "ClaudeCodeStop",
    "ClaudeCodeOpen",
    "ClaudeCodeClose",
    "ClaudeCodeDiffAccept",
    "ClaudeCodeDiffDeny",
    "ClaudeCodeCloseAllDiffs",
  },
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file from tree",
      ft = { "neo-tree", "NvimTree", "oil", "minifiles" },
    },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
  config = function()
    apply_claude_highlights()

    local ui = require("core.ui")
    local claude_group = ui.create_augroup("ClaudeCodeThemeHighlights")
    ui.on_theme_change(claude_group, apply_claude_highlights)

    -- Neovim's terminal spawner cannot launch npm's claude.cmd shim by bare
    -- name on Windows, so point at the native claude.exe when it exists.
    local claude_exe = vim.fn.expand("~/.local/bin/claude.exe")
    local terminal_cmd = vim.fn.filereadable(claude_exe) == 1 and claude_exe or nil

    require("claudecode").setup({
      terminal_cmd = terminal_cmd,
      terminal = {
        split_side = "right",
        split_width_percentage = 0.30,
        snacks_win_opts = {
          wo = {
            winbar = " 󰚩 Claude Code",
            number = false,
            relativenumber = false,
            signcolumn = "no",
            statuscolumn = "",
            cursorline = false,
          },
        },
      },
    })
  end,
}
