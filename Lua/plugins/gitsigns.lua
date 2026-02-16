return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "▁" },
      topdelete = { text = "▔" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
      end

      map("n", "]c", gs.next_hunk, "Next hunk")
      map("n", "[c", gs.prev_hunk, "Prev hunk")
      map({ "n", "v" }, "<leader>gs", gs.stage_hunk, "Stage hunk")
      map({ "n", "v" }, "<leader>gr", gs.reset_hunk, "Reset hunk")
      map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
      map("n", "<leader>gu", gs.undo_stage_hunk, "Undo stage hunk")
      map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
      map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line (full)")
    end,
  },
}
