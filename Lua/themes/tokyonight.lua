-- Theme-specific overrides for base46's built-in `tokyonight`.
--
-- This file is NOT the full theme palette; base46 already provides the real TokyoNight palette.
-- Put only the changes you want here (colors + highlight tweaks).
--
-- What you can change:
-- - base_30 / base_16: core palette values used across integrations
-- - polish_hl: per-integration highlight overrides (syntax, treesitter, telescope, etc.)
--
-- Any fields left empty simply keep the original theme values.

return {
  base_30 = {
    -- Example overrides:
    -- one_bg = "#10131a",
    -- pmenu_bg = "#10131a",
  },

  base_16 = {
    -- Example overrides:
    -- base05 = "#c0caf5", -- default foreground
  },

  polish_hl = {
    -- Example: override syntax highlight groups
    -- syntax = {
    --   Comment = { fg = "#565f89", italic = true },
    --   String = { fg = "#9ece6a" },
    -- },
  },
}
