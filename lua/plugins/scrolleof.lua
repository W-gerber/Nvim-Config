-- scrollEOF: keep 'scrolloff' honoured at the end of the buffer.
--
-- Vim's own 'scrolloff' stops applying once the last line is on screen, so the
-- cursor walks down into the bottom edge of the window while the text stays
-- put. This makes the buffer keep scrolling past the last line until the cursor
-- has its usual margin below it — the behaviour every other editor has.
--
-- Loaded on cursor movement rather than at startup: nothing it does matters
-- before the cursor has moved, and `CursorMoved` fires within the first
-- keystroke of real use.

return {
  "Aasim-A/scrollEOF.nvim",
  event = { "CursorMoved", "WinScrolled" },
  opts = {
    pattern = "*",

    -- The cursor in insert mode is usually mid-edit and the extra scrolling
    -- reads as the buffer jumping around under you.
    insert_mode = false,

    -- Floats get it too: previews, hover windows and the picker's preview pane
    -- are exactly where hitting the bottom edge is most obvious.
    floating = true,

    -- Terminals scroll themselves. Padding below the prompt in a shell,
    -- lazygit or the Claude Code pane just hides the line you are typing on.
    disabled_filetypes = {
      "terminal",
      "toggleterm",
      "lazygit",
      "claude",
      "neo-tree",
      "alpha",
      "TelescopePrompt",
      "trouble",
      "dap-repl",
      "dapui_watches",
      "dapui_stacks",
      "dapui_breakpoints",
      "dapui_scopes",
      "dapui_console",
    },

    -- `t` is terminal-insert, `nt` terminal-normal.
    disabled_modes = { "t", "nt" },
  },
}
