return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local ok, wk = pcall(require, "which-key")
    if not ok then
      return
    end

    wk.setup({
      plugins = {
        spelling = { enabled = false },
      },
      win = {
        border = "rounded",
      },
      icons = {
        breadcrumb = " ",
        separator = " ",
        group = " ",
      },
    })

    wk.add({
      -- Buffers
      { "<leader>b",  group = "buffers" },
      { "<leader>bn", desc = "New buffer" },
      { "<leader>bc", desc = "Close buffer" },
      { "<leader>bC", desc = "Force close buffer" },
      { "<leader>bo", desc = "Close other buffers" },
      { "<leader>bO", desc = "Force close other buffers" },

      -- Diagnostics / LSP helpers
      { "<leader>d",  desc = "Line diagnostics" },

      -- File explorer
      { "<leader>e",  desc = "Explorer (Neo-tree)" },

      -- Telescope
      { "<leader>f",  group = "find" },
      { "<leader>ff", desc = "Find files (Everything)" },
      { "<leader>fg", desc = "Live grep (Everything)" },
      { "<leader>fb", desc = "Buffers" },
      { "<leader>fh", desc = "Help tags" },

      -- Git (gitsigns)
      { "<leader>g",  group = "git" },
      { "<leader>gs", desc = "Stage hunk" },
      { "<leader>gr", desc = "Reset hunk" },
      { "<leader>gS", desc = "Stage buffer" },
      { "<leader>gu", desc = "Undo stage hunk" },
      { "<leader>gp", desc = "Preview hunk" },
      { "<leader>gb", desc = "Blame line" },

      -- Lazygit wrapper
      { "<leader>l",  group = "lazygit" },
      { "<leader>lg", desc = "Open Lazygit" },
      { "<leader>lG", desc = "Lazygit current file" },

      -- Window management
      { "<leader>q",  desc = "Close window" },

      -- Sessions
      { "<leader>s",  group = "sessions" },
      { "<leader>sl", desc = "Load session" },
      { "<leader>ss", desc = "Save session" },
      { "<leader>sd", desc = "Delete session" },

      -- Tools / misc
      { "<leader>t",  group = "tools" },
      { "<leader>tt", desc = "Toggle terminal" },

      -- Trouble (diagnostics UI)
      { "<leader>x",  group = "trouble" },
      { "<leader>xx", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", desc = "Buffer diagnostics (Trouble)" },
      { "<leader>xs", desc = "Symbols (Trouble)" },
      { "<leader>xr", desc = "LSP list (Trouble)" },
      { "<leader>xL", desc = "Location list (Trouble)" },
      { "<leader>xQ", desc = "Quickfix list (Trouble)" },

      -- Theme switcher
      { "<leader>th", desc = "Theme picker" },
    })
  end,
}
