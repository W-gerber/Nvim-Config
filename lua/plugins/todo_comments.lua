return {
  -- Highlight and search for TODO, FIXME, NOTE, and other comment keywords.
  -- Provides :TodoTelescope, :TodoTrouble, and :TodoQuickFix commands.
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "TodoTelescope", "TodoTrouble", "TodoQuickFix", "TodoLocList" },
  keys = {
    {
      "]t",
      function() require("todo-comments").jump_next() end,
      desc = "Next todo comment",
    },
    {
      "[t",
      function() require("todo-comments").jump_prev() end,
      desc = "Previous todo comment",
    },
    { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
    { "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
    -- Searching todos is a *find* action. It used to live under <leader>s,
    -- which is the session prefix — two unrelated things sharing a group.
    { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Todo comments" },
    { "<leader>fT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },
    { "<leader>xq", "<cmd>TodoQuickFix<cr>", desc = "Todo (Quickfix)" },
    { "<leader>xl", "<cmd>TodoLocList<cr>", desc = "Todo (Loclist)" },
  },
  opts = {
    signs = true, -- Show icons in the sign column
    sign_priority = 8,
    keywords = {
      FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
      TODO = { icon = " ", color = "info" },
      HACK = { icon = " ", color = "warning" },
      WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
      PERF = { icon = "󰅒 ", color = "hint", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
      NOTE = { icon = "󰍨 ", color = "hint", alt = { "INFO" } },
      TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
    },
    merge_keywords = true,
    highlight = {
      multiline = true,
      multiline_pattern = "^.",
      multiline_context = 10,
      before = "",
      keyword = "wide",
      after = "fg",
      pattern = [[.*<(KEYWORDS)\s*:]],
      comments_only = true,
      max_line_len = 400,
      exclude = {},
    },
    -- Keep colors theme-friendly by linking to existing highlight groups.
    colors = {
      error = { "DiagnosticError", "ErrorMsg" },
      warning = { "DiagnosticWarn", "WarningMsg" },
      info = { "DiagnosticInfo" },
      hint = { "DiagnosticHint" },
      default = { "Identifier" },
      test = { "Identifier" },
    },
    search = {
      command = "rg",
      args = {
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
      },
      pattern = [[\b(KEYWORDS):]],
    },
  },
}
