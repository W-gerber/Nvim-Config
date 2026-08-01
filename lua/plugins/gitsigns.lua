return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "\u{258e}" }, -- ▎
      change = { text = "\u{258e}" },
      delete = { text = "\u{2581}" }, -- ▁
      topdelete = { text = "\u{2594}" }, -- ▔
      changedelete = { text = "\u{258e}" },
      untracked = { text = "\u{258e}" },
    },
    signs_staged_enable = true,
    current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },
    preview_config = { border = "rounded" },
    on_attach = function(bufnr)
      local gs = require("gitsigns")

      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
      end

      -- Navigation
      map("n", "]c", function() gs.nav_hunk("next") end, "Next git hunk")
      map("n", "[c", function() gs.nav_hunk("prev") end, "Previous git hunk")

      -- Staging. `stage_hunk` toggles when run on an already-staged hunk, which
      -- is why the old `undo_stage_hunk` binding (deprecated upstream) is gone.
      map({ "n", "v" }, "<leader>gs", gs.stage_hunk, "Stage hunk (toggle)")
      map({ "n", "v" }, "<leader>gr", gs.reset_hunk, "Reset hunk")
      map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
      map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")

      -- Inspection
      map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
      map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
      map("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle inline blame")
      map("n", "<leader>gd", gs.diffthis, "Diff against index")
      map("n", "<leader>gD", function() gs.diffthis("~") end, "Diff against last commit")

      -- Hunk text object: `dih`, `vih`, ...
      map({ "o", "x" }, "ih", gs.select_hunk, "Git hunk")
    end,
  },
}
