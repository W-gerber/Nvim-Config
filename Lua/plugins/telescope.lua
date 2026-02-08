return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "Telescope" },
  keys = {
    { "<leader>ff", function() require("telescope.builtin").find_files({ cwd = require("core.utils").everything, hidden = true }) end, desc = "Telescope: Find files" },
    { "<leader>fg", function() require("telescope.builtin").live_grep({ cwd = require("core.utils").everything }) end, desc = "Telescope: Live grep" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Telescope: Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Telescope: Help tags" },
  },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")
    local utils = require("core.utils")

    telescope.setup({
      defaults = {
        cwd = utils.everything,
        path_display = { "smart" },
        layout_strategy = "flex",
        layout_config = {
          flex = { flip_columns = 120 },
          prompt_position = "top",
        },
        sorting_strategy = "ascending",
        prompt_prefix = "🔍 ",
        winblend = 0,
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        color_devicons = true,
        mappings = {
          i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<C-c>"] = "close",
          },
          n = { ["q"] = "close" },
        },
      },
      pickers = {
        find_files = { hidden = true, layout_config = { prompt_position = "top" } },
        live_grep = {
          only_sort_text = true,
          layout_strategy = "horizontal",
          layout_config = {
            prompt_position = "top",
            width = 0.90,
            height = 0.85,
            horizontal = {
              preview_width = 0.55,
            },
          },
        },
      },
    })

    -- Theme-aware telescope highlights (re-applied on ColorScheme)
    local function apply_telescope_highlights()
      local ok_theme, theme = pcall(require, "theme")
      local c = (ok_theme and theme and theme.neon) or {
        cyan = "#00d7ff", hotpink = "#ff2d95", lime = "#b7ff3a", white = "#ffffff",
      }
      local hl = vim.api.nvim_set_hl
      hl(0, "TelescopeNormal",        { bg = "NONE", fg = c.white })
      hl(0, "TelescopeBorder",        { bg = "NONE", fg = c.cyan })
      hl(0, "TelescopePromptNormal",  { bg = "NONE", fg = c.cyan })
      hl(0, "TelescopePromptBorder",  { bg = "NONE", fg = c.cyan })
      hl(0, "TelescopePromptTitle",   { bg = "NONE", fg = c.cyan })
      hl(0, "TelescopePreviewTitle",  { bg = "NONE", fg = c.hotpink })
      hl(0, "TelescopePreviewBorder", { bg = "NONE", fg = c.hotpink })
      hl(0, "TelescopeResultsTitle",  { bg = "NONE", fg = c.lime })
      hl(0, "TelescopeResultsBorder", { bg = "NONE", fg = c.lime })
      hl(0, "TelescopeSelection",     { bg = "#444444", fg = c.white, bold = true })
      hl(0, "TelescopeMatching",      { fg = c.cyan, bold = true })
    end

    apply_telescope_highlights()

    local tele_group = vim.api.nvim_create_augroup("TelescopeHighlights", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = tele_group,
      callback = apply_telescope_highlights,
    })
  end,
}
