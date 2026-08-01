-- Theme-specific overrides for base46's built-in `tokyonight`.
--
-- This file is NOT the full theme palette; base46 already provides the real
-- TokyoNight palette. Put only the changes you want here.
--
-- What you can change:
-- - base_30 / base_16: core palette values used across integrations
-- - polish_hl: per-integration highlight overrides (syntax, treesitter, ...)
-- - ui_palette: exact chrome colors for this config's statusline, tabline,
--   pickers and floats. Without it those are *derived* from syntax groups —
--   `String` is assumed greenish, `Keyword` purple-ish — which is a heuristic.
--   Declaring it is how a theme stops that guess from being wrong.
--
-- Any table left empty simply keeps the original theme values, so this file is
-- inert until you fill something in. It is wired up through
-- `changed_themes.tokyonight` in lua/nvconfig.lua.

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
