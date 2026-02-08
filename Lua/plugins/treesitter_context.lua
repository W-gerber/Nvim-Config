return {
  -- Sticky context header (VS Code-like):
  -- Keeps the current function/class/if/loop context visible at the top while scrolling.
  "nvim-treesitter/nvim-treesitter-context",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    enable = true,
    max_lines = 3,
    min_window_height = 0,
    -- Follow the cursor for a "what block am I in" feeling.
    mode = "cursor",
    separator = nil,
  },
}
