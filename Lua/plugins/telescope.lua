return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")

    telescope.setup({
      defaults = {
        cwd = "C:/Users/wgerb/Desktop/Everything",
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

    -- Keymaps
    vim.keymap.set("n", "<leader>ff", function()
      builtin.find_files({ cwd = "C:/Users/wgerb/Desktop/Everything", hidden = true })
    end, { desc = "Telescope: Find files in Everything" })

    vim.keymap.set("n", "<leader>fg", function()
      builtin.live_grep({
        cwd = "C:/Users/wgerb/Desktop/Everything",
      })
    end, { desc = "Telescope: Live grep in Everything" })

    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope: Buffers" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope: Help tags" })

    -- Telescope neon transparency
    vim.cmd([[
      hi TelescopeNormal        guibg=NONE guifg=#ffffff
      hi TelescopeBorder        guibg=NONE guifg=#00d7ff
      hi TelescopePromptNormal  guibg=NONE guifg=#00d7ff
      hi TelescopePromptBorder  guibg=NONE guifg=#00d7ff
      hi TelescopePromptTitle   guibg=NONE guifg=#00d7ff
      hi TelescopePreviewTitle  guibg=NONE guifg=#ff2d95
      hi TelescopePreviewBorder guibg=NONE guifg=#ff2d95
      hi TelescopeResultsTitle  guibg=NONE guifg=#b7ff3a
      hi TelescopeResultsBorder guibg=NONE guifg=#b7ff3a
      hi TelescopeSelection     guibg=#444444 guifg=#ffffff gui=bold
      hi TelescopeMatching      guifg=#00d7ff gui=bold
    ]])
  end,
}
