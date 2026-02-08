-- Additional colorscheme plugins (non-base46)
-- These are installed so `:colorscheme <name>` works, and so the theme picker can switch to them.

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    priority = 900,
    config = function()
      pcall(function()
        require("catppuccin").setup({
          flavour = "auto",
          background = { light = "latte", dark = "mocha" },
          transparent_background = false,
        })
      end)
    end,
  },
  {
    "olimorris/onedarkpro.nvim",
    lazy = true,
    priority = 900,
    config = function()
      pcall(function()
        require("onedarkpro").setup({})
      end)
    end,
  },
  {
    "everviolet/nvim",
    name = "evergarden",
    lazy = true,
    priority = 900,
    opts = {
      theme = {
        variant = "fall", -- 'winter'|'fall'|'spring'|'summer'
        accent = "green",
      },
      editor = {
        transparent_background = false,
        sign = { color = "none" },
        float = {
          color = "mantle",
          solid_border = false,
        },
        completion = {
          color = "surface0",
        },
      },
    },
    config = function(_, opts)
      pcall(function()
        require("evergarden").setup(opts)
      end)
    end,
  },
  {
    "ribru17/bamboo.nvim",
    lazy = true,
    priority = 900,
    config = function()
      pcall(function()
        require("bamboo").setup({})
      end)
    end,
  },
  {
    "yorumicolors/yorumi.nvim",
    lazy = true,
    priority = 900,
  },
  {
    "b0o/lavi.nvim",
    lazy = true,
    priority = 900,
  },
}
