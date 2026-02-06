-- Theme-specific overrides for base46's built-in `default-light`.
--
-- base46 already provides the real default-light palette.
-- Put only your tweaks here.

return {
  base_30 = {
    -- Example overrides:
    -- one_bg = "#f6f6f6",
    -- black = "#ffffff",
  },

  base_16 = {
    -- Example overrides:
    -- base05 = "#202020", -- default foreground
  },

  polish_hl = {
    -- Example: make comments a bit softer
    -- syntax = {
    --   Comment = { fg = "#6b7280", italic = true },
    -- },
    
    -- Neo-tree explorer text colors (black for light theme)
    treesitter = {
      NeoTreeNormal = { fg = "#000000" },
      NeoTreeNormalNC = { fg = "#000000" },
      NeoTreeDirectoryName = { fg = "#000000", bold = true },
      NeoTreeFileName = { fg = "#000000" },
      NeoTreeRootName = { fg = "#000000", bold = true },
      NeoTreeFileNameOpened = { fg = "#000000", bold = true },
    },
  },
}
