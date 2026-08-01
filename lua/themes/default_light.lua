-- Theme-specific overrides for base46's built-in `default-light`.
--
-- base46 already provides the real default-light palette; put only your tweaks
-- here. See lua/themes/tokyonight.lua for what each table does.
--
-- Note the filename: the theme *id* is `default-light` (hyphen, as base46
-- spells it) but a Lua module cannot have a hyphen, so the file is
-- `default_light.lua` and lua/nvconfig.lua maps one to the other.
--
-- Empty tables keep the original values, so this file is inert until filled in.

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
    --
    -- Note: the Neo-tree overrides that used to live here are gone. The
    -- explorer now derives its colors from the active theme (see
    -- plugins/neo_tree.lua), so light themes no longer need a per-theme
    -- "force the text black" patch.
  },
}
