return {
  -- Flash: fast, VS Code-like "jump" navigation.
  -- Lets you jump to any visible text with a couple keystrokes.
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {
    label = {
      rainbow = {
        enabled = true,
      },
    },
    modes = {
      -- Use flash in normal/operator/visual modes.
      search = {
        enabled = true,
      },
      char = {
        enabled = true,
      },
    },
  },
  keys = {
    {
      "s",
      mode = { "n", "x", "o" },
      function()
        require("flash").jump()
      end,
      desc = "Flash: Jump",
    },
    {
      "S",
      mode = { "n", "x", "o" },
      function()
        require("flash").treesitter()
      end,
      desc = "Flash: Treesitter",
    },
    {
      "r",
      mode = "o",
      function()
        require("flash").remote()
      end,
      desc = "Flash: Remote",
    },
    {
      "R",
      mode = { "o", "x" },
      function()
        require("flash").treesitter_search()
      end,
      desc = "Flash: Treesitter Search",
    },
    {
      "<c-s>",
      mode = { "c" },
      function()
        require("flash").toggle()
      end,
      desc = "Flash: Toggle (cmdline)",
    },
  },
}
